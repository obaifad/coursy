import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/data/repositories/auth_repository.dart';
import '../../../core/data/repositories/category_repository.dart';
import '../../../core/data/repositories/city_repository.dart';
import '../../../core/data/repositories/profile_repository.dart';
import '../../../core/data/repositories/reference_repository.dart';
import '../../../core/models/app_models.dart';
import '../../../core/models/register_payload.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/favorites_service.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../core/utils/education_level_utils.dart';
import '../../../routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepository = Get.find();
  final CityRepository _cityRepository = Get.find();
  final CategoryRepository _categoryRepository = Get.find();
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
  final categoriesLoading = false.obs;
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

  @override
  void onInit() {
    super.onInit();
    loadCities();
    loadReferences();
    loadCategories();
  }

  Future<void> loadCities({bool force = false}) async {
    if (citiesLoading.value) return;
    if (!force && cities.isNotEmpty) return;
    citiesLoading.value = true;
    citiesError.value = null;
    try {
      cities.assignAll(await _cityRepository.fetchCities());
    } catch (_) {
      cities.clear();
    } finally {
      citiesLoading.value = false;
    }
  }

  Future<void> loadReferences({bool force = false}) async {
    if (referencesLoading.value) return;
    if (!force && universities.isNotEmpty && specializations.isNotEmpty) return;
    referencesLoading.value = true;
    try {
      final results = await Future.wait([
        _referenceRepository.fetchUniversities(),
        _referenceRepository.fetchStudentSpecializations(),
      ]);
      universities.assignAll(results[0]);
      specializations.assignAll(results[1]);
    } catch (_) {
      universities.clear();
      specializations.clear();
    } finally {
      referencesLoading.value = false;
    }
  }

  Future<void> loadCategories({bool force = false}) async {
    if (categoriesLoading.value) return;
    if (!force && categories.isNotEmpty) return;
    categoriesLoading.value = true;
    try {
      categories.assignAll(await _categoryRepository.fetchCategories());
    } catch (_) {
      categories.clear();
    } finally {
      categoriesLoading.value = false;
    }
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
    if (Get.isRegistered<FavoritesService>()) {
      await Get.find<FavoritesService>().syncFromApi();
    }
    AppNavigation.goToRoot(tab: 2);
  }

  void clearRegisterValidation() {
    registerStepError.value = null;
    registerFieldErrors.clear();
  }

  Future<void> nextRegisterStep() async {
    clearRegisterValidation();

    final fieldErrors = _collectRegisterStepErrors(registerStep.value);
    if (!_applyRegisterFieldErrors(fieldErrors)) return;

    isLoading.value = true;
    try {
      if (registerStep.value == 0) {
        final remoteError = await _validateRegisterStep0Remote();
        if (remoteError != null) {
          _showRegisterStepError(remoteError);
          return;
        }
      }

      if (registerStep.value < 2) {
        registerStep.value++;
        if (registerStep.value == 2) {
          loadCities(force: cities.isEmpty);
          loadReferences(force: universities.isEmpty || specializations.isEmpty);
          loadCategories(force: categories.isEmpty);
        }
      }
    } on ApiException catch (e) {
      _showRegisterStepError(e.message);
    } catch (_) {
      _showRegisterStepError('connection_error'.tr);
    } finally {
      isLoading.value = false;
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
    clearRegisterValidation();

    for (var step = 0; step <= 2; step++) {
      final fieldErrors = _collectRegisterStepErrors(step);
      if (fieldErrors.isNotEmpty) {
        registerStep.value = step;
        _applyRegisterFieldErrors(fieldErrors);
        return;
      }
    }

    isLoading.value = true;
    try {
      if (await _authRepository.isEmailTaken(emailController.text.trim())) {
        registerStep.value = 0;
        _applyRegisterFieldErrors({'email': 'email_already_registered'.tr});
        return;
      }
      if (await _authRepository.isPhoneTaken(phoneController.text.trim())) {
        registerStep.value = 0;
        _applyRegisterFieldErrors({'phone': 'phone_already_registered'.tr});
        return;
      }
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
        preferredCategories: selectedCategoryIds.isEmpty ? null : selectedCategoryIds.toList(),
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
      Get.snackbar('register_failed'.tr, registerStepError.value ?? e.message);
    } catch (_) {
      _showRegisterStepError('connection_error'.tr);
      Get.snackbar('error'.tr, 'connection_error'.tr);
    } finally {
      isLoading.value = false;
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

  Future<String?> _validateRegisterStep0Remote() async {
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();

    final emailTaken = await _authRepository.isEmailTaken(email);
    if (emailTaken) {
      _applyRegisterFieldErrors({'email': 'email_already_registered'.tr});
      return 'email_already_registered'.tr;
    }

    final phoneTaken = await _authRepository.isPhoneTaken(phone);
    if (phoneTaken) {
      _applyRegisterFieldErrors({'phone': 'phone_already_registered'.tr});
      return 'phone_already_registered'.tr;
    }

    return null;
  }

  bool _applyRegisterFieldErrors(Map<String, String> errors) {
    if (errors.isEmpty) return true;
    registerFieldErrors.assignAll(errors);
    registerStepError.value = errors.values.first;
    Get.snackbar('alert'.tr, errors.values.first);
    return false;
  }

  void _showRegisterStepError(String message) {
    registerStepError.value = message;
    Get.snackbar('alert'.tr, message);
  }

  void _applyApiRegisterErrors(ApiException e) {
    final apiFields = e.fieldErrors ?? {};
    if (apiFields.isEmpty) {
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
    } else if (mapped.containsKey('password') || mapped.containsKey('confirmPassword')) {
      registerStep.value = 1;
    }
  }

  String _mapApiFieldKey(String key) {
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
    if (password.length < 6) return 'password_min_6'.tr;
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
