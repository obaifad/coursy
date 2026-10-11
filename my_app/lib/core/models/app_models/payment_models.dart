part of '../app_models.dart';

/// بيانات حساب شام كاش الخاص بالمعهد (لا تُخزَّن — تُجلب في كل مرة تُفتح فيها شاشة الدفع).
class ShamCashInfo {
  const ShamCashInfo({this.available = false, this.accountName, this.address, this.qrPayload, this.reason});

  final bool available;
  final String? accountName;
  final String? address;
  final String? qrPayload;

  /// سبب عدم الإتاحة إن أرسله الخادم — `online_course`: الدورات الأونلاين تُدفع للمعهد مباشرة
  /// خارج التطبيق (سياسة Google Play للدفع داخل التطبيقات).
  final String? reason;

  bool get isOnlineCourse => reason == 'online_course';

  factory ShamCashInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ShamCashInfo();
    String? text(dynamic v) {
      final s = v?.toString().trim();
      return s == null || s.isEmpty ? null : s;
    }

    return ShamCashInfo(
      available: JsonHelpers.parseBool(json['available']),
      accountName: text(json['account_name']),
      address: text(json['address']),
      qrPayload: text(json['qr_payload']),
      reason: text(json['reason']),
    );
  }

  /// الخيار يُعرض فقط عندما يكون متاحاً ويوجد عنوان فعلي للإرسال إليه.
  bool get canPay => available && address != null;
}

/// تحويل مقبول سُجّل على التسجيل.
class PaymentRecordModel {
  const PaymentRecordModel({
    required this.id,
    required this.transactionId,
    required this.amount,
    required this.currency,
    this.senderName,
    this.occurredAt,
  });

  final int id;
  final String transactionId;
  final double amount;
  final String currency;
  final String? senderName;
  final DateTime? occurredAt;

  factory PaymentRecordModel.fromJson(Map<String, dynamic> json) {
    final sender = json['sender_name']?.toString().trim();
    return PaymentRecordModel(
      id: JsonHelpers.parseInt(json['id']),
      transactionId: json['transaction_id']?.toString() ?? '',
      amount: JsonHelpers.parseDouble(json['amount']),
      currency: json['currency']?.toString() ?? 'SYP',
      senderName: sender == null || sender.isEmpty ? null : sender,
      occurredAt: DateTime.tryParse(json['occurred_at']?.toString() ?? '')?.toLocal(),
    );
  }
}

/// ما يدين به الطالب وأين يرسله — من `GET /student/enrollments/{id}/payment`.
class PaymentDetailsModel {
  const PaymentDetailsModel({
    required this.enrollmentId,
    required this.paymentStatus,
    required this.currency,
    required this.amountDue,
    required this.advanceAmount,
    required this.amountPaid,
    required this.amountRemaining,
    required this.advanceRemaining,
    required this.shamcash,
    this.payments = const [],
  });

  final int enrollmentId;
  final String paymentStatus;
  final String currency;
  final double amountDue;
  final double advanceAmount;
  final double amountPaid;
  final double amountRemaining;
  final double advanceRemaining;
  final ShamCashInfo shamcash;
  final List<PaymentRecordModel> payments;

  bool get isPaid => paymentStatus == 'paid';

  bool get isPartial => paymentStatus == 'partial';

  /// المبلغ المطلوب إرساله الآن: المتبقي من الدفعة المقدمة، وإلا كامل المتبقي.
  double get amountToSendNow => advanceRemaining > 0 ? advanceRemaining : amountRemaining;

  /// دفعة مقدّمة لم تُسدَّد بعد.
  bool get hasPendingAdvance => advanceRemaining > 0;

  /// ما سيبقى للدفع في المعهد بعد تسديد الدفعة المقدّمة (الإجمالي المتبقي − المطلوب الآن).
  double get remainingAtInstitute {
    final value = amountRemaining - advanceRemaining;
    return value > 0 ? value : 0;
  }

  /// الدورة تتطلب دفعة مقدّمة (حسب الخادم) لكن الدفع الإلكتروني غير مفعّل للمعهد حالياً.
  bool get advanceRequiredButUnavailable => advanceAmount > 0 && !shamcash.canPay && !isPaid;

  factory PaymentDetailsModel.fromJson(Map<String, dynamic> json) {
    final shamcash = json['shamcash'];
    final payments = json['payments'];
    return PaymentDetailsModel(
      enrollmentId: JsonHelpers.parseInt(json['enrollment_id']),
      paymentStatus: json['payment_status']?.toString() ?? 'unpaid',
      currency: json['currency']?.toString() ?? 'SYP',
      amountDue: JsonHelpers.parseDouble(json['amount_due']),
      advanceAmount: JsonHelpers.parseDouble(json['advance_amount']),
      amountPaid: JsonHelpers.parseDouble(json['amount_paid']),
      amountRemaining: JsonHelpers.parseDouble(json['amount_remaining']),
      advanceRemaining: JsonHelpers.parseDouble(json['advance_remaining']),
      shamcash: ShamCashInfo.fromJson(shamcash is Map ? Map<String, dynamic>.from(shamcash) : null),
      payments: payments is List
          ? [
              for (final p in payments)
                if (p is Map) PaymentRecordModel.fromJson(Map<String, dynamic>.from(p)),
            ]
          : const [],
    );
  }
}

/// نتيجة إرسال رقم عملية ناجحة (201).
class ShamCashSubmitResult {
  const ShamCashSubmitResult({required this.payment, this.enrollment});

  final PaymentRecordModel payment;
  final EnrollmentModel? enrollment;

  factory ShamCashSubmitResult.fromJson(Map<String, dynamic> json) {
    final payment = json['payment'];
    final enrollment = json['enrollment'];
    return ShamCashSubmitResult(
      payment: PaymentRecordModel.fromJson(payment is Map ? Map<String, dynamic>.from(payment) : const {}),
      enrollment: enrollment is Map ? EnrollmentModel.fromJson(Map<String, dynamic>.from(enrollment)) : null,
    );
  }
}
