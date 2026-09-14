import 'dart:convert';

/// لقطة محلية للمعلومات الأكاديمية — تُستخدم حتى يعيد الـ API نفس البيانات.
class AcademicProfileCache {
  const AcademicProfileCache({
    this.educationLevel,
    this.universityId,
    this.specializationId,
    this.preferredCategoryIds = const [],
  });

  final String? educationLevel;
  final int? universityId;
  final int? specializationId;
  final List<int> preferredCategoryIds;

  bool get isEmpty =>
      (educationLevel == null || educationLevel!.isEmpty) &&
      universityId == null &&
      specializationId == null &&
      preferredCategoryIds.isEmpty;

  Map<String, dynamic> toJson() => {
        if (educationLevel != null && educationLevel!.isNotEmpty) 'education_level': educationLevel,
        if (universityId != null) 'university_id': universityId,
        if (specializationId != null) 'specialization_id': specializationId,
        if (preferredCategoryIds.isNotEmpty) 'preferred_tags': preferredCategoryIds,
      };

  factory AcademicProfileCache.fromJson(Map<String, dynamic> json) {
    return AcademicProfileCache(
      educationLevel: json['education_level']?.toString(),
      universityId: int.tryParse(json['university_id']?.toString() ?? ''),
      specializationId: int.tryParse(json['specialization_id']?.toString() ?? ''),
      preferredCategoryIds: _parseIds(
        json['preferred_tags'] ??
            json['preferred_tag_ids'] ??
            json['preferred_categories'] ??
            json['preferred_category_ids'],
      ),
    );
  }

  static List<int> _parseIds(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .map((e) => e is Map
            ? int.tryParse('${e['id'] ?? e['tag_id'] ?? e['category_id']}')
            : int.tryParse('$e'))
        .whereType<int>()
        .where((id) => id > 0)
        .toList();
  }

  static AcademicProfileCache? decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is! Map) return null;
      return AcademicProfileCache.fromJson(Map<String, dynamic>.from(map));
    } catch (_) {
      return null;
    }
  }

  String encode() => jsonEncode(toJson());
}
