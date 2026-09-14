import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/api_config.dart';
import 'json_helpers.dart';
import 'media_path_resolver.dart';

class CityModel {
  CityModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.institutesCount = 0,
    this.coursesCount = 0,
  });

  final int id;
  final String nameAr;
  final String nameEn;
  final int institutesCount;
  final int coursesCount;

  String get name => JsonHelpers.pickLocalized(ar: nameAr, en: nameEn);

  factory CityModel.fromJson(Map<String, dynamic> json) {
    final names = JsonHelpers.bilingualText(json);
    return CityModel(
      id: JsonHelpers.parseInt(json['id']),
      nameAr: names.ar,
      nameEn: names.en,
      institutesCount: JsonHelpers.parseInt(json['institutes_count']),
      coursesCount: JsonHelpers.parseInt(json['courses_count']),
    );
  }
}

/// تخصص من `/specializations?type=student` أو `type=instructor`.
class SpecializationModel {
  SpecializationModel({
    required this.id,
    required this.type,
    required this.name,
    this.nameEn,
    this.nameAr,
  });

  final int id;
  final String type;
  final String name;
  final String? nameEn;
  final String? nameAr;

  bool get isInstructor => type.toLowerCase() == 'instructor';

  bool get isStudent => type.toLowerCase() == 'student';

  String get filterKey => 'spec:$id';

  NamedEntity toNamedEntity() {
    final names = JsonHelpers.bilingualText({
      'name': name,
      if (nameAr != null) 'name_ar': nameAr,
      if (nameEn != null) 'name_en': nameEn,
    });
    return NamedEntity(id: id, nameAr: names.ar, nameEn: names.en);
  }

  String get displayName {
    return JsonHelpers.pickLocalized(
      ar: nameAr ?? (JsonHelpers.containsArabicScript(name) ? name : ''),
      en: nameEn ?? (!JsonHelpers.containsArabicScript(name) ? name : ''),
      fallback: name,
    );
  }

  factory SpecializationModel.fromJson(Map<String, dynamic> json) {
    final localized = JsonHelpers.localizedText(json, 'name');
    final nameEn = json['name_en']?.toString().trim();
    final nameAr = json['name_ar']?.toString().trim();
    return SpecializationModel(
      id: JsonHelpers.parseInt(json['id']),
      type: json['type']?.toString() ?? '',
      name: localized.isNotEmpty ? localized : (json['name']?.toString() ?? nameEn ?? nameAr ?? ''),
      nameEn: (nameEn != null && nameEn.isNotEmpty) ? nameEn : null,
      nameAr: (nameAr != null && nameAr.isNotEmpty) ? nameAr : null,
    );
  }

  InstructorSubjectModel toSubjectFilter() {
    return InstructorSubjectModel(
      key: filterKey,
      name: displayName,
      nameEn: nameEn,
      nameAr: nameAr,
      specializationId: id,
    );
  }
}

/// كيان بسيط (جامعة / اختصاص) — {id, name}.
class NamedEntity {
  NamedEntity({required this.id, required this.nameAr, required this.nameEn});

  final int id;
  final String nameAr;
  final String nameEn;

  String get name => JsonHelpers.pickLocalized(ar: nameAr, en: nameEn);

  factory NamedEntity.fromJson(Map<String, dynamic> json) {
    final names = JsonHelpers.bilingualText(json);
    return NamedEntity(
      id: JsonHelpers.parseInt(json['id']),
      nameAr: names.ar,
      nameEn: names.en,
    );
  }
}

