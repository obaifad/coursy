part of '../app_models.dart';

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
    return source
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
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
    if (probe.contains('project') ||
        probe.contains('management') ||
        probe.contains('business') ||
        probe.contains('أعمال') ||
        probe.contains('مشاريع')) {
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
  }) : nameAr = nameAr ?? name ?? '',
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

  String get subjectKey =>
      InstructorSubjectModel.keyFromParts(en: specializationEn, ar: specializationAr, localized: specialization);

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
