/// بيانات إنشاء حساب طالب — مطابقة لـ `/api/student/register` و`student_profile`.
class RegisterPayload {
  RegisterPayload({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
    required this.cityId,
    this.phone,
    this.gender,
    this.birthDate,
    this.deviceName = 'flutter',
    this.educationLevel,
    this.universityId,
    this.specializationId,
    this.preferredCategories,
    this.notificationRadiusKm,
    this.role = 'student',
    this.isActive = true,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String passwordConfirmation;
  final int cityId;
  final String? phone;
  final String? gender;
  final String? birthDate;
  final String deviceName;
  final String? educationLevel;
  final int? universityId;
  final int? specializationId;
  final List<int>? preferredCategories;
  final int? notificationRadiusKm;
  final String role;
  final bool isActive;

  String get fullName => '$firstName $lastName'.trim();

  Map<String, dynamic>? _studentProfileJson() {
    final categories = preferredCategories;
    final hasCategories = categories != null && categories.isNotEmpty;
    final hasEducation = educationLevel != null && educationLevel!.isNotEmpty;
    final hasUniversity = universityId != null;
    final hasSpecialization = specializationId != null;
    final hasRadius = notificationRadiusKm != null;

    if (!hasEducation && !hasUniversity && !hasSpecialization && !hasCategories && !hasRadius) {
      return null;
    }

    return {
      if (hasEducation) 'education_level': educationLevel,
      if (hasUniversity) 'university_id': universityId,
      if (hasSpecialization) 'specialization_id': specializationId,
      if (hasCategories) 'preferred_categories': categories,
      if (hasRadius) 'notification_radius_km': notificationRadiusKm,
    };
  }

  Map<String, dynamic> toJson() {
    final studentProfile = _studentProfileJson();

    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'role': role,
      'city_id': cityId,
      'device_name': deviceName,
      'is_active': isActive ? 1 : 0,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      if (gender != null && gender!.isNotEmpty) 'gender': gender,
      if (birthDate != null && birthDate!.isNotEmpty) 'birth_date': birthDate,
      if (studentProfile != null) 'student_profile': studentProfile,
    };
  }
}
