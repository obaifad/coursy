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
import '../../../core/storage/academic_profile_cache.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/utils/education_level_utils.dart';
import '../../../core/session/session_refresh.dart';
import '../../../core/utils/app_toast.dart';

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

  /// تعذّر جلب بيانات الملف من الخادم (والنموذج معبأ مما في الجهاز فقط): يظهر شريط تنبيه مع إعادة المحاولة.
  final profileLoadFailed = false.obs;
  final hasChanges = false.obs;

  /// عدد الحقول التي تغيّرت عن آخر نسخة محفوظة (الصورة حقل واحد) — لشريط الحفظ السفلي.
  final pendingChangesCount = 0.obs;

  /// البريد كما يرسله الخادم — للعرض فقط في قسم الحساب.
  final email = RxnString();
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

  List<String>? _editFormBaseline;

  /// القيم الأكاديمية عند آخر لقطة أساس: بمقارنتها بالحالية نعرف ما أفرغه المستخدم فيُرسَل صراحة.
  String? _baseEducation;
  int? _baseUniversity;
  int? _baseSpecialization;
  Set<int> _baseCategories = {};
  final avatarDirty = false.obs;

  static const educationLevels = ['High School', 'Diploma', 'Bachelor', 'Master', 'PhD'];

  /// معاينة الصورة المختارة قبل رفعها — في الذاكرة فقط؛ مسار image_picker مؤقت وقد يحذفه النظام.
  String? get displayAvatarLocalPath => pickedAvatarPath.value;

  String? get displayAvatarUrl => avatarUrl.value ?? _tokenStorage.userAvatarUrl.value;

  Map<String, dynamic>? _cachedProfileUser;

  /// مراقبات «هل تغيّر شيء؟» — تُلغى في onClose كباقي المتحكّمات.
  final _changeWorkers = <Worker>[];

  @override
  void onInit() {
    super.onInit();
    avatarUrl.value = _tokenStorage.userAvatarUrl.value;
    _applySessionSeed();
    firstNameController.addListener(_recomputeHasChanges);
    lastNameController.addListener(_recomputeHasChanges);
    _changeWorkers.addAll([
      ever(selectedGender, (_) => _recomputeHasChanges()),
      ever(birthDate, (_) => _recomputeHasChanges()),
      ever(selectedCityId, (_) => _recomputeHasChanges()),
      ever(selectedEducationLevel, (_) => _recomputeHasChanges()),
      ever(selectedUniversityId, (_) => _recomputeHasChanges()),
      ever(selectedSpecializationId, (_) => _recomputeHasChanges()),
      ever(selectedCategoryIds, (_) => _recomputeHasChanges()),
    ]);
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
    final mail = user['email']?.toString().trim() ?? '';
    email.value = mail.isEmpty ? null : mail;
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
    selectedUniversityId.value = JsonHelpers.parseIntOrNull(profile['university_id'] ?? user['university_id']);
    selectedSpecializationId.value = JsonHelpers.parseIntOrNull(
      profile['specialization_id'] ?? user['specialization_id'],
    );

    selectedCategoryIds.assignAll(extractPreferredInterestIds({...profile, ...user}));
  }

  Future<void> loadProfile() async {
    try {
      final user = await _repository.fetchFullStudentUser();
      profileLoadFailed.value = false;
      if (user.isNotEmpty) {
        _cachedProfileUser = user;
        _applyUserToForm(user);
      }
    } catch (_) {
      // نكمل من الكاش المحلي أدناه، ونُظهر للمستخدم أن البيانات قد لا تكون الأحدث.
      profileLoadFailed.value = true;
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
    _editFormBaseline = _formSnapshot();
    _baseEducation = selectedEducationLevel.value;
    _baseUniversity = selectedUniversityId.value;
    _baseSpecialization = selectedSpecializationId.value;
    _baseCategories = selectedCategoryIds.toSet();
    _recomputeHasChanges();
  }

  /// قيمة كل حقل قابل للتعديل بترتيب ثابت — يُقارن عنصراً بعنصر لعدّ التغييرات.
  List<String> _formSnapshot() {
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
    ];
  }

  void _recomputeHasChanges() {
    final baseline = _editFormBaseline;
    var count = avatarDirty.value ? 1 : 0;
    if (baseline != null) {
      final current = _formSnapshot();
      for (var i = 0; i < current.length; i++) {
        if (current[i] != baseline[i]) count++;
      }
    }
    pendingChangesCount.value = count;
    hasChanges.value = count > 0;
    // تعديل جديد بعد حفظ ناجح: تعود علامة «تم» زرَّ حفظ. كانت تبقى (والزر معطّل ما دامت ظاهرة)، فيعرض الشريط
    // «تغييرات غير محفوظة» ولا يمكن حفظها إلا بالخروج من الصفحة والعودة.
    if (count > 0) saveSucceeded.value = false;
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
      _recomputeHasChanges();
    } catch (_) {
      AppToast.show('error'.tr, 'pick_image_failed'.tr);
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

  bool get requiresUniversityFields => EducationLevelUtils.requiresUniversityFields(selectedEducationLevel.value);

  String? validateProfile() {
    if (requiresUniversityFields) {
      if (selectedUniversityId.value == null) return 'pick_university'.tr;
      if (selectedSpecializationId.value == null) return 'pick_specialization'.tr;
    }
    return null;
  }

  /// الحقول الأكاديمية التي كانت ذات قيمة وصارت فارغة: تُرسَل صراحة (انظر [StudentProfilePayload.clearFields]).
  /// يشمل ذلك الجامعة والتخصص حين يُغيَّر المستوى إلى ما لا يحتاجهما.
  Set<String> _clearedAcademicFields() {
    final level = selectedEducationLevel.value ?? '';
    final university = requiresUniversityFields ? selectedUniversityId.value : null;
    final specialization = requiresUniversityFields ? selectedSpecializationId.value : null;
    return {
      if ((_baseEducation ?? '').isNotEmpty && level.isEmpty) 'education_level',
      if (_baseUniversity != null && university == null) 'university_id',
      if (_baseSpecialization != null && specialization == null) 'specialization_id',
      if (_baseCategories.isNotEmpty && selectedCategoryIds.isEmpty) 'preferred_categories',
    };
  }

  /// تراجع عن التعديلات غير المحفوظة: يعيد النموذج إلى آخر ما حُمّل من الخادم (أو النسخة المحلية).
  Future<void> discardChanges() async {
    final user = _cachedProfileUser;
    if (user != null) _applyUserToForm(user);
    await _fillAcademicGapsFromCache();
    pickedAvatarPath.value = null;
    avatarDirty.value = false;
    captureEditBaseline();
  }

  Future<void> saveProfile() async {
    if (!hasChanges.value) return;
    final validationError = validateProfile();
    if (validationError != null) {
      AppToast.show('alert'.tr, validationError);
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
              ? await _repository.uploadAvatarBytes(await XFile(path).readAsBytes(), filename: 'avatar.jpg')
              : await _repository.uploadAvatar(path);
          final avatarUser = extractProfileUserMap(avatarResult);
          if (avatarUser.isNotEmpty) {
            final remoteAvatar = _repository.extractAvatarUrl(avatarUser);
            if (remoteAvatar != null) {
              avatarUrl.value = remoteAvatar;
              await _tokenStorage.saveAvatar(url: remoteAvatar);
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
          birthDate: birthDate.value == null ? null : EducationLevelUtils.formatApiDate(birthDate.value!),
          clearFields: _clearedAcademicFields(),
        ),
      );
      // النسخة المحلية تطابق ما حُفظ (فارغة إن أُفرغت الحقول) قبل أي إعادة تحميل، وإلا أعادت تعبئتها.
      await _repository.saveAcademicSnapshot(
        AcademicProfileCache(
          educationLevel: selectedEducationLevel.value,
          universityId: requiresUniversityFields ? selectedUniversityId.value : null,
          specializationId: requiresUniversityFields ? selectedSpecializationId.value : null,
          preferredCategoryIds: selectedCategoryIds.toList(),
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
      // تبقى الصفحة مفتوحة لمتابعة التعديل (كانت تُغلق وحدها بعد 0.7 ثانية)؛ الرجوع بيد المستخدم، وبلا
      // تغييرات معلّقة لا يُسأل عن شيء.
      await SessionRefresh.afterProfileSaved();
    } on ApiException catch (e) {
      AppToast.show('error'.tr, e.message);
    } catch (_) {
      AppToast.show('error'.tr, 'save_profile_failed'.tr);
    } finally {
      isSaving.value = false;
    }
  }

  void _showSavedSnack() {
    AppToast.show('profile_saved'.tr, 'profile_changes_saved'.tr, kind: ToastKind.success);
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

  String educationLevelLabel(String value) => EducationLevelUtils.label(value);

  /// البريد من آخر تحميل للملف الشخصي (فارغ إن لم يُحمَّل بعد).
  String get currentEmail => _cachedProfileUser?['email']?.toString().trim() ?? '';

  static void ensureRegistered() {
    if (!Get.isRegistered<ProfileController>()) {
      Get.lazyPut<ProfileController>(() => ProfileController(), fenix: true);
    }
  }

  void clearForLogout() {
    _cachedProfileUser = null;
    _editFormBaseline = null;
    firstNameController.clear();
    lastNameController.clear();
    phoneController.clear();
    avatarUrl.value = null;
    pickedAvatarPath.value = null;
    avatarDirty.value = false;
    hasChanges.value = false;
    pendingChangesCount.value = 0;
    email.value = null;
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
    for (final worker in _changeWorkers) {
      worker.dispose();
    }
    firstNameController.removeListener(_recomputeHasChanges);
    lastNameController.removeListener(_recomputeHasChanges);
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    super.onClose();
  }
}
