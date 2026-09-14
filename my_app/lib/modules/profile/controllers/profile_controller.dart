import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/data/repositories/interest_repository.dart';
import '../../../core/data/repositories/city_repository.dart';
import '../../../core/data/repositories/profile_repository.dart';
import '../../../core/data/repositories/reference_repository.dart';
import '../../../core/locale/locale_request_guard.dart';
import '../../../core/models/app_models.dart';
import '../../../core/models/json_helpers.dart';
import '../../../core/models/student_profile_payload.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/json_parser.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/utils/education_level_utils.dart';
import '../../../core/session/session_refresh.dart';
import '../../../theme/app_colors.dart';

class ProfileController extends GetxController with LatestLoadGuard {
  ProfileController();

  final ProfileRepository _repository = Get.find();
  final CityRepository _cityRepository = Get.find();
  final ReferenceRepository _referenceRepository = Get.find();
  final InterestRepository _interestRepository = Get.find();
  final TokenStorage _tokenStorage = Get.find();
  final ImagePicker _imagePicker = ImagePicker();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final isSaving = false.obs;
  final listsLoading = false.obs;
  final hasChanges = false.obs;
  final saveSucceeded = false.obs;
  final pickedAvatarPath = RxnString();
  final avatarUrl = RxnString();
  final cities = <CityModel>[].obs;
  final universities = <NamedEntity>[].obs;
  final specializations = <NamedEntity>[].obs;
  final categories = <CategoryModel>[].obs;
  final selectedCityId = RxnInt();
  final selectedGender = RxnString();
  final birthDate = Rxn<DateTime>();
  final selectedEducationLevel = RxnString();
  final selectedUniversityId = RxnInt();
  final selectedSpecializationId = RxnInt();
  final selectedCategoryIds = <int>[].obs;

  String? _editFormBaselineKey;
  final avatarDirty = false.obs;

  static const educationLevels = ['High School', 'Diploma', 'Bachelor', 'Master', 'PhD'];

  String? get displayAvatarLocalPath => pickedAvatarPath.value ?? _tokenStorage.userAvatarLocalPath.value;

  String? get displayAvatarUrl => avatarUrl.value ?? _tokenStorage.userAvatarUrl.value;

  Map<String, dynamic>? _cachedProfileUser;

  @override
  void onInit() {
    super.onInit();
    avatarUrl.value = _tokenStorage.userAvatarUrl.value;
    pickedAvatarPath.value = _tokenStorage.userAvatarLocalPath.value;
    _applySessionSeed();
    firstNameController.addListener(_recomputeHasChanges);
    lastNameController.addListener(_recomputeHasChanges);
    ever(selectedGender, (_) => _recomputeHasChanges());
    ever(birthDate, (_) => _recomputeHasChanges());
    ever(selectedCityId, (_) => _recomputeHasChanges());
    ever(selectedEducationLevel, (_) => _recomputeHasChanges());
    ever(selectedUniversityId, (_) => _recomputeHasChanges());
    ever(selectedSpecializationId, (_) => _recomputeHasChanges());
    ever(selectedCategoryIds, (_) => _recomputeHasChanges());
    _bootstrapProfileForm();
  }

  Future<void> _bootstrapProfileForm() async {
    await _fillAcademicGapsFromCache();
    if (_cachedProfileUser != null) {
      _applyUserToForm(_cachedProfileUser!);
      captureEditBaseline();
    }
    await Future.wait([loadLists(), loadProfile()]);
  }

  void _applySessionSeed() {
    if (firstNameController.text.isEmpty && lastNameController.text.isEmpty) {
      final name = _tokenStorage.userName.value?.trim();
      if (name != null && name.isNotEmpty) {
        final parts = name.split(RegExp(r'\s+'));
        firstNameController.text = parts.first;
        if (parts.length > 1) {
          lastNameController.text = parts.sublist(1).join(' ');
        }
      }
    }
    if (phoneController.text.isEmpty) {
      phoneController.text = _tokenStorage.userPhone.value ?? '';
    }
  }

