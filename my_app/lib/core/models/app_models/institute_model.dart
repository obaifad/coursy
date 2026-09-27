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
    this.description,
    this.address,
    this.latitude,
    this.longitude,
    this.isVerified = false,
    this.logoUrl,
    this.coverImageUrl,
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