class CategoryModel {
  CategoryModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.icon,
    this.coursesCount = 0,
  });

  final int id;
  final String nameAr;
  final String nameEn;
  /// القيمة الخام من الـ API: slug مثل heroicon-o-briefcase أو مسار/رابط صورة.
  final String? icon;
  final int coursesCount;

  String get name => JsonHelpers.pickLocalized(ar: nameAr, en: nameEn);

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final names = JsonHelpers.bilingualText(json);
    return CategoryModel(
      id: JsonHelpers.parseInt(json['id']),
      nameAr: names.ar,
      nameEn: names.en,
      icon: _parseIcon(json['icon']),
      coursesCount: JsonHelpers.parseInt(json['courses_count']),
    );
  }

  static String? _parseIcon(dynamic raw) {
    if (raw == null) return null;
    final value = raw.toString().trim();
    return value.isEmpty ? null : value;
  }

  /// slug بعد إزالة بادئة heroicon (مثلاً heroicon-o-briefcase → briefcase).
  String? get iconSlug {
    if (icon == null) return null;
    final value = icon!.trim().toLowerCase().replaceAll('\\', '/');
    if (_looksLikeMediaPath(value)) return null;
    return _stripHeroiconPrefix(value);
  }

  /// رابط صورة الأيقونة عندما يعيد الـ API مساراً أو URL.
  String? get iconImageUrl {
    if (icon == null) return null;
    if (!_looksLikeMediaPath(icon!)) return null;
    return ApiConfig.resolveMediaUrl(icon);
  }

  static String _stripHeroiconPrefix(String value) {
    const prefixes = ['heroicon-o-', 'heroicon-s-', 'heroicon-m-', 'heroicon-mini-', 'heroicon-'];
    for (final prefix in prefixes) {
      if (value.startsWith(prefix)) return value.substring(prefix.length);
    }
    return value;
  }

  static bool _looksLikeMediaPath(String value) {
    final v = value.trim().toLowerCase().replaceAll('\\', '/');
    if (v.startsWith('http://') || v.startsWith('https://')) return true;
    if (v.startsWith('storage/') || v.startsWith('/storage/')) return true;
    if (v.contains('/')) return true;
    return v.endsWith('.png') ||
        v.endsWith('.jpg') ||
        v.endsWith('.jpeg') ||
        v.endsWith('.webp') ||
        v.endsWith('.gif') ||
        v.endsWith('.svg');
  }

  IconData get iconData {
    final key = iconSlug;
    if (key == null || key.isEmpty) return Icons.category_rounded;
    return _iconForSlug(key);
  }

  static IconData _iconForSlug(String key) {
    const icons = <String, IconData>{
      'code': Icons.code_rounded,
      'code-bracket': Icons.code_rounded,
      'programming': Icons.code_rounded,
      'development': Icons.code_rounded,
      'languages': Icons.translate_rounded,
      'language': Icons.translate_rounded,
      'globe-alt': Icons.language_rounded,
      'palette': Icons.palette_rounded,
      'design': Icons.palette_rounded,
      'paint-brush': Icons.brush_rounded,
      'swatch': Icons.palette_rounded,
      'briefcase': Icons.business_center_rounded,
      'business': Icons.business_center_rounded,
      'building-office': Icons.business_rounded,
      'megaphone': Icons.campaign_rounded,
      'marketing': Icons.campaign_rounded,
      'speaker-wave': Icons.campaign_rounded,
      'science': Icons.science_rounded,
      'data': Icons.science_rounded,
      'beaker': Icons.science_rounded,
      'school': Icons.school_rounded,
      'education': Icons.school_rounded,
      'academic-cap': Icons.school_rounded,
      'book-open': Icons.menu_book_rounded,
      'computer': Icons.computer_rounded,
      'tech': Icons.computer_rounded,
      'computer-desktop': Icons.computer_rounded,
      'device-phone-mobile': Icons.smartphone_rounded,
      'finance': Icons.account_balance_wallet_rounded,
      'accounting': Icons.account_balance_wallet_rounded,
      'banknotes': Icons.payments_rounded,
      'currency-dollar': Icons.attach_money_rounded,
      'health': Icons.medical_services_rounded,
      'medical': Icons.medical_services_rounded,
      'heart': Icons.favorite_rounded,
      'music': Icons.music_note_rounded,
      'musical-note': Icons.music_note_rounded,
      'photo': Icons.photo_camera_rounded,
      'camera': Icons.photo_camera_rounded,
      'video-camera': Icons.videocam_rounded,
      'chart-bar': Icons.bar_chart_rounded,
      'presentation-chart-line': Icons.insights_rounded,
      'calculator': Icons.calculate_rounded,
      'light-bulb': Icons.lightbulb_rounded,
      'puzzle-piece': Icons.extension_rounded,
      'rocket-launch': Icons.rocket_launch_rounded,
      'user-group': Icons.groups_rounded,
      'wrench': Icons.build_rounded,
      'cog': Icons.settings_rounded,
      'tag': Icons.local_offer_rounded,
      'star': Icons.star_rounded,
      'sparkles': Icons.auto_awesome_rounded,
    };
    return icons[key] ?? icons[key.replaceAll('-', '_')] ?? Icons.category_rounded;
  }
}

class ScheduleModel {
  ScheduleModel({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  final int id;
  final String dayOfWeek;
  final String startTime;
  final String endTime;

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: JsonHelpers.parseInt(json['id']),
      dayOfWeek: json['day_of_week']?.toString() ??
          json['day']?.toString() ??
          json['weekday']?.toString() ??
          '',
      startTime: _shortTime(json['start_time'] ?? json['starts_at'] ?? json['from']),
      endTime: _shortTime(json['end_time'] ?? json['ends_at'] ?? json['to']),
    );
  }

  static String _shortTime(dynamic value) {
    final s = value?.toString() ?? '';
    if (s.length >= 5) return s.substring(0, 5);
    return s;
  }

  String get display => '${JsonHelpers.weekdayLabel(dayOfWeek)} · $startTime - $endTime';
}

class InstructorInstituteLink {
  InstructorInstituteLink({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.rating = 0,
    this.isVerified = false,
    this.phone,
    this.whatsapp,
    this.website,
    this.facebook,
    this.instagram,
  });

  final int id;
  final String name;
  final String? description;
  final String? address;
  final double rating;
  final bool isVerified;
  final String? phone;
  final String? whatsapp;
  final String? website;
  final String? facebook;
  final String? instagram;

