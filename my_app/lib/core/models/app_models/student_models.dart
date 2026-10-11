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

  /// بيانات الوجهة كما في إشعار FCM (`{"course_id":"41","enrollment_id":"7"}`) — null للإشعارات القديمة.
  final Map<String, dynamic>? data;

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
    id: id,
    title: title,
    subtitle: subtitle,
    type: type,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
    courseId: courseId,
    enrollmentId: enrollmentId,
    data: data,
  );

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
    this.studentImageUrl,
    this.courseTitle,
  });

  final int id;
  final int rating;
  final String comment;
  final String studentName;
  final int? studentId;

  /// صورة صاحب التقييم (`student.profile_image`) — مسار نسبي أو رابط.
  final String? studentImageUrl;

  /// اسم الدورة المقيَّمة (تقييمات المدرّس تشمل كل دوراته).
  final String? courseTitle;

  String? get resolvedStudentImageUrl => ApiConfig.resolveMediaUrl(studentImageUrl);

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    var studentName = '';
    String? studentImage;
    var studentId = JsonHelpers.parseIntOrNull(json['student_id']);
    if (json['student'] is Map<String, dynamic>) {
      final s = json['student'] as Map<String, dynamic>;
      // الخادم يرسل اسماً مختصراً جاهزاً في `name` (مثل «Sara H.»)؛ first/last احتياط للنسخ القديمة.
      final short = s['name']?.toString().trim() ?? '';
      studentName = short.isNotEmpty ? short : '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim();
      final img = (s['profile_image'] ?? s['photo'])?.toString().trim();
      studentImage = img == null || img.isEmpty ? null : img;
      studentId ??= JsonHelpers.parseIntOrNull(s['id']);
    }
    String? courseTitle;
    final course = json['course'];
    if (course is Map<String, dynamic>) {
      final names = JsonHelpers.bilingualText(course, 'title');
      final t = JsonHelpers.pickLocalized(ar: names.ar, en: names.en).trim();
      courseTitle = t.isEmpty ? course['title']?.toString() : t;
    }
    return ReviewModel(
      id: JsonHelpers.parseInt(json['id']),
      rating: JsonHelpers.parseInt(json['rating']),
      comment: json['comment']?.toString() ?? '',
      studentName: studentName,
      studentId: studentId,
      studentImageUrl: studentImage,
      courseTitle: courseTitle,
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
    this.institute,
  });

  final int id;
  final String status;
  final String paymentStatus;
  final int? courseId;
  final String? courseTitle;
  final CourseModel? course;

  /// معهد الدورة (`course.institute`) — منه `accepts_shamcash` (هل يمكن الدفع داخل التطبيق).
  final InstituteModel? institute;

  factory EnrollmentModel.fromJson(Map<String, dynamic> json) {
    var title = '';
    int? courseId = JsonHelpers.parseIntOrNull(json['course_id']);
    CourseModel? courseModel;
    InstituteModel? institute;
    if (json['course'] is Map<String, dynamic>) {
      final course = json['course'] as Map<String, dynamic>;
      title = course['title']?.toString() ?? '';
      courseId ??= JsonHelpers.parseIntOrNull(course['id']);
      courseModel = CourseModel.fromJson(course);
      if (course['institute'] is Map) {
        institute = InstituteModel.fromJson(Map<String, dynamic>.from(course['institute'] as Map));
      }
    }
    return EnrollmentModel(
      id: JsonHelpers.parseInt(json['id']),
      status: json['status']?.toString() ?? '',
      paymentStatus: json['payment_status']?.toString() ?? '',
      courseId: courseId,
      courseTitle: title,
      course: courseModel,
      institute: institute,
    );
  }

  bool get canCancel => status.toLowerCase() == 'pending';

  /// الدفع الإلكتروني مطلوب فقط للدورات ذات الدفعة المقدّمة، ولا يُقبل لتسجيل مرفوض أو ملغى أو مدفوع بالكامل.
  bool get canPay {
    if (course?.requiresAdvancePayment != true) return false;
    if (paymentStatus.toLowerCase() == 'paid') return false;
    switch (status.toLowerCase()) {
      case 'pending':
      case 'approved':
      case 'confirmed':
        return true;
      default:
        return false;
    }
  }

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