  Future<void> loadLists({bool force = false}) async {
    if (listsLoading.value && !force) return;
    if (!force && categories.isNotEmpty && universities.isNotEmpty && specializations.isNotEmpty) {
      return;
    }
    final session = beginLoad();
    listsLoading.value = true;
    try {
      final results = await Future.wait([
        _safeList(_cityRepository.fetchCities()),
        _safeList(_referenceRepository.fetchUniversities()),
        _safeList(_referenceRepository.fetchStudentSpecializations()),
        _safeList(_interestRepository.fetchInterests()),
      ]);

      applyIfCurrent(session, () {
        if (results[0].isNotEmpty) cities.assignAll(results[0] as List<CityModel>);
        if (results[1].isNotEmpty) universities.assignAll(results[1] as List<NamedEntity>);
        if (results[2].isNotEmpty) specializations.assignAll(results[2] as List<NamedEntity>);
        if (results[3].isNotEmpty) categories.assignAll(results[3] as List<CategoryModel>);
        if (_cachedProfileUser != null) {
          _applyUserToForm(_cachedProfileUser!);
        }
      });
      await _fillAcademicGapsFromCache();
    } on ApiCancelledException {
      return;
    } catch (_) {
      await _fillAcademicGapsFromCache();
    } finally {
      finishLoad(session, () => listsLoading.value = false);
    }
  }

  Future<void> reloadLocalizedData() async {
    await loadLists(force: true);
    await loadProfile();
  }

  Future<void> refreshForEdit() async {
    _applySessionSeed();
    await _fillAcademicGapsFromCache();
    if (_cachedProfileUser != null) {
      _applyUserToForm(_cachedProfileUser!);
      captureEditBaseline();
    }
    await Future.wait([loadLists(), loadProfile()]);
  }

  void _applyUserToForm(Map<String, dynamic> user) {
    firstNameController.text = user['first_name']?.toString() ?? '';
    lastNameController.text = user['last_name']?.toString() ?? '';
    phoneController.text = user['phone']?.toString() ?? '';
    selectedGender.value = user['gender']?.toString();
    if (user['city_id'] != null) {
      selectedCityId.value = int.tryParse(user['city_id'].toString());
    }
    if (user['birth_date'] != null) {
      birthDate.value = DateTime.tryParse(user['birth_date'].toString());
    }
    final remoteAvatar = _repository.extractAvatarUrl(user);
    if (remoteAvatar != null) {
      avatarUrl.value = remoteAvatar;
      _tokenStorage.saveAvatar(url: remoteAvatar);
    }

    final profile = extractNestedStudentProfile(user) ?? <String, dynamic>{};
    selectedEducationLevel.value = EducationLevelUtils.normalize(
      profile['education_level']?.toString() ?? user['education_level']?.toString(),
    );
    selectedUniversityId.value = JsonHelpers.parseIntOrNull(
      profile['university_id'] ?? user['university_id'],
    );
    selectedSpecializationId.value = JsonHelpers.parseIntOrNull(
      profile['specialization_id'] ?? user['specialization_id'],
    );

    selectedCategoryIds.assignAll(extractPreferredInterestIds({...profile, ...user}));
  }

  Future<void> loadProfile() async {
    try {
      final user = await _repository.fetchFullStudentUser();
      if (user.isNotEmpty) {
        _cachedProfileUser = user;
        _applyUserToForm(user);
      }
    } catch (_) {
      // نكمل من الكاش المحلي أدناه.
    } finally {
      await _fillAcademicGapsFromCache();
      captureEditBaseline();
    }
  }

  Future<void> _fillAcademicGapsFromCache() async {
    final cached = await _tokenStorage.loadAcademicCache();
    if (cached == null || cached.isEmpty) return;

    if (selectedEducationLevel.value == null || selectedEducationLevel.value!.isEmpty) {
      selectedEducationLevel.value = EducationLevelUtils.normalize(cached.educationLevel);
    }
    selectedUniversityId.value ??= cached.universityId;
    selectedSpecializationId.value ??= cached.specializationId;
    if (selectedCategoryIds.isEmpty && cached.preferredCategoryIds.isNotEmpty) {
      selectedCategoryIds.assignAll(cached.preferredCategoryIds);
    }
  }