  factory InstructorInstituteLink.fromJson(Map<String, dynamic> json) {
    final name = JsonHelpers.localizedText(json, 'name');
    final description = JsonHelpers.localizedText(json, 'description');
    final address = JsonHelpers.localizedText(json, 'address');
    return InstructorInstituteLink(
      id: JsonHelpers.parseInt(json['id']),
      name: name.isNotEmpty ? name : (json['name']?.toString() ?? ''),
      description: description.isNotEmpty ? description : json['description']?.toString(),
      address: address.isNotEmpty ? address : json['address']?.toString(),
      rating: JsonHelpers.parseDouble(json['average_rating'] ?? json['rating']),
      isVerified: JsonHelpers.parseBool(json['is_verified']),
      phone: json['phone']?.toString(),
      whatsapp: json['whatsapp']?.toString(),
      website: json['website']?.toString(),
      facebook: json['facebook']?.toString(),
      instagram: json['instagram']?.toString(),
    );
  }
}

/// مادة/تخصص يدرّسها المدرّب — تُجمّع من حقل specialization في الـ API.
class InstructorSubjectModel {
  InstructorSubjectModel({
    required this.key,
    required this.name,
    this.nameEn,
    this.nameAr,
    this.instructorsCount = 0,
    this.specializationId,
  });

  final String key;
  final String name;
  final String? nameEn;
  final String? nameAr;
  final int instructorsCount;
  final int? specializationId;

  bool get isApiSpecialization => specializationId != null || key.startsWith('spec:');

  int? get resolvedSpecializationId {
    if (specializationId != null) return specializationId;
    if (key.startsWith('spec:')) return int.tryParse(key.substring(5));
    return null;
  }

  InstructorSubjectModel copyWith({int? instructorsCount}) {
    return InstructorSubjectModel(
      key: key,
      name: name,
      nameEn: nameEn,
      nameAr: nameAr,
      instructorsCount: instructorsCount ?? this.instructorsCount,
      specializationId: specializationId,
    );
  }

  static String keyFromParts({String? en, String? ar, String? localized}) {
    final source = (en?.trim().isNotEmpty == true)
        ? en!.trim()
        : (ar?.trim().isNotEmpty == true)
            ? ar!.trim()
            : (localized?.trim() ?? '');
    if (source.isEmpty) return '';
    return source.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF]+'), '-').replaceAll(RegExp(r'-+'), '-').replaceAll(RegExp(r'^-|-$'), '');
  }

  IconData get iconData {
    final probe = '${nameEn ?? ''} ${nameAr ?? ''} $name'.toLowerCase();
    if (probe.contains('mobile') || probe.contains('flutter') || probe.contains('موبايل')) {
      return Icons.phone_android_rounded;
    }
    if (probe.contains('laravel') || probe.contains('api') || probe.contains('backend') || probe.contains('برمج')) {
      return Icons.code_rounded;
    }
    if (probe.contains('frontend') || probe.contains('واجه')) return Icons.web_rounded;
    if (probe.contains('design') || probe.contains('graphic') || probe.contains('product') || probe.contains('تصميم')) {
      return Icons.palette_rounded;
    }
    if (probe.contains('ux') || probe.contains('research') || probe.contains('مستخدم')) {
      return Icons.psychology_rounded;
    }
    if (probe.contains('data') || probe.contains('science') || probe.contains('بيانات')) {
      return Icons.analytics_rounded;
    }
    if (probe.contains('marketing') || probe.contains('digital') || probe.contains('تسويق')) {
      return Icons.campaign_rounded;
    }
    if (probe.contains('english') || probe.contains('language') || probe.contains('لغ')) {
      return Icons.translate_rounded;
    }
    if (probe.contains('project') || probe.contains('management') || probe.contains('business') || probe.contains('أعمال') || probe.contains('مشاريع')) {
      return Icons.business_center_rounded;
    }
    return Icons.menu_book_rounded;
  }
}

class InstructorModel {
  InstructorModel({
    required this.id,
    String? name,
    String? nameAr,
    String? nameEn,
    this.bio,
    this.specialization,
    this.specializationEn,
    this.specializationAr,
    this.specializationId,
    this.experienceYears = 0,
    this.imageUrl,
    this.isPrivate = false,
    this.mobile,
    this.sessionPrice,
    this.hourlyPrice,
    this.address,
    this.institutes = const [],
  })  : nameAr = nameAr ?? name ?? '',
        nameEn = nameEn ?? name ?? '';

  final int id;
  final String nameAr;
  final String nameEn;
  final String? bio;
  final String? specialization;
  final String? specializationEn;
  final String? specializationAr;
  final int? specializationId;
  final int experienceYears;
  final String? imageUrl;
  final bool isPrivate;
  final String? mobile;
  final String? sessionPrice;
  final String? hourlyPrice;
  final String? address;
  final List<InstructorInstituteLink> institutes;

  String get name => JsonHelpers.pickLocalized(ar: nameAr, en: nameEn);

  String? get resolvedImageUrl => ApiConfig.resolveMediaUrl(imageUrl);

  String get subjectKey => InstructorSubjectModel.keyFromParts(
        en: specializationEn,
        ar: specializationAr,
        localized: specialization,
      );

