class StudentProfilePayload {
  StudentProfilePayload({
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.gender,
    this.birthDate,
    this.cityId,
    this.educationLevel,
    this.universityId,
    this.specializationId,
    this.universityEn,
    this.universityAr,
    this.specializationEn,
    this.specializationAr,
    this.interests,
    this.preferredCategories,
    this.currentPassword,
    this.clearFields = const {},
  });

  /// حقول أكاديمية أفرغها المستخدم: تُرسَل صراحة (`null` أو قائمة فارغة) كي يمسحها الخادم. الحقول الفارغة
  /// الأخرى تُحذف من الطلب كما كان، فيحتفظ الخادم بقيمها (حذفها كان يعني أن الإفراغ لا يصل أبداً).
  /// القيم: education_level, university_id, specialization_id, preferred_categories.
  final Set<String> clearFields;

  static const clearableFields = {'education_level', 'university_id', 'specialization_id', 'preferred_categories'};

  Map<String, dynamic> _clearedJson() => {
    for (final field in clearFields)
      if (clearableFields.contains(field)) field: field == 'preferred_categories' ? <int>[] : null,
  };

  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? gender;
  final String? birthDate;
  final int? cityId;
  final String? educationLevel;
  final int? universityId;
  final int? specializationId;
  final String? universityEn;
  final String? universityAr;
  final String? specializationEn;
  final String? specializationAr;
  final List<String>? interests;
  final List<int>? preferredCategories;

  /// مطلوبة عند تغيير البريد (حماية من تغييره بتوكن مسروق).
  final String? currentPassword;

  Map<String, dynamic>? _studentProfileJson() {
    final categories = preferredCategories;
    final hasCategories = categories != null && categories.isNotEmpty;
    final hasEducation = educationLevel != null && educationLevel!.isNotEmpty;
    final hasUniversity = universityId != null;
    final hasSpecialization = specializationId != null;

    if (!hasEducation &&
        !hasUniversity &&
        !hasSpecialization &&
        !hasCategories &&
        _clearedJson().isEmpty) {
      return null;
    }

    return {
      ..._clearedJson(),
      if (hasEducation) 'education_level': educationLevel,
      if (hasUniversity) 'university_id': universityId,
      if (hasSpecialization) 'specialization_id': specializationId,
      if (hasCategories) 'preferred_categories': categories,
    };
  }

  Map<String, dynamic> toJson() {
    final studentProfile = _studentProfileJson();

    return {
      ..._clearedJson(),
      if (firstName != null && firstName!.isNotEmpty) 'first_name': firstName,
      if (lastName != null && lastName!.isNotEmpty) 'last_name': lastName,
      if (email != null && email!.isNotEmpty) 'email': email,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      if (gender != null && gender!.isNotEmpty) 'gender': gender,
      if (birthDate != null && birthDate!.isNotEmpty) 'birth_date': birthDate,
      if (cityId != null) 'city_id': cityId,
      if (educationLevel != null && educationLevel!.isNotEmpty) 'education_level': educationLevel,
      if (universityId != null) 'university_id': universityId,
      if (specializationId != null) 'specialization_id': specializationId,
      if (universityEn != null && universityEn!.isNotEmpty) 'university_en': universityEn,
      if (universityAr != null && universityAr!.isNotEmpty) 'university_ar': universityAr,
      if (specializationEn != null && specializationEn!.isNotEmpty) 'specialization_en': specializationEn,
      if (specializationAr != null && specializationAr!.isNotEmpty) 'specialization_ar': specializationAr,
      if (interests != null && interests!.isNotEmpty) 'interests': interests,
      if (preferredCategories != null && preferredCategories!.isNotEmpty) 'preferred_categories': preferredCategories,
      if (currentPassword != null && currentPassword!.isNotEmpty) 'current_password': currentPassword,
      if (studentProfile != null) 'student_profile': studentProfile,
    };
  }
}
