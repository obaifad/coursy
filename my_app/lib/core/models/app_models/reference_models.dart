part of '../app_models.dart';

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
  SpecializationModel({required this.id, required this.type, required this.name, this.nameEn, this.nameAr});

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
    return NamedEntity(id: JsonHelpers.parseInt(json['id']), nameAr: names.ar, nameEn: names.en);
  }
}

class CategoryModel {
  CategoryModel({required this.id, required this.nameAr, required this.nameEn, this.icon, this.coursesCount = 0});

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