  factory InstructorModel.fromJson(Map<String, dynamic> json) {
    final names = JsonHelpers.bilingualText(json);
    final bio = JsonHelpers.localizedText(json, 'bio');
    var specializationId = JsonHelpers.parseIntOrNull(json['specialization_id']);
    var specialization = JsonHelpers.localizedText(json, 'specialization');
    var specializationEn = json['specialization_en']?.toString().trim();
    var specializationAr = json['specialization_ar']?.toString().trim();
    final specRaw = json['specialization'];
    if (specRaw is Map<String, dynamic>) {
      specializationId ??= JsonHelpers.parseIntOrNull(specRaw['id']);
      specializationEn ??= specRaw['name_en']?.toString().trim();
      specializationAr ??= specRaw['name_ar']?.toString().trim();
      final nested = JsonHelpers.localizedText(specRaw, 'name');
      if (nested.isNotEmpty) specialization = nested;
    } else if (specRaw is Map) {
      final spec = Map<String, dynamic>.from(specRaw);
      specializationId ??= JsonHelpers.parseIntOrNull(spec['id']);
      specializationEn ??= spec['name_en']?.toString().trim();
      specializationAr ??= spec['name_ar']?.toString().trim();
      final nested = JsonHelpers.localizedText(spec, 'name');
      if (nested.isNotEmpty) specialization = nested;
    }
    final address = JsonHelpers.localizedText(json, 'address');
    final institutesRaw = json['institutes'];
    final institutes = institutesRaw is List
        ? institutesRaw
            .map((e) => e is Map ? InstructorInstituteLink.fromJson(Map<String, dynamic>.from(e)) : null)
            .whereType<InstructorInstituteLink>()
            .toList()
        : const <InstructorInstituteLink>[];

    return InstructorModel(
      id: JsonHelpers.parseInt(json['id']),
      nameAr: names.ar,
      nameEn: names.en,
      bio: bio.isNotEmpty ? bio : (json['bio']?.toString() ?? json['bio_ar']?.toString() ?? json['bio_en']?.toString()),
      specialization: specialization.isNotEmpty
          ? specialization
          : (json['specialization']?.toString() ??
              json['specialization_ar']?.toString() ??
              json['specialization_en']?.toString()),
      specializationEn: (specializationEn != null && specializationEn.isNotEmpty) ? specializationEn : null,
      specializationAr: (specializationAr != null && specializationAr.isNotEmpty) ? specializationAr : null,
      specializationId: specializationId,
      experienceYears: JsonHelpers.parseInt(json['experience_years']),
      imageUrl: json['image']?.toString(),
      isPrivate: JsonHelpers.parseBool(json['is_private']),
      mobile: json['mobile']?.toString(),
      sessionPrice: _instructorPriceLabel(json['session_price']),
      hourlyPrice: _instructorPriceLabel(json['hourly_price']),
      address: address.isNotEmpty ? address : json['address']?.toString(),
      institutes: institutes,
    );
  }

  static String? _instructorPriceLabel(dynamic raw) {
    if (raw == null) return null;
    final value = JsonHelpers.parseDouble(raw);
    if (value <= 0) return null;
    return JsonHelpers.formatSyrianPrice(value);
  }
}

class CourseModel {
  CourseModel({
    required this.id,
    String? title,
    String? titleAr,
    String? titleEn,
    String? institute,
    String? instituteAr,
    String? instituteEn,
    required this.price,
    required this.rating,
    required this.duration,
    required this.level,
    this.instituteId,
    this.categoryId,
    this.description,
    this.requirements,
    this.studentsCount,
    this.confirmedStudentsCount,
    this.maxStudents,
    this.durationHours,
    this.sessionsCount,
    this.studyType,
    this.language,
    this.startDate,
    this.endDate,
    this.registrationDeadline,
    this.certificateAvailable = false,
    this.requiresAdvancePayment = false,
    this.instituteCity,
    this.instituteAddress,
    this.institutePhone,
    this.instituteWhatsapp,
    this.instituteWebsite,
    this.schedules = const [],
    this.instructor,
    this.categoryName,
    this.isFeatured = false,
    this.rawPrice,
    this.discountPrice,
    this.imageUrl,
  })  : titleAr = titleAr ?? title ?? '',
        titleEn = titleEn ?? title ?? '',
        instituteAr = instituteAr ?? institute ?? '',
        instituteEn = instituteEn ?? institute ?? '';

  final int id;
  final String titleAr;
  final String titleEn;
  final String instituteAr;
  final String instituteEn;
  final String price;
  final double rating;
  final String duration;
  final String level;
  final int? instituteId;
  final int? categoryId;
  final String? description;
  final String? requirements;
  final int? studentsCount;
  final int? confirmedStudentsCount;
  final int? maxStudents;
  final int? durationHours;
  final int? sessionsCount;
  final String? studyType;
  final String? language;
  final String? startDate;
  final String? endDate;
  final String? registrationDeadline;
  final bool certificateAvailable;
  final bool requiresAdvancePayment;
  final String? instituteCity;
  final String? instituteAddress;
  final String? institutePhone;
  final String? instituteWhatsapp;
  final String? instituteWebsite;
  final List<ScheduleModel> schedules;
  final InstructorModel? instructor;
  final String? categoryName;
  final bool isFeatured;
  final String? rawPrice;
  final String? discountPrice;
  final String? imageUrl;

  String get title => JsonHelpers.pickLocalized(ar: titleAr, en: titleEn);

  String get institute => JsonHelpers.pickLocalized(ar: instituteAr, en: instituteEn);

  String? get resolvedImageUrl => ApiConfig.resolveMediaUrl(imageUrl);