  Future<List<T>> _safeList<T>(Future<List<T>> future) async {
    try {
      return await future;
    } catch (_) {
      return [];
    }
  }

  void captureEditBaseline() {
    saveSucceeded.value = false;
    _editFormBaselineKey = _formSnapshotKey();
    _recomputeHasChanges();
  }

  String _formSnapshotKey() {
    final categoryIds = [...selectedCategoryIds]..sort();
    return [
      firstNameController.text.trim(),
      lastNameController.text.trim(),
      selectedGender.value ?? '',
      birthDate.value?.toIso8601String() ?? '',
      '${selectedCityId.value ?? ''}',
      selectedEducationLevel.value ?? '',
      '${selectedUniversityId.value ?? ''}',
      '${selectedSpecializationId.value ?? ''}',
      categoryIds.join(','),
    ].join('|');
  }

  void _recomputeHasChanges() {
    if (_editFormBaselineKey == null) {
      hasChanges.value = avatarDirty.value;
      return;
    }
    hasChanges.value = _formSnapshotKey() != _editFormBaselineKey || avatarDirty.value;
  }

  Future<void> pickAvatar() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (picked == null) return;
      pickedAvatarPath.value = picked.path;
      avatarDirty.value = true;
      await _tokenStorage.saveAvatar(localPath: picked.path);
      _recomputeHasChanges();
    } catch (_) {
      Get.snackbar('error'.tr, 'pick_image_failed'.tr);
    }
  }

  void setGender(String? gender) {
    selectedGender.value = gender;
    _recomputeHasChanges();
  }

  void setEducationLevel(String? level) {
    selectedEducationLevel.value = EducationLevelUtils.normalize(level);
    if (!EducationLevelUtils.requiresUniversityFields(selectedEducationLevel.value)) {
      selectedUniversityId.value = null;
      selectedSpecializationId.value = null;
    }
  }

  bool get requiresUniversityFields =>
      EducationLevelUtils.requiresUniversityFields(selectedEducationLevel.value);

  String? validateProfile() {
    if (requiresUniversityFields) {
      if (selectedUniversityId.value == null) return 'pick_university'.tr;
      if (selectedSpecializationId.value == null) return 'pick_specialization'.tr;
    }
    return null;
  }

  Future<void> saveProfile() async {
    if (!hasChanges.value) return;
    final validationError = validateProfile();
    if (validationError != null) {
      Get.snackbar('alert'.tr, validationError);
      return;
    }

    isSaving.value = true;
    saveSucceeded.value = false;
    try {
      final firstName = firstNameController.text.trim();
      final lastName = lastNameController.text.trim();
      final phone = phoneController.text.trim();

      if (avatarDirty.value && pickedAvatarPath.value != null && pickedAvatarPath.value!.isNotEmpty) {
        try {
          final path = pickedAvatarPath.value!;
          final avatarResult = kIsWeb
              ? await _repository.uploadAvatarBytes(
                  await XFile(path).readAsBytes(),
                  filename: 'avatar.jpg',
                )
              : await _repository.uploadAvatar(path);
          final avatarUser = extractProfileUserMap(avatarResult);
          if (avatarUser.isNotEmpty) {
            final remoteAvatar = _repository.extractAvatarUrl(avatarUser);
            if (remoteAvatar != null) {
              avatarUrl.value = remoteAvatar;
              await _tokenStorage.saveAvatar(url: remoteAvatar, localPath: '');
              pickedAvatarPath.value = null;
            }
          }
        } catch (_) {
          // إذا لم يدعم الخادم رفع الصورة نُبقي المعاينة محلياً ونكمل حفظ البيانات.
        }
      }

      final result = await _repository.updateProfile(
        StudentProfilePayload(
          firstName: firstName,
          lastName: lastName,
          phone: phone,
          gender: selectedGender.value,
          cityId: selectedCityId.value,
          educationLevel: selectedEducationLevel.value,
          universityId: requiresUniversityFields ? selectedUniversityId.value : null,
          specializationId: requiresUniversityFields ? selectedSpecializationId.value : null,
          preferredTags: selectedCategoryIds.isEmpty ? null : selectedCategoryIds.toList(),
          birthDate: birthDate.value == null
              ? null
              : '${birthDate.value!.year}-${birthDate.value!.month.toString().padLeft(2, '0')}-${birthDate.value!.day.toString().padLeft(2, '0')}',
        ),
      );
      final merged = mergeProfileUserData(result);
      if (merged.isNotEmpty) {
        _cachedProfileUser = merged;
        _applyUserToForm(merged);
      }
      await _repository.syncProfileToSession(
        firstName: merged['first_name']?.toString() ?? firstName,
        lastName: merged['last_name']?.toString() ?? lastName,
        phone: merged['phone']?.toString() ?? phone,
        avatarUrl: _repository.extractAvatarUrl(merged) ?? avatarUrl.value,
      );
      try {
        final freshUser = await _repository.fetchFullStudentUser();
        if (freshUser.isNotEmpty) {
          _cachedProfileUser = freshUser;
          _applyUserToForm(freshUser);
          await _repository.syncProfileToSession(
            firstName: freshUser['first_name']?.toString(),
            lastName: freshUser['last_name']?.toString(),
            phone: freshUser['phone']?.toString(),
            avatarUrl: _repository.extractAvatarUrl(freshUser) ?? avatarUrl.value,
          );
        }
      } catch (_) {}

      avatarDirty.value = false;
      captureEditBaseline();
      saveSucceeded.value = true;
      _showSavedSnack();
      await SessionRefresh.afterProfileSaved();
      await Future<void>.delayed(const Duration(milliseconds: 700));
      Get.back(result: true);
    } on ApiException catch (e) {
      Get.snackbar('error'.tr, e.message);
    } catch (_) {
      Get.snackbar('error'.tr, 'save_profile_failed'.tr);
    } finally {
      isSaving.value = false;
    }
  }

  void _showSavedSnack() {
    Get.snackbar(
      'profile_saved'.tr,
      'profile_changes_saved'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
      duration: const Duration(seconds: 3),
    );
  }

  void toggleCategoryId(int id) {
    if (selectedCategoryIds.contains(id)) {
      selectedCategoryIds.remove(id);
    } else {
      selectedCategoryIds.add(id);
    }
    _recomputeHasChanges();
  }

  void setCategoryIds(List<int> ids) {
    selectedCategoryIds.assignAll(ids.where((id) => id > 0).toSet().toList());
    _recomputeHasChanges();
  }

  String educationLevelLabel(String value) {
    switch (value) {
      case 'High School':
        return 'edu_high_school'.tr;
      case 'Diploma':
        return 'edu_diploma'.tr;
      case 'Bachelor':
        return 'edu_bachelor'.tr;
      case 'Master':
        return 'edu_master'.tr;
      case 'PhD':
        return 'edu_phd'.tr;
      default:
        return value;
    }
  }

  static void ensureRegistered() {
    if (!Get.isRegistered<ProfileController>()) {
      Get.lazyPut<ProfileController>(() => ProfileController(), fenix: true);
    }
  }

  void clearForLogout() {
    _cachedProfileUser = null;
    _editFormBaselineKey = null;
    firstNameController.clear();
    lastNameController.clear();
    phoneController.clear();
    avatarUrl.value = null;
    pickedAvatarPath.value = null;
    avatarDirty.value = false;
    hasChanges.value = false;
    saveSucceeded.value = false;
    selectedCityId.value = null;
    selectedGender.value = null;
    birthDate.value = null;
    selectedEducationLevel.value = null;
    selectedUniversityId.value = null;
    selectedSpecializationId.value = null;
    selectedCategoryIds.clear();
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    super.onClose();
  }
}
