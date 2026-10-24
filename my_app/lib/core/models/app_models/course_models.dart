part of '../app_models.dart';

class ScheduleModel {
  ScheduleModel({required this.id, required this.dayOfWeek, required this.startTime, required this.endTime});

  final int id;
  final String dayOfWeek;
  final String startTime;
  final String endTime;

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: JsonHelpers.parseInt(json['id']),
      dayOfWeek: json['day_of_week']?.toString() ?? json['day']?.toString() ?? json['weekday']?.toString() ?? '',
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

class CourseModel {
  CourseModel({
    required this.id,
    String? title,
    String? titleAr,
    String? titleEn,
    String? institute,
    String? instituteAr,
    String? instituteEn,
    required this.rating,
    this.reviewsCount,
    this.levelCode,
    this.instituteId,
    this.categoryId,
    this.description,
    this.requirements,
    this.studentsCount,
    this.confirmedStudentsCount,
    this.maxStudents,
    this.durationHours,
    this.sessionsCount,
    this.studyTypeCode,
    this.language,
    this.startDate,
    this.endDate,
    this.registrationDeadline,
    this.certificateAvailable = false,
    this.requiresAdvancePayment = false,
    String? instituteCity,
    String? instituteCityAr,
    String? instituteCityEn,
    this.instituteAddress,
    this.institutePhone,
    this.instituteWhatsapp,
    this.instituteWebsite,
    this.schedules = const [],
    this.instructor,
    this.categoryName,
    this.isFeatured = false,
    this.isFree = false,
    this.rawPrice,
    this.discountPrice,
    this.imageUrl,
  }) : titleAr = titleAr ?? title ?? '',
       titleEn = titleEn ?? title ?? '',
       instituteAr = instituteAr ?? institute ?? '',
       instituteEn = instituteEn ?? institute ?? '',
       instituteCityAr = instituteCityAr ?? instituteCity ?? '',
       instituteCityEn = instituteCityEn ?? instituteCity ?? '';

  final int id;
  final String titleAr;
  final String titleEn;
  final String instituteAr;
  final String instituteEn;
  final double rating;

  /// عدد التقييمات إن أرسله الخادم (`reviews_count` أو قائمة `reviews`) — null = غير معروف فلا يُعرض.
  final int? reviewsCount;

  /// تقييم يستحق العرض: من تقييمات فعلية (لا نجمة «0.0» لدورة لم يقيّمها أحد).
  bool get hasRating => rating > 0 && (reviewsCount == null || reviewsCount! > 0);

  /// دورة أونلاين: لا دفع داخل التطبيق (سياسة Google Play)، تُدفع للمعهد مباشرة.
  bool get isOnline => studyTypeCode?.trim().toLowerCase() == 'online';

  /// القيمة الخام من الـ API (beginner / intermediate / advanced) — النص المترجم في [level].
  final String? levelCode;
  final int? instituteId;
  final int? categoryId;
  final String? description;
  final String? requirements;
  final int? studentsCount;
  final int? confirmedStudentsCount;
  final int? maxStudents;
  final int? durationHours;
  final int? sessionsCount;

  /// القيمة الخام من الـ API (online / offline / hybrid) — النص المترجم في [studyType].
  final String? studyTypeCode;
  final String? language;
  final String? startDate;
  final String? endDate;
  final String? registrationDeadline;
  final bool certificateAvailable;
  final bool requiresAdvancePayment;

  /// المدينة بالنسختين — تُختار عند العرض بلغة الواجهة الحالية (مثل العنوان واسم المعهد).
  final String instituteCityAr;
  final String instituteCityEn;

  String? get instituteCity {
    final city = JsonHelpers.pickLocalized(ar: instituteCityAr, en: instituteCityEn);
    return city.isEmpty ? null : city;
  }

  final String? instituteAddress;
  final String? institutePhone;
  final String? instituteWhatsapp;
  final String? instituteWebsite;
  final List<ScheduleModel> schedules;
  final InstructorModel? instructor;
  final String? categoryName;
  final bool isFeatured;

  /// دورة مجانية فعلاً (من لوحة التحكم) — تختلف عن سعر 0 «لم يُحدد بعد».
  final bool isFree;
  final String? rawPrice;
  final String? discountPrice;
  final String? imageUrl;