  /// هل ما زالت فترة التسجيل مفتوحة (اليوم ≤ آخر موعد للتسجيل).
  bool get isRegistrationOpen {
    final deadline = registrationDeadline;
    if (deadline == null || deadline.trim().isEmpty) return true;
    final deadlineDay = JsonHelpers.tryParseDateOnly(deadline);
    if (deadlineDay == null) return true;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(deadlineDay.year, deadlineDay.month, deadlineDay.day);
    return !today.isAfter(lastDay);
  }

  bool get isRegistrationClosed => !isRegistrationOpen;

  String? get primaryInstituteContact {
    final phone = institutePhone?.trim();
    if (phone != null && phone.isNotEmpty) return phone;
    final whatsapp = instituteWhatsapp?.trim();
    if (whatsapp != null && whatsapp.isNotEmpty) return whatsapp;
    return null;
  }

  bool get hasDiscount {
    final discount = JsonHelpers.parseDouble(discountPrice);
    return discount > 0;
  }

  String? get originalPriceLabel {
    if (!hasDiscount) return null;
    return JsonHelpers.formatSyrianPrice(rawPrice);
  }

  /// عدد المسجّلين المؤكّدين فقط (بدون المعلقين).
  int get enrolledCountForCapacity => confirmedStudentsCount ?? studentsCount ?? 0;

  double get effectivePrice {
    final discount = JsonHelpers.parseDouble(discountPrice);
    if (discount > 0) return discount;
    return JsonHelpers.parseDouble(rawPrice);
  }

  String get seatsLabel {
    final current = enrolledCountForCapacity;
    final max = maxStudents;
    if (max != null && max > 0) {
      return 'course_seats'.trParams({'current': '$current', 'max': '$max'});
    }
    return 'students_count'.trParams({'n': '$current'});
  }

  static int? _parseConfirmedStudents(Map<String, dynamic> json) {
    const keys = [
      'confirmed_students_count',
      'confirmed_students',
      'approved_students_count',
      'active_enrollments_count',
    ];
    for (final key in keys) {
      final value = JsonHelpers.parseIntOrNull(json[key]);
      if (value != null) return value;
    }
    final count = json['_count'];
    if (count is Map) {
      for (final key in ['confirmed_enrollments', 'confirmed_students', 'active_enrollments']) {
        final value = JsonHelpers.parseIntOrNull(count[key]);
        if (value != null) return value;
      }
    }
    return null;
  }

