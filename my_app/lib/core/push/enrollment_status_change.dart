/// تغيّر في حالة تسجيل يستحق إشعاراً للطالب — مشترك بين التطبيق والفحص الخلفي (isolate منفصل)،
/// فلا يعتمد على GetX ولا على الترجمات.
enum EnrollmentStatusChange {
  approved(key: 'approved', type: 'enrollment_approved', idOffset: 0),
  rejected(key: 'rejected', type: 'enrollment_rejected', idOffset: 100000),

  /// الإلغاء حالة مستقلة عن الرفض: الطالب أو المعهد ألغى الحجز، ولا يصح أن يظهر «تم رفض التسجيل».
  cancelled(key: 'cancelled', type: 'enrollment_cancelled', idOffset: 200000);

  const EnrollmentStatusChange({required this.key, required this.type, required this.idOffset});

  /// بادئة مفتاح «تم الإشعار» في EnrollmentStatusStore (مثل `approved:12`).
  final String key;

  /// نوع الإشعار كما يرسله الخادم — وهو أيضاً بادئة مفاتيح الترجمة (`<type>_title`، `<type>_body`…).
  final String type;

  /// يُضاف لمعرّف التسجيل كي لا يستبدل إشعارُ حالةٍ إشعارَ حالةٍ أخرى لنفس التسجيل.
  final int idOffset;

  String deliveredKey(int enrollmentId) => '$key:$enrollmentId';

  int notificationId(int enrollmentId) => enrollmentId + idOffset;

  String get titleKey => '${type}_title';
  String get bodyKey => '${type}_body';
  String get genericBodyKey => '${type}_body_generic';

  /// التغيّر الذي يستحق إشعاراً: فقط من «قيد المراجعة» إلى حالة نهائية.
  static EnrollmentStatusChange? detect(String? previous, String next) {
    if (previous?.toLowerCase() != 'pending') return null;
    return fromStatus(next);
  }

  static EnrollmentStatusChange? fromStatus(String status) {
    switch (status.trim().toLowerCase()) {
      case 'approved':
      case 'confirmed':
        return approved;
      case 'rejected':
        return rejected;
      case 'cancelled':
      case 'canceled':
        return cancelled;
      default:
        return null;
    }
  }

  /// من نوع إشعار الخادم (`enrollment_approved`…) — لتسجيل أن FCM أوصل الإشعار فلا نكرره محلياً.
  static EnrollmentStatusChange? fromNotificationType(String? type) {
    final normalized = type?.trim().toLowerCase() ?? '';
    for (final change in values) {
      if (normalized == change.type) return change;
    }
    return null;
  }
}
