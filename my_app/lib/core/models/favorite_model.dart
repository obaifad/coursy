import 'json_helpers.dart';

enum FavoriteTargetType { course, institute, instructor }

class FavoriteModel {
  FavoriteModel({
    required this.id,
    required this.type,
    required this.targetId,
  });

  final int id;
  final FavoriteTargetType type;
  final int targetId;

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    var courseId = JsonHelpers.parseIntOrNull(json['course_id']);
    var instituteId = JsonHelpers.parseIntOrNull(json['institute_id']);
    var instructorId = JsonHelpers.parseIntOrNull(json['instructor_id']);

    if (json['course'] is Map) {
      final course = json['course'] as Map<String, dynamic>;
      courseId ??= JsonHelpers.parseIntOrNull(course['id']);
    }
    if (json['institute'] is Map) {
      final institute = json['institute'] as Map<String, dynamic>;
      instituteId ??= JsonHelpers.parseIntOrNull(institute['id']);
    }
    if (json['instructor'] is Map) {
      final instructor = json['instructor'] as Map<String, dynamic>;
      instructorId ??= JsonHelpers.parseIntOrNull(instructor['id']);
    }

    final typeStr = json['favoritable_type']?.toString().toLowerCase() ?? '';
    if (courseId == null && typeStr.contains('course')) {
      courseId = JsonHelpers.parseIntOrNull(json['favoritable_id']);
    }
    if (instituteId == null && typeStr.contains('institute')) {
      instituteId = JsonHelpers.parseIntOrNull(json['favoritable_id']);
    }
    if (instructorId == null && typeStr.contains('instructor')) {
      instructorId = JsonHelpers.parseIntOrNull(json['favoritable_id']);
    }

    FavoriteTargetType type;
    int targetId;
    if (courseId != null && courseId > 0) {
      type = FavoriteTargetType.course;
      targetId = courseId;
    } else if (instituteId != null && instituteId > 0) {
      type = FavoriteTargetType.institute;
      targetId = instituteId;
    } else if (instructorId != null && instructorId > 0) {
      type = FavoriteTargetType.instructor;
      targetId = instructorId;
    } else {
      type = FavoriteTargetType.course;
      targetId = JsonHelpers.parseInt(json['favoritable_id'] ?? json['id']);
    }

    return FavoriteModel(
      id: JsonHelpers.parseInt(json['id']),
      type: type,
      targetId: targetId,
    );
  }
}