  CourseModel copyWith({
    String? imageUrl,
    List<ScheduleModel>? schedules,
    InstructorModel? instructor,
    String? categoryName,
    String? description,
    String? requirements,
    String? instituteCity,
    String? instituteAddress,
    String? institutePhone,
    String? instituteWhatsapp,
    String? instituteWebsite,
    double? rating,
    int? studentsCount,
    int? confirmedStudentsCount,
  }) {
    return CourseModel(
      id: id,
      title: title,
      institute: institute,
      price: price,
      rating: rating ?? this.rating,
      duration: duration,
      level: level,
      instituteId: instituteId,
      categoryId: categoryId,
      description: description ?? this.description,
      requirements: requirements ?? this.requirements,
      studentsCount: studentsCount ?? this.studentsCount,
      confirmedStudentsCount: confirmedStudentsCount ?? this.confirmedStudentsCount,
      maxStudents: maxStudents,
      durationHours: durationHours,
      sessionsCount: sessionsCount,
      studyType: studyType,
      language: language,
      startDate: startDate,
      endDate: endDate,
      registrationDeadline: registrationDeadline,
      certificateAvailable: certificateAvailable,
      requiresAdvancePayment: requiresAdvancePayment,
      instituteCity: instituteCity ?? this.instituteCity,
      instituteAddress: instituteAddress ?? this.instituteAddress,
      institutePhone: institutePhone ?? this.institutePhone,
      instituteWhatsapp: instituteWhatsapp ?? this.instituteWhatsapp,
      instituteWebsite: instituteWebsite ?? this.instituteWebsite,
      schedules: schedules ?? this.schedules,
      instructor: instructor ?? this.instructor,
      categoryName: categoryName ?? this.categoryName,
      isFeatured: isFeatured,
      rawPrice: rawPrice,
      discountPrice: discountPrice,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  static String? _extractCourseImagePath(Map<String, dynamic> json) {
    return MediaPathResolver.extractCourseImage(json);
  }

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    final instituteObj = json['institute'];
    var instituteNameAr = '';
    var instituteNameEn = '';
    var instituteRating = 0.0;
    var instituteId = JsonHelpers.parseIntOrNull(json['institute_id']);
    String? instituteCity;
    String? instituteAddress;
    String? institutePhone;
    String? instituteWhatsapp;
    String? instituteWebsite;

    if (instituteObj is Map<String, dynamic>) {
      final instituteNames = JsonHelpers.bilingualText(instituteObj);
      instituteNameAr = instituteNames.ar;
      instituteNameEn = instituteNames.en;
      instituteId = JsonHelpers.parseInt(instituteObj['id']);
      instituteRating = JsonHelpers.parseDouble(instituteObj['average_rating']);
      instituteAddress = instituteObj['address']?.toString() ??
          JsonHelpers.localizedText(instituteObj, 'address');
      institutePhone = instituteObj['phone']?.toString();
      instituteWhatsapp = instituteObj['whatsapp']?.toString();
      instituteWebsite = instituteObj['website']?.toString();
      final cityObj = instituteObj['city'];
      if (cityObj is Map<String, dynamic>) {
        instituteCity = JsonHelpers.pickLocalized(
          ar: JsonHelpers.bilingualText(cityObj).ar,
          en: JsonHelpers.bilingualText(cityObj).en,
        );
      }
    } else if (instituteObj is String && instituteObj.trim().isNotEmpty) {
      final flat = instituteObj.trim();
      if (JsonHelpers.containsArabicScript(flat)) {
        instituteNameAr = flat;
      } else {
        instituteNameEn = flat;
      }
    }
    if (instituteNameAr.isEmpty && instituteNameEn.isEmpty) {
      final flatInstitute = JsonHelpers.bilingualText(json, 'institute_name');
      instituteNameAr = flatInstitute.ar;
      instituteNameEn = flatInstitute.en;
    }

    final categoryObj = json['category'];
    String? categoryName;
    int? categoryId = JsonHelpers.parseIntOrNull(json['category_id']);
    if (categoryObj is Map<String, dynamic>) {
      final catNames = JsonHelpers.bilingualText(categoryObj);
      categoryName = JsonHelpers.pickLocalized(ar: catNames.ar, en: catNames.en);
      categoryId = JsonHelpers.parseInt(categoryObj['id']);
    }
    if ((categoryName ?? '').isEmpty) {
      final flatCategory = JsonHelpers.bilingualText(json, 'category_name');
      categoryName = JsonHelpers.pickLocalized(ar: flatCategory.ar, en: flatCategory.en);
    }

    InstructorModel? instructor;
    if (json['instructor'] is Map<String, dynamic>) {
      instructor = InstructorModel.fromJson(json['instructor'] as Map<String, dynamic>);
    }

    final schedulesList = <ScheduleModel>[];
    if (json['schedules'] is List) {
      for (final item in json['schedules'] as List) {
        if (item is Map<String, dynamic>) {
          schedulesList.add(ScheduleModel.fromJson(item));
        }
      }
    }

    final levelRaw = json['level']?.toString();
    final hours = JsonHelpers.parseIntOrNull(json['duration_hours']);
    final sessions = JsonHelpers.parseIntOrNull(json['sessions_count']);

    final titleNames = JsonHelpers.bilingualText(json, 'title');
    final description = JsonHelpers.localizedText(json, 'description');
    final requirements = JsonHelpers.localizedText(json, 'requirements');

    return CourseModel(
      id: JsonHelpers.parseInt(json['id']),
      titleAr: titleNames.ar,
      titleEn: titleNames.en,
      instituteAr: instituteNameAr,
      instituteEn: instituteNameEn,
      instituteId: instituteId,
      categoryId: categoryId,
      price: JsonHelpers.formatSyrianPrice(json['price'], discount: json['discount_price']),
      rawPrice: json['price']?.toString(),
      discountPrice: json['discount_price']?.toString(),
      imageUrl: _extractCourseImagePath(json),
      rating: JsonHelpers.resolveCourseRating(json, fallback: instituteRating),
      duration: JsonHelpers.durationLabel(hours: hours, sessions: sessions),
      level: JsonHelpers.levelLabel(levelRaw),
      description: description.isNotEmpty ? description : json['description']?.toString(),
      requirements: requirements.isNotEmpty ? requirements : json['requirements']?.toString(),
      studentsCount: JsonHelpers.parseIntOrNull(json['current_students']),
      confirmedStudentsCount: _parseConfirmedStudents(json),
      maxStudents: JsonHelpers.parseIntOrNull(json['max_students']),
      durationHours: hours,
      sessionsCount: sessions,
      studyType: JsonHelpers.studyTypeLabel(json['study_type']?.toString()),
      language: json['language']?.toString(),
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
      registrationDeadline: json['registration_deadline']?.toString(),
      certificateAvailable: JsonHelpers.parseBool(json['certificate_available']),
      requiresAdvancePayment: JsonHelpers.parseBool(json['requires_advance_payment']),
      instituteCity: instituteCity,
      instituteAddress: instituteAddress,
      institutePhone: institutePhone,
      instituteWhatsapp: instituteWhatsapp,
      instituteWebsite: instituteWebsite,
      schedules: schedulesList,
      instructor: instructor,
      categoryName: categoryName,
      isFeatured: JsonHelpers.parseBool(json['is_featured']),
    );
  }
}

class InstituteModel {
  InstituteModel({
    required this.id,
    String? name,
    String? nameAr,
    String? nameEn,
    String? city,
    String? cityAr,
    String? cityEn,
    required this.rating,
    required this.coursesCount,
    this.description,
    this.address,
    this.latitude,
    this.longitude,
    this.isVerified = false,
    this.logoUrl,
    this.coverImageUrl,
  })  : nameAr = nameAr ?? name ?? '',
        nameEn = nameEn ?? name ?? '',
        cityAr = cityAr ?? city ?? '',
        cityEn = cityEn ?? city ?? '';

