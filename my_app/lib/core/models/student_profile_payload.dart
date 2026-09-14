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
    this.preferredTags,
    this.notificationRadiusKm,
  });

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
  final List<int>? preferredTags;
  final int? notificationRadiusKm;

  Map<String, dynamic>? _studentProfileJson() {
    final tags = preferredTags;
    final hasTags = tags != null && tags.isNotEmpty;
    final hasEducation = educationLevel != null && educationLevel!.isNotEmpty;
    final hasUniversity = universityId != null;
    final hasSpecialization = specializationId != null;
    final hasRadius = notificationRadiusKm != null;

    if (!hasEducation && !hasUniversity && !hasSpecialization && !hasTags && !hasRadius) {
      return null;
    }

    return {
      if (hasEducation) 'education_level': educationLevel,
      if (hasUniversity) 'university_id': universityId,
      if (hasSpecialization) 'specialization_id': specializationId,
      if (hasTags) ...{
        'preferred_tags': tags,
        'tag_ids': tags,
      },
      if (hasRadius) 'notification_radius_km': notificationRadiusKm,
    };
  }

  Map<String, dynamic> toJson() {
    final studentProfile = _studentProfileJson();

    return {
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
      if (preferredTags != null && preferredTags!.isNotEmpty) 'preferred_tags': preferredTags,
      if (notificationRadiusKm != null) 'notification_radius_km': notificationRadiusKm,
      if (studentProfile != null) 'student_profile': studentProfile,
    };
  }
}
