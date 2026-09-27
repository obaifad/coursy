part of '../app_models.dart';

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