  String get title => JsonHelpers.pickLocalized(ar: titleAr, en: titleEn);

  String get institute => JsonHelpers.pickLocalized(ar: instituteAr, en: instituteEn);

  // النصوص المعروضة تُحسب عند القراءة بلغة الواجهة الحالية — لا تُخزَّن مترجمة داخل النموذج
  // حتى لا تبقى بلغة قديمة بعد تغيير اللغة.
  String get price => isFree ? 'price_free'.tr : JsonHelpers.formatSyrianPrice(rawPrice, discount: discountPrice);

  String get duration => JsonHelpers.durationLabel(hours: durationHours, sessions: sessionsCount);

  String get level => JsonHelpers.levelLabel(levelCode);

  String? get studyType {
    final code = studyTypeCode?.trim();
    if (code == null || code.isEmpty) return null;
    return JsonHelpers.studyTypeLabel(code);
  }

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
    if (isFree) return false;
    final discount = JsonHelpers.parseDouble(discountPrice);
    return discount > 0;
  }

  /// نسبة الخصم من السعر الأصلي (مثلاً 20)، أو null إن لم يوجد خصم فعلي.
  int? get discountPercent {
    if (!hasDiscount) return null;
    final original = JsonHelpers.parseDouble(rawPrice);
    final discounted = JsonHelpers.parseDouble(discountPrice);
    if (original <= 0 || discounted >= original) return null;
    final percent = ((original - discounted) / original * 100).round();
    return percent > 0 ? percent : null;
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

  /// المدة بالأسابيع من تاريخَي البدء والانتهاء (مقرّبة للأعلى)؛ null إن غاب أحدهما.
  int? get durationWeeks {
    final start = JsonHelpers.tryParseDateOnly(startDate);
    final end = JsonHelpers.tryParseDateOnly(endDate);
    if (start == null || end == null || !end.isAfter(start)) return null;
    return (end.difference(start).inDays / 7).ceil();
  }

  /// موعد البدء كـ «22 تشرين الأول» (null إن لم يُرسل الخادم تاريخاً صالحاً).
  String? get startDayMonth => JsonHelpers.formatDayMonth(startDate);

  String get seatsLabel {
    final current = enrolledCountForCapacity;
    final max = maxStudents;
    if (max != null && max > 0) {
      return 'course_seats'.trParams({'current': '$current', 'max': '$max'});
    }
    return pluralTr('students_count', current);
  }

  static int? _parseReviewsCount(Map<String, dynamic> json) {
    for (final key in ['reviews_count', 'ratings_count', 'review_count']) {
      final value = JsonHelpers.parseIntOrNull(json[key]);
      if (value != null) return value;
    }
    final reviews = json['reviews'];
    return reviews is List ? reviews.length : null;
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
    String? instituteCityAr,
    String? instituteCityEn,
    String? instituteAr,
    String? instituteEn,
    String? instituteAddress,
    String? institutePhone,
    String? instituteWhatsapp,
    String? instituteWebsite,
    double? rating,
    int? reviewsCount,
    int? studentsCount,
    int? confirmedStudentsCount,
  }) {
    return CourseModel(
      id: id,
      // النسختان العربية والإنجليزية معاً — تمرير `title` المترجم كان يثبّت لغة واحدة.
      titleAr: titleAr,
      titleEn: titleEn,
      instituteAr: instituteAr ?? this.instituteAr,
      instituteEn: instituteEn ?? this.instituteEn,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      levelCode: levelCode,
      instituteId: instituteId,
      categoryId: categoryId,
      description: description ?? this.description,
      requirements: requirements ?? this.requirements,
      studentsCount: studentsCount ?? this.studentsCount,
      confirmedStudentsCount: confirmedStudentsCount ?? this.confirmedStudentsCount,
      maxStudents: maxStudents,
      durationHours: durationHours,
      sessionsCount: sessionsCount,
      studyTypeCode: studyTypeCode,
      language: language,
      startDate: startDate,
      endDate: endDate,
      registrationDeadline: registrationDeadline,
      certificateAvailable: certificateAvailable,
      requiresAdvancePayment: requiresAdvancePayment,
      instituteCityAr: instituteCityAr ?? this.instituteCityAr,
      instituteCityEn: instituteCityEn ?? this.instituteCityEn,
      instituteAddress: instituteAddress ?? this.instituteAddress,
      institutePhone: institutePhone ?? this.institutePhone,
      instituteWhatsapp: instituteWhatsapp ?? this.instituteWhatsapp,
      instituteWebsite: instituteWebsite ?? this.instituteWebsite,
      schedules: schedules ?? this.schedules,
      instructor: instructor ?? this.instructor,
      categoryName: categoryName ?? this.categoryName,
      isFeatured: isFeatured,
      isFree: isFree,
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
    var instituteCityAr = '';
    var instituteCityEn = '';
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
      instituteAddress = instituteObj['address']?.toString() ?? JsonHelpers.localizedText(instituteObj, 'address');
      institutePhone = instituteObj['phone']?.toString();
      instituteWhatsapp = instituteObj['whatsapp']?.toString();
      instituteWebsite = instituteObj['website']?.toString();
      final cityObj = instituteObj['city'];
      if (cityObj is Map<String, dynamic>) {
        final cityNames = JsonHelpers.bilingualText(cityObj);
        instituteCityAr = cityNames.ar;
        instituteCityEn = cityNames.en;
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
      rawPrice: json['price']?.toString(),
      discountPrice: json['discount_price']?.toString(),
      imageUrl: _extractCourseImagePath(json),
      // الخادم يرسل تقييم الدورة نفسها مع عدد تقييماتها: دورة بلا تقييمات تبقى بلا تقييم،
      // ولا نستعير تقييم المعهد إلا من خادم قديم لا يرسل `reviews_count`.
      rating: json.containsKey('reviews_count')
          ? JsonHelpers.parseDouble(json['average_rating'])
          : JsonHelpers.resolveCourseRating(json, fallback: instituteRating),
      reviewsCount: _parseReviewsCount(json),
      levelCode: levelRaw,
      description: description.isNotEmpty ? description : json['description']?.toString(),
      requirements: requirements.isNotEmpty ? requirements : json['requirements']?.toString(),
      studentsCount: JsonHelpers.parseIntOrNull(json['current_students']),
      confirmedStudentsCount: _parseConfirmedStudents(json),
      maxStudents: JsonHelpers.parseIntOrNull(json['max_students']),
      durationHours: hours,
      sessionsCount: sessions,
      studyTypeCode: json['study_type']?.toString(),
      language: json['language']?.toString(),
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
      registrationDeadline: json['registration_deadline']?.toString(),
      certificateAvailable: JsonHelpers.parseBool(json['certificate_available']),
      requiresAdvancePayment: JsonHelpers.parseBool(json['requires_advance_payment']),
      instituteCityAr: instituteCityAr,
      instituteCityEn: instituteCityEn,
      instituteAddress: instituteAddress,
      institutePhone: institutePhone,
      instituteWhatsapp: instituteWhatsapp,
      instituteWebsite: instituteWebsite,
      schedules: schedulesList,
      instructor: instructor,
      categoryName: categoryName,
      isFeatured: JsonHelpers.parseBool(json['is_featured']),
      isFree: JsonHelpers.parseBool(json['is_free']),
    );
  }
}

enum CourseSortOption { newest, ratingHigh, priceLow, priceHigh }

extension CourseSortOptionX on CourseSortOption {
  String get labelKey => switch (this) {
    CourseSortOption.newest => 'sort_newest',
    CourseSortOption.ratingHigh => 'sort_rating_high',
    CourseSortOption.priceLow => 'sort_price_low',
    CourseSortOption.priceHigh => 'sort_price_high',
  };

  /// قيمة `sort` في الـ API (الترتيب على الخادم). null = الافتراضي (الأحدث) فلا يُرسل.
  String? get apiValue => switch (this) {
    CourseSortOption.newest => null,
    CourseSortOption.ratingHigh => 'rating',
    CourseSortOption.priceLow => 'price_asc',
    CourseSortOption.priceHigh => 'price_desc',
  };
}
