import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/data/repositories/auth_repository.dart';
import '../../../core/data/repositories/interest_repository.dart';
import '../../../core/data/repositories/city_repository.dart';
import '../../../core/data/repositories/profile_repository.dart';
import '../../../core/data/repositories/reference_repository.dart';
import '../../../core/locale/locale_request_guard.dart';
import '../../../core/models/app_models.dart';
import '../../../core/models/register_payload.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/session/session_refresh.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../core/utils/education_level_utils.dart';
import '../../../routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepository = Get.find();
  final CityRepository _cityRepository = Get.find();
  final InterestRepository _interestRepository = Get.find();
  final ReferenceRepository _referenceRepository = Get.find();

  static const educationLevels = ['High School', 'Diploma', 'Bachelor', 'Master', 'PhD'];

  final loginEmailController = TextEditingController();
  final loginPhoneController = TextEditingController();
  final passwordController = TextEditingController();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final registerPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final isLoading = false.obs;
  final hidePassword = true.obs;
  final hideRegisterPassword = true.obs;
  final hideConfirmPassword = true.obs;
  final errorMessage = RxnString();
  final registerStepError = RxnString();
  final registerFieldErrors = <String, String>{}.obs;

  final registerStep = 0.obs;
  final cities = <CityModel>[].obs;
  final citiesLoading = false.obs;
  final citiesError = RxnString();
  final referencesLoading = false.obs;
  final referencesError = RxnString();
  final categoriesLoading = false.obs;
  final categoriesError = RxnString();
  final selectedCityId = RxnInt();
  final selectedGender = RxnString();
  final birthDate = Rxn<DateTime>();
  final universities = <NamedEntity>[].obs;
  final specializations = <NamedEntity>[].obs;
  final categories = <CategoryModel>[].obs;
  final selectedEducationLevel = RxnString();
  final selectedUniversityId = RxnInt();
  final selectedSpecializationId = RxnInt();
  final selectedCategoryIds = <int>[].obs;

  final isAdvancingStep = false.obs;
  final isSubmittingRegister = false.obs;
  final registerReferenceReady = false.obs;
  final registerStep1Validated = false.obs;
  final registerStep0Validated = false.obs;

  int _citiesLoadId = 0;
  int _referencesLoadId = 0;
  int _categoriesLoadId = 0;

  LocaleRequestGuard get _localeGuard => Get.find<LocaleRequestGuard>();

  bool _loadStillCurrent(int loadId, int counter, int localeGen) =>
      loadId == counter && _localeGuard.isCurrent(localeGen);

  @override
  void onInit() {
    super.onInit();
    registerPasswordController.addListener(_validatePasswordFieldsLive);
    confirmPasswordController.addListener(_validatePasswordFieldsLive);
    emailController.addListener(_onRegisterIdentityChanged);
    phoneController.addListener(_onRegisterIdentityChanged);
  }

  void _onRegisterIdentityChanged() {
    registerStep0Validated.value = false;
    if (registerStep.value != 0) return;
    registerFieldErrors.remove('email');
    registerFieldErrors.remove('phone');
    registerFieldErrors.refresh();
  }

  /// تحميل قوائم التسجيل عند فتح الشاشة فقط — لا يُستدعى عند الدخول.
  Future<void> prepareRegisterReferenceData({bool force = false}) async {
    if (registerReferenceReady.value && !force) return;
    await Future.wait([
      loadCities(force: force),
      loadReferences(force: force),
      loadCategories(force: force),
    ]);
    registerReferenceReady.value =
        cities.isNotEmpty && universities.isNotEmpty && categories.isNotEmpty;
  }

  Future<void> loadCities({bool force = false}) async {
    if (citiesLoading.value && !force) return;
    final loadId = ++_citiesLoadId;
    final localeGen = _localeGuard.capture();
    citiesLoading.value = true;
    citiesError.value = null;
    try {
      final fresh = await _cityRepository.fetchCities();
      if (_loadStillCurrent(loadId, _citiesLoadId, localeGen)) {
        cities.assignAll(fresh);
      }
    } on ApiCancelledException {
      return;
    } catch (e) {
      if (!_loadStillCurrent(loadId, _citiesLoadId, localeGen)) return;
      cities.clear();
      citiesError.value = e is ApiException ? e.message : 'connection_error'.tr;
    } finally {
      if (loadId == _citiesLoadId) citiesLoading.value = false;
    }
  }

  Future<void> loadReferences({bool force = false}) async {
    if (referencesLoading.value && !force) return;
    final loadId = ++_referencesLoadId;
    final localeGen = _localeGuard.capture();
    referencesLoading.value = true;
    referencesError.value = null;
    try {
      final results = await Future.wait([
        _referenceRepository.fetchUniversities(),
        _referenceRepository.fetchStudentSpecializations(),
      ]);
      if (_loadStillCurrent(loadId, _referencesLoadId, localeGen)) {
        universities.assignAll(results[0]);
        specializations.assignAll(results[1]);
      }
    } on ApiCancelledException {
      return;
    } catch (e) {
      if (!_loadStillCurrent(loadId, _referencesLoadId, localeGen)) return;
      universities.clear();
      specializations.clear();
      referencesError.value = e is ApiException ? e.message : 'connection_error'.tr;
    } finally {
      if (loadId == _referencesLoadId) referencesLoading.value = false;
    }
  }

  Future<void> loadCategories({bool force = false}) async {
    if (categoriesLoading.value && !force) return;
    final loadId = ++_categoriesLoadId;
    final localeGen = _localeGuard.capture();
    categoriesLoading.value = true;
    categoriesError.value = null;
    try {
      final fresh = await _fetchAllInterestsWithRetry();
      if (_loadStillCurrent(loadId, _categoriesLoadId, localeGen)) {
        categories.assignAll(fresh);
        if (kDebugMode) {
          debugPrint('[Register] loaded ${fresh.length} interest tags');
        }
      }
    } on ApiCancelledException {
      return;
    } catch (e) {
      if (!_loadStillCurrent(loadId, _categoriesLoadId, localeGen)) return;
      categories.clear();
      categoriesError.value = e is ApiException ? e.message : 'connection_error'.tr;
    } finally {
      if (loadId == _categoriesLoadId) categoriesLoading.value = false;
    }
  }

  Future<List<CategoryModel>> _fetchAllInterestsWithRetry() async {
    try {
      return await _interestRepository.fetchInterests();
    } on ApiException catch (e) {
      if (!e.message.contains('Incomplete paginated fetch')) rethrow;
      return _interestRepository.fetchInterests();
    }
  }

  Future<void> reloadLocalizedData() async {
    await Future.wait([
      loadCities(force: true),
      loadReferences(force: true),
      loadCategories(force: true),
    ]);
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

  void setCategoryIds(List<int> ids) {
    selectedCategoryIds.assignAll(ids.where((id) => id > 0).toSet().toList());
  }

  void toggleCategoryId(int id) {
    if (selectedCategoryIds.contains(id)) {
      selectedCategoryIds.remove(id);
    } else {
      selectedCategoryIds.add(id);
    }
  }

  Future<void> login() async {
    final email = loginEmailController.text.trim();
    final phone = loginPhoneController.text.trim();
    final pass = passwordController.text;

    if (email.isEmpty || phone.isEmpty || pass.isEmpty) {
      Get.snackbar('alert'.tr, 'enter_email_phone_password'.tr);
      return;
    }
    if (!email.contains('@')) {
      Get.snackbar('alert'.tr, 'enter_valid_email'.tr);
      return;
    }
    if (!_isValidSyrianMobile(phone)) {
      Get.snackbar('alert'.tr, 'enter_valid_phone'.tr);
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;
    try {
      await _authRepository.login(email: email, phone: phone, password: pass);
      await _afterAuthSuccess();
    } on ApiException catch (e) {
      errorMessage.value = e.message;
      Get.snackbar('login_failed'.tr, e.message);
    } catch (_) {
      final msg = kIsWeb ? 'web_cors_hint'.tr : 'connection_error'.tr;
      errorMessage.value = msg;
      Get.snackbar('error'.tr, msg);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _afterAuthSuccess() async {
    if (Get.isRegistered<ProfileRepository>()) {
      try {
        await Get.find<ProfileRepository>().fetchMe();
      } catch (_) {}
    }
    await SessionRefresh.onLoginSuccess();
    AppNavigation.goToRoot(tab: 2);
  }

  void clearRegisterValidation() {
    registerStepError.value = null;
    registerFieldErrors.clear();
  }

  Future<void> nextRegisterStep() async {
    registerStepError.value = null;

    final step = registerStep.value;
    final fieldErrors = _collectRegisterStepErrors(step);
    if (!_applyRegisterFieldErrors(fieldErrors)) return;

    isAdvancingStep.value = true;
    try {
      if (step == 0) {
        final blocked = await _validateRegisterStep0Remote();
        if (blocked) return;
        registerStep0Validated.value = true;
      } else if (step == 1) {
        registerStep1Validated.value = true;
      }

      if (step < 2) {
        registerStep.value++;
        if (registerStep.value == 2) {
          prepareRegisterReferenceData(force: true);
        }
      }
    } on ApiException catch (e) {
      _showRegisterStepError(e.message);
    } catch (_) {
      _showRegisterStepError('connection_error'.tr);
    } finally {
      isAdvancingStep.value = false;
    }
  }

  void previousRegisterStep() {
    clearRegisterValidation();
    if (registerStep.value > 0) {
      registerStep.value--;
    } else {
      Get.back();
    }
  }

  Future<void> submitRegister() async {
    registerStepError.value = null;

    final step2Errors = _collectRegisterStepErrors(2);
    if (!_applyRegisterFieldErrors(step2Errors)) return;

    isSubmittingRegister.value = true;
    try {
      final phone = phoneController.text.trim();
      final payload = RegisterPayload(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: emailController.text.trim(),
        phone: phone,
        password: registerPasswordController.text,
        passwordConfirmation: confirmPasswordController.text,
        cityId: selectedCityId.value!,
        gender: selectedGender.value,
        birthDate: birthDate.value != null ? formatBirthDate(birthDate.value!) : null,
        educationLevel: selectedEducationLevel.value,
        universityId: requiresUniversityFields ? selectedUniversityId.value : null,
        specializationId: requiresUniversityFields ? selectedSpecializationId.value : null,
        preferredTags: selectedCategoryIds.isEmpty ? null : selectedCategoryIds.toList(),
        deviceName: GetPlatform.isAndroid
            ? 'android'
            : GetPlatform.isIOS
                ? 'ios'
                : GetPlatform.isWindows
                    ? 'windows'
                    : 'flutter',
      );

      final autoLoggedIn = await _authRepository.register(payload);
      if (autoLoggedIn) {
        await Get.find<ProfileRepository>().syncAcademicAfterRegister(
          educationLevel: payload.educationLevel,
          universityId: payload.universityId,
          specializationId: payload.specializationId,
          preferredTags: payload.preferredTags,
        );
        Get.snackbar('welcome'.tr, 'account_created_ok'.tr);
        await _afterAuthSuccess();
        return;
      }

      Get.offAllNamed(AppRoutes.login);
      loginEmailController.text = emailController.text.trim();
      loginPhoneController.text = phone;
      Get.snackbar('register_done'.tr, 'register_login_hint'.tr);
    } on ApiException catch (e) {
      _applyApiRegisterErrors(e);
      if (registerFieldErrors.isEmpty) {
        Get.snackbar('register_failed'.tr, e.message);
      }
    } catch (_) {
      _showRegisterStepError('connection_error'.tr);
      Get.snackbar('error'.tr, 'connection_error'.tr);
    } finally {
      isSubmittingRegister.value = false;
    }
  }

  Map<String, String> _collectRegisterStepErrors(int step) {
    final errors = <String, String>{};

    switch (step) {
      case 0:
        if (firstNameController.text.trim().isEmpty) {
          errors['firstName'] = 'enter_first_name'.tr;
        }
        if (lastNameController.text.trim().isEmpty) {
          errors['lastName'] = 'enter_last_name'.tr;
        }
        final email = emailController.text.trim();
        if (email.isEmpty) {
          errors['email'] = 'enter_valid_email'.tr;
        } else if (!_isValidEmail(email)) {
          errors['email'] = 'enter_valid_email'.tr;
        }
        final phone = phoneController.text.trim();
        if (!_isValidSyrianMobile(phone)) {
          errors['phone'] = 'enter_valid_phone'.tr;
        }
        break;
      case 1:
        final password = registerPasswordController.text;
        final confirm = confirmPasswordController.text;
        if (password.isEmpty) {
          errors['password'] = 'enter_password'.tr;
        } else {
          final passwordError = _passwordValidationError(password);
          if (passwordError != null) errors['password'] = passwordError;
        }
        if (confirm.isEmpty) {
          errors['confirmPassword'] = 'confirm_password_required'.tr;
        } else if (password != confirm) {
          errors['confirmPassword'] = 'password_mismatch'.tr;
        }
        if (selectedGender.value == null) errors['gender'] = 'pick_gender'.tr;
        if (birthDate.value == null) {
          errors['birthDate'] = 'pick_birth_date'.tr;
        } else if (!_isValidBirthDate(birthDate.value!)) {
          errors['birthDate'] = 'pick_valid_birth_date'.tr;
        }
        break;
      case 2:
        if (selectedCityId.value == null) errors['city'] = 'pick_city_validation'.tr;
        if (requiresUniversityFields) {
          if (selectedUniversityId.value == null) errors['university'] = 'pick_university'.tr;
          if (selectedSpecializationId.value == null) {
            errors['specialization'] = 'pick_specialization'.tr;
          }
        }
        break;
    }

    return errors;
  }

  void _validatePasswordFieldsLive() {
    if (registerStep.value != 1) return;
    registerStep1Validated.value = false;

    final password = registerPasswordController.text;
    final confirm = confirmPasswordController.text;
    final nextErrors = Map<String, String>.from(registerFieldErrors);

    nextErrors.remove('password');
    nextErrors.remove('confirmPassword');

    if (password.isNotEmpty) {
      final passwordError = _passwordValidationError(password);
      if (passwordError != null) nextErrors['password'] = passwordError;
    }

    if (confirm.isNotEmpty || password.isNotEmpty) {
      if (confirm.isEmpty) {
        nextErrors['confirmPassword'] = 'confirm_password_required'.tr;
      } else if (password != confirm) {
        nextErrors['confirmPassword'] = 'password_mismatch'.tr;
      }
    }

    registerFieldErrors.assignAll(nextErrors);
    registerFieldErrors.refresh();
  }

  Future<bool> _validateRegisterStep0Remote() async {
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();

    final emailTaken = await _authRepository.isEmailTaken(email);
    if (emailTaken) {
      _applyRegisterFieldErrors({'email': 'email_already_registered'.tr});
      return true;
    }

    final phoneTaken = await _authRepository.isPhoneTaken(phone);
    if (phoneTaken) {
      _applyRegisterFieldErrors({'phone': 'phone_already_registered'.tr});
      return true;
    }

    return false;
  }

  bool _applyRegisterFieldErrors(Map<String, String> errors) {
    if (errors.isEmpty) return true;
    registerFieldErrors.assignAll(errors);
    registerStepError.value = errors.values.first;
    return false;
  }

  void _showRegisterStepError(String message) {
    registerStepError.value = message;
    Get.snackbar('alert'.tr, message);
  }

  void _applyApiRegisterErrors(ApiException e) {
    final apiFields = e.fieldErrors ?? {};
    if (apiFields.isEmpty) {
      final msg = e.message.toLowerCase();
      if (msg.contains('email')) {
        _applyRegisterFieldErrors({'email': e.message});
        registerStep.value = 0;
        registerStep0Validated.value = false;
        return;
      }
      if (msg.contains('phone')) {
        _applyRegisterFieldErrors({'phone': e.message});
        registerStep.value = 0;
        registerStep0Validated.value = false;
        return;
      }
      if (msg.contains('password')) {
        _applyRegisterFieldErrors({'password': e.message});
        registerStep.value = 1;
        registerStep1Validated.value = false;
        return;
      }
      if (msg.contains('preferred_tags') || msg.contains('preferred_categories') || msg.contains('tag_ids')) {
        _applyRegisterFieldErrors({'interests': e.message});
        registerStep.value = 2;
        return;
      }
      _showRegisterStepError(e.message);
      return;
    }

    final mapped = <String, String>{};
    for (final entry in apiFields.entries) {
      mapped[_mapApiFieldKey(entry.key)] = entry.value;
    }
    _applyRegisterFieldErrors(mapped);

    if (mapped.containsKey('email') || mapped.containsKey('phone')) {
      registerStep.value = 0;
      registerStep0Validated.value = false;
    } else if (mapped.containsKey('password') || mapped.containsKey('confirmPassword')) {
      registerStep.value = 1;
      registerStep1Validated.value = false;
    } else if (mapped.containsKey('interests')) {
      registerStep.value = 2;
    }
  }

  String _mapApiFieldKey(String key) {
    if (key.startsWith('preferred_tags') ||
        key.startsWith('preferred_tag_ids') ||
        key.startsWith('tag_ids') ||
        key.startsWith('preferred_categories') ||
        key.startsWith('preferred_category_ids') ||
        key.startsWith('category_ids')) {
      return 'interests';
    }
    switch (key) {
      case 'first_name':
        return 'firstName';
      case 'last_name':
        return 'lastName';
      case 'password_confirmation':
        return 'confirmPassword';
      case 'city_id':
        return 'city';
      case 'university_id':
        return 'university';
      case 'specialization_id':
        return 'specialization';
      case 'birth_date':
        return 'birthDate';
      default:
        return key;
    }
  }

  String? _passwordValidationError(String password) {
    if (password.length < 8) return 'password_min_8'.tr;
    if (!RegExp(r'[A-Za-z]').hasMatch(password) || !RegExp(r'\d').hasMatch(password)) {
      return 'password_must_have_letter_number'.tr;
    }
    return null;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}$').hasMatch(email);
  }

  bool _isValidBirthDate(DateTime date) {
    final now = DateTime.now();
    final minDate = DateTime(now.year - 100);
    final maxDate = DateTime(now.year - 10, now.month, now.day);
    return !date.isBefore(minDate) && !date.isAfter(maxDate);
  }

  static String formatBirthDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  bool _isValidSyrianMobile(String phone) {
    return RegExp(r'^09\d{8}$').hasMatch(phone);
  }

  double get registerProgress => (registerStep.value + 1) / 3;

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

  void resetAfterLogout() {
    errorMessage.value = null;
    registerStepError.value = null;
    registerFieldErrors.clear();
    registerStep.value = 0;
    registerStep0Validated.value = false;
    registerStep1Validated.value = false;
    isLoading.value = false;
    isAdvancingStep.value = false;
  }

  @override
  void onClose() {
    loginEmailController.dispose();
    loginPhoneController.dispose();
    passwordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    registerPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