  final int id;
  final String nameAr;
  final String nameEn;
  final String cityAr;
  final String cityEn;
  final double rating;
  final int coursesCount;
  final String? description;
  final String? address;
  final double? latitude;
  final double? longitude;
  final bool isVerified;
  final String? logoUrl;
  final String? coverImageUrl;

  String get name => JsonHelpers.pickLocalized(ar: nameAr, en: nameEn);

  String get city => JsonHelpers.pickLocalized(ar: cityAr, en: cityEn);

  String? get resolvedLogoUrl => ApiConfig.resolveMediaUrl(logoUrl);

  String? get resolvedCoverImageUrl => ApiConfig.resolveMediaUrl(coverImageUrl);

  /// للقوائم: لوغو ثم صورة الغلاف.
  String? get resolvedListImageUrl => resolvedLogoUrl ?? resolvedCoverImageUrl;

  InstituteModel copyWith({
    String? name,
    String? nameAr,
    String? nameEn,
    String? city,
    String? cityAr,
    String? cityEn,
    double? rating,
    int? coursesCount,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
    bool? isVerified,
    String? logoUrl,
    String? coverImageUrl,
  }) {
    return InstituteModel(
      id: id,
      nameAr: nameAr ?? name ?? this.nameAr,
      nameEn: nameEn ?? name ?? this.nameEn,
      cityAr: cityAr ?? city ?? this.cityAr,
      cityEn: cityEn ?? city ?? this.cityEn,
      rating: rating ?? this.rating,
      coursesCount: coursesCount ?? this.coursesCount,
      description: description ?? this.description,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isVerified: isVerified ?? this.isVerified,
      logoUrl: logoUrl ?? this.logoUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
    );
  }

  factory InstituteModel.fromJson(Map<String, dynamic> json) {
    final cityObj = json['city'];
    var cityAr = '';
    var cityEn = '';
    if (cityObj is Map<String, dynamic>) {
      final cityNames = JsonHelpers.bilingualText(cityObj);
      cityAr = cityNames.ar;
      cityEn = cityNames.en;
    }

    final names = JsonHelpers.bilingualText(json);
    final descriptionNames = JsonHelpers.bilingualText(json, 'description');

    return InstituteModel(
      id: JsonHelpers.parseInt(json['id']),
      nameAr: names.ar,
      nameEn: names.en,
      cityAr: cityAr,
      cityEn: cityEn,
      rating: JsonHelpers.resolveInstituteRating(json),
      coursesCount: _resolveCoursesCount(json),
      description: JsonHelpers.pickLocalized(ar: descriptionNames.ar, en: descriptionNames.en).isEmpty
          ? null
          : JsonHelpers.pickLocalized(ar: descriptionNames.ar, en: descriptionNames.en),
      address: json['address']?.toString(),
      latitude: JsonHelpers.parseDoubleOrNull(json['latitude'] ?? json['lat']),
      longitude: JsonHelpers.parseDoubleOrNull(json['longitude'] ?? json['lng'] ?? json['lon']),
      isVerified: JsonHelpers.parseBool(json['is_verified']),
      logoUrl: _extractLogoPath(json),
      coverImageUrl: _extractCoverImagePath(json),
    );
  }

  static String? _extractMediaPath(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final resolved = _coerceMediaValue(json[key]);
      if (resolved != null) return resolved;
    }
    return null;
  }

  static String? _coerceMediaValue(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      for (final nestedKey in const [
        'url',
        'original_url',
        'full_url',
        'path',
        'original',
        'src',
      ]) {
        final nested = _coerceMediaValue(map[nestedKey]);
        if (nested != null) return nested;
      }
      return null;
    }
    if (raw is List && raw.isNotEmpty) {
      return _coerceMediaValue(raw.first);
    }
    final value = raw.toString().trim();
    if (value.isEmpty || value == 'null') return null;
    return value;
  }

  static String? _extractLogoPath(Map<String, dynamic> json) {
    return _extractMediaPath(json, const [
      'logo',
      'logo_url',
      'logo_path',
      'brand_logo',
      'icon',
      'avatar',
      'profile_image',
    ]);
  }

  static String? _extractCoverImagePath(Map<String, dynamic> json) {
    return _extractMediaPath(json, const [
      'cover_image',
      'cover_image_url',
      'cover',
      'banner',
      'banner_image',
      'featured_image',
      'image',
      'image_url',
      'photo',
      'thumbnail',
      'picture',
    ]);
  }

  static int _resolveCoursesCount(Map<String, dynamic> json) {
    const keys = [
      'courses_count',
      'coursesCount',
      'active_courses_count',
      'active_courses',
      'total_courses',
      'published_courses_count',
      'courses_total',
    ];
    for (final key in keys) {
      final value = json[key];
      if (value != null) return JsonHelpers.parseInt(value);
    }
    final stats = json['stats'];
    if (stats is Map<String, dynamic>) {
      for (final key in keys) {
        final value = stats[key];
        if (value != null) return JsonHelpers.parseInt(value);
      }
    }
    final meta = json['meta'];
    if (meta is Map<String, dynamic>) {
      for (final key in keys) {
        final value = meta[key];
        if (value != null) return JsonHelpers.parseInt(value);
      }
    }
    final courses = json['courses'];
    if (courses is List && courses.isNotEmpty) return courses.length;

    final count = json['_count'];
    if (count is Map<String, dynamic>) {
      for (final key in ['courses', 'active_courses']) {
        final value = count[key];
        if (value != null) return JsonHelpers.parseInt(value);
      }
    }

    return 0;
  }
}

