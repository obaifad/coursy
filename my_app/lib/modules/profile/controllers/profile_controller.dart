import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/data/repositories/category_repository.dart';
import '../../../core/data/repositories/city_repository.dart';
import '../../../core/data/repositories/profile_repository.dart';
import '../../../core/data/repositories/reference_repository.dart';
import '../../../core/models/app_models.dart';
import '../../../core/models/student_profile_payload.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/json_parser.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/utils/education_level_utils.dart';
import '../../../theme/app_colors.dart';

class ProfileController extends GetxController {
  ProfileController();

  final ProfileRepository _repository = Get.find();
  final CityRepository _cityRepository = Get.find();
  final ReferenceRepository _referenceRepository = Get.find();
  final CategoryRepository _categoryRepository = Get.find();
  final TokenStorage _tokenStorage = Get.find();
  final ImagePicker _imagePicker = ImagePicker();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final isLoading = false.obs;
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

  @override
  void onInit() {
    super.onInit();
    avatarUrl.value = _tokenStorage.userAvatarUrl.value;
    pickedAvatarPath.value = _tokenStorage.userAvatarLocalPath.value;
    firstNameController.addListener(_recomputeHasChanges);
    lastNameController.addListener(_recomputeHasChanges);
    ever(selectedGender, (_) => _recomputeHasChanges());
    ever(birthDate, (_) => _recomputeHasChanges());
    ever(selectedCityId, (_) => _recomputeHasChanges());
    ever(selectedEducationLevel, (_) => _recomputeHasChanges());
    ever(selectedUniversityId, (_) => _recomputeHasChanges());
    ever(selectedSpecializationId, (_) => _recomputeHasChanges());
    ever(selectedCategoryIds, (_) => _recomputeHasChanges());
    loadLists();
    loadProfile();
  }

  Future<void> loadLists() async {
    listsLoading.value = true;
    try {
      final results = await Future.wait([
        _cityRepository.fetchCities(),
        _referenceRepository.fetchUniversities(),
        _referenceRepository.fetchStudentSpecializations(),
        _categoryRepository.fetchCategories(),
      ]);
      cities.assignAll(results[0] as List<CityModel>);
      universities.assignAll(results[1] as List<NamedEntity>);
      specializations.assignAll(results[2] as List<NamedEntity>);
      categories.assignAll(results[3] as List<CategoryModel>);
    } catch (_) {
      // تبقى الحقول قابلة للتعديل حتى لو تعذر تحميل القوائم.
    } finally {
      listsLoading.value = false;
    }
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
    final profileRaw = user['student_profile'];
    if (profileRaw is Map) {
      final profile = Map<String, dynamic>.from(profileRaw);
      selectedEducationLevel.value = profile['education_level']?.toString();
      selectedUniversityId.value = int.tryParse(profile['university_id']?.toString() ?? '');
      selectedSpecializationId.value = int.tryParse(profile['specialization_id']?.toString() ?? '');
      final preferred = profile['preferred_categories'];
      if (preferred is List) {
        selectedCategoryIds.assignAll(
          preferred
              .map((item) {
                if (item is Map) return int.tryParse(item['id']?.toString() ?? '');
                return int.tryParse(item.toString());
              })
              .whereType<int>(),
        );
      }
    }
  }

  Future<void> loadProfile() async {
    isLoading.value = true;
    try {
      final data = await _repository.fetchMe();
      _applyUserToForm(extractProfileUserMap(data));
    } catch (_) {
      // keep form editable even on fetch failure
    } finally {
      isLoading.value = false;
      captureEditBaseline();
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
    selectedEducationLevel.value = level;
    if (!EducationLevelUtils.requiresUniversityFields(level)) {
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
          preferredCategories: selectedCategoryIds.isEmpty ? null : selectedCategoryIds.toList(),
          birthDate: birthDate.value == null
              ? null
              : '${birthDate.value!.year}-${birthDate.value!.month.toString().padLeft(2, '0')}-${birthDate.value!.day.toString().padLeft(2, '0')}',
        ),
      );
      final user = extractProfileUserMap(result);
      if (user.isNotEmpty) {
        _applyUserToForm(user);
      }
      await _repository.syncProfileToSession(
        firstName: user['first_name']?.toString() ?? firstName,
        lastName: user['last_name']?.toString() ?? lastName,
        phone: user['phone']?.toString() ?? phone,
        avatarUrl: _repository.extractAvatarUrl(user) ?? avatarUrl.value,
      );
      try {
        final fresh = await _repository.fetchMe();
        final freshUser = extractProfileUserMap(fresh);
        if (freshUser.isNotEmpty) {
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

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    super.onClose();
  }
}
