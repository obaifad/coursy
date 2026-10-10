part of '../app_models.dart';

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
    this.reviewsCount,
    this.description,
    this.address,
    this.latitude,
    this.longitude,
    this.isVerified = false,
    this.logoUrl,
    this.coverImageUrl,
    this.cityId,
    this.phone,
    this.whatsapp,
    this.website,
    this.facebook,
    this.instagram,
  }) : nameAr = nameAr ?? name ?? '',
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

  /// عدد التقييمات إن أرسله الخادم (`reviews_count`) — null = غير معروف فلا يُعرض.
  final int? reviewsCount;
  final String? description;
  final String? address;
  final double? latitude;
  final double? longitude;
  final bool isVerified;
  final String? logoUrl;
  final String? coverImageUrl;
  final int? cityId;

  // وسائل تواصل المعهد كما يرسلها الخادم (قد تكون فارغة).
  final String? phone;
  final String? whatsapp;
  final String? website;
  final String? facebook;
  final String? instagram;

  bool get hasContact => [phone, whatsapp, website, facebook, instagram].any((v) => v != null);

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
    int? reviewsCount,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
    bool? isVerified,
    String? logoUrl,
    String? coverImageUrl,
    String? phone,
    String? whatsapp,
    String? website,
    String? facebook,
    String? instagram,
  }) {
    return InstituteModel(
      id: id,
      nameAr: nameAr ?? name ?? this.nameAr,
      nameEn: nameEn ?? name ?? this.nameEn,
      cityAr: cityAr ?? city ?? this.cityAr,
      cityEn: cityEn ?? city ?? this.cityEn,
      rating: rating ?? this.rating,
      coursesCount: coursesCount ?? this.coursesCount,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      description: description ?? this.description,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isVerified: isVerified ?? this.isVerified,
      logoUrl: logoUrl ?? this.logoUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      cityId: cityId,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      website: website ?? this.website,
      facebook: facebook ?? this.facebook,
      instagram: instagram ?? this.instagram,
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
    } else if (cityObj is String && cityObj.trim().isNotEmpty) {
      cityAr = cityObj.trim();
      cityEn = cityObj.trim();
    } else {
      // بعض استجابات القوائم تُرجع اسم المدينة كحقل مسطّح.
      final flatAr = (json['city_name_ar'] ?? json['city_ar'] ?? json['city_name'])?.toString().trim() ?? '';
      final flatEn = (json['city_name_en'] ?? json['city_en'] ?? json['city_name'])?.toString().trim() ?? '';
      cityAr = flatAr;
      cityEn = flatEn.isEmpty ? flatAr : flatEn;
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
      reviewsCount: JsonHelpers.parseIntOrNull(json['reviews_count'] ?? json['ratings_count']),
      description: JsonHelpers.pickLocalized(ar: descriptionNames.ar, en: descriptionNames.en).isEmpty
          ? null
          : JsonHelpers.pickLocalized(ar: descriptionNames.ar, en: descriptionNames.en),
      address: json['address']?.toString(),
      latitude: JsonHelpers.parseDoubleOrNull(json['latitude'] ?? json['lat']),
      longitude: JsonHelpers.parseDoubleOrNull(json['longitude'] ?? json['lng'] ?? json['lon']),
      isVerified: JsonHelpers.parseBool(json['is_verified']),
      logoUrl: _extractLogoPath(json),
      coverImageUrl: _extractCoverImagePath(json),
      cityId:
          JsonHelpers.parseIntOrNull(json['city_id']) ??
          (cityObj is Map ? JsonHelpers.parseIntOrNull(cityObj['id']) : null),
      phone: _contact(json['phone']),
      whatsapp: _contact(json['whatsapp']),
      website: _contact(json['website']),
      facebook: _contact(json['facebook']),
      instagram: _contact(json['instagram']),
    );
  }

  static String? _contact(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
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
      for (final nestedKey in const ['url', 'original_url', 'full_url', 'path', 'original', 'src']) {
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