class NotificationModel {
  NotificationModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    this.isRead = false,
    this.createdAt,
    this.courseId,
    this.enrollmentId,
    this.data,
  });

  final int id;
  final String title;
  final String subtitle;
  final String type;
  final bool isRead;
  final String? createdAt;
  final int? courseId;
  final int? enrollmentId;
  final Map<String, dynamic>? data;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? extra;
    if (json['data'] is Map) {
      extra = Map<String, dynamic>.from(json['data'] as Map);
    }

    return NotificationModel(
      id: JsonHelpers.parseInt(json['id']),
      title: json['title']?.toString() ?? '',
      subtitle: json['body']?.toString() ?? json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'info',
      isRead: JsonHelpers.parseBool(json['is_read']),
      createdAt: json['created_at']?.toString(),
      courseId: JsonHelpers.parseIntOrNull(extra?['course_id'] ?? json['course_id']),
      enrollmentId: JsonHelpers.parseIntOrNull(extra?['enrollment_id'] ?? json['enrollment_id']),
      data: extra,
    );
  }
}

class ReviewModel {
  ReviewModel({
    required this.id,
    required this.rating,
    required this.comment,
    required this.studentName,
    this.studentId,
  });

  final int id;
  final int rating;
  final String comment;
  final String studentName;
  final int? studentId;

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    var studentName = '';
    var studentId = JsonHelpers.parseIntOrNull(json['student_id']);
    if (json['student'] is Map<String, dynamic>) {
      final s = json['student'] as Map<String, dynamic>;
      studentName = '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim();
      studentId ??= JsonHelpers.parseIntOrNull(s['id']);
    }
    return ReviewModel(
      id: JsonHelpers.parseInt(json['id']),
      rating: JsonHelpers.parseInt(json['rating']),
      comment: json['comment']?.toString() ?? '',
      studentName: studentName,
      studentId: studentId,
    );
  }
}

enum CourseSortOption {
  newest,
  ratingHigh,
  priceLow,
  priceHigh,
}

extension CourseSortOptionX on CourseSortOption {
  String get labelKey => switch (this) {
        CourseSortOption.newest => 'sort_newest',
        CourseSortOption.ratingHigh => 'sort_rating_high',
        CourseSortOption.priceLow => 'sort_price_low',
        CourseSortOption.priceHigh => 'sort_price_high',
      };

  void apply(List<CourseModel> courses) {
    switch (this) {
      case CourseSortOption.newest:
        break;
      case CourseSortOption.ratingHigh:
        courses.sort((a, b) => b.rating.compareTo(a.rating));
      case CourseSortOption.priceLow:
        courses.sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));
      case CourseSortOption.priceHigh:
        courses.sort((a, b) => b.effectivePrice.compareTo(a.effectivePrice));
    }
  }
}

List<CourseModel> sortCourses(List<CourseModel> courses, CourseSortOption sort) {
  final list = List<CourseModel>.from(courses);
  sort.apply(list);
  return list;
}

class EnrollmentModel {
  EnrollmentModel({
    required this.id,
    required this.status,
    required this.paymentStatus,
    this.courseId,
    this.courseTitle,
    this.course,
  });

  final int id;
  final String status;
  final String paymentStatus;
  final int? courseId;
  final String? courseTitle;
  final CourseModel? course;

  factory EnrollmentModel.fromJson(Map<String, dynamic> json) {
    var title = '';
    int? courseId = JsonHelpers.parseIntOrNull(json['course_id']);
    CourseModel? courseModel;
    if (json['course'] is Map<String, dynamic>) {
      final course = json['course'] as Map<String, dynamic>;
      title = course['title']?.toString() ?? '';
      courseId ??= JsonHelpers.parseIntOrNull(course['id']);
      courseModel = CourseModel.fromJson(course);
    }
    return EnrollmentModel(
      id: JsonHelpers.parseInt(json['id']),
      status: json['status']?.toString() ?? '',
      paymentStatus: json['payment_status']?.toString() ?? '',
      courseId: courseId,
      courseTitle: title,
      course: courseModel,
    );
  }

  bool get canCancel => status.toLowerCase() == 'pending';

  bool get allowsReview => status.toLowerCase() == 'completed';

  /// يُحسب ضمن سعة الدورة (مؤكّد/معتمد/مكتمل — بدون المعلق).
  static bool countsTowardCapacity(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'confirmed':
      case 'completed':
        return true;
      default:
        return false;
    }
  }

  bool get countsTowardCourseCapacity => countsTowardCapacity(status);

  String get statusLabel {
    switch (status) {
      case 'approved':
      case 'confirmed':
        return 'tab_confirmed'.tr;
      case 'completed':
        return 'tab_done'.tr;
      case 'pending':
        return 'tab_pending'.tr;
      case 'rejected':
        return 'tab_rejected'.tr;
      case 'cancelled':
        return 'tab_cancelled'.tr;
      default:
        return status;
    }
  }
}
