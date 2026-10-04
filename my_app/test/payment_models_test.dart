import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/models/app_models.dart';

void main() {
  test('payment details parse numbers, shamcash info and payments', () {
    final d = PaymentDetailsModel.fromJson({
      'enrollment_id': 42,
      'payment_status': 'partial',
      'currency': 'SYP',
      'amount_due': 100000,
      'advance_amount': 30000.5,
      'amount_paid': '30000.00',
      'amount_remaining': 70000,
      'advance_remaining': 0,
      'shamcash': {
        'available': true,
        'account_name': 'Masar Institute',
        'address': 'SC-ADDRESS-123',
        'qr_payload': 'shamcash://pay/SC-ADDRESS-123',
      },
      'payments': [
        {
          'id': 7,
          'transaction_id': '555',
          'amount': '30000.00',
          'currency': 'SYP',
          'occurred_at': '2026-10-03T06:15:00.000000Z',
        },
      ],
    });
    expect(d.enrollmentId, 42);
    expect(d.isPartial, isTrue);
    expect(d.isPaid, isFalse);
    expect(d.advanceAmount, 30000.5);
    expect(d.amountPaid, 30000);
    expect(d.shamcash.canPay, isTrue);
    expect(d.shamcash.accountName, 'Masar Institute');
    expect(d.payments.single.amount, 30000);
    expect(d.payments.single.occurredAt, isNotNull);
  });

  test('amount to send now is the remaining advance, else the full remaining balance', () {
    PaymentDetailsModel make(double advanceRemaining, double remaining) => PaymentDetailsModel.fromJson({
      'enrollment_id': 1,
      'advance_remaining': advanceRemaining,
      'amount_remaining': remaining,
    });
    expect(make(30000, 100000).amountToSendNow, 30000);
    expect(make(0, 70000).amountToSendNow, 70000);
  });

  test('shamcash unavailable has no keys and cannot pay', () {
    final d = PaymentDetailsModel.fromJson({
      'enrollment_id': 1,
      'payment_status': 'unpaid',
      'shamcash': {'available': false},
    });
    expect(d.shamcash.available, isFalse);
    expect(d.shamcash.canPay, isFalse);
    expect(d.payments, isEmpty);
  });

  test('available without address cannot pay (never show an empty destination)', () {
    expect(ShamCashInfo.fromJson({'available': true, 'address': null}).canPay, isFalse);
  });

  test('submit result carries the updated enrollment', () {
    final r = ShamCashSubmitResult.fromJson({
      'payment': {'id': 7, 'transaction_id': '555', 'amount': '30000.00', 'currency': 'SYP'},
      'enrollment': {
        'id': 42,
        'status': 'pending',
        'payment_status': 'partial',
        'course': {'id': 9, 'title': 'x', 'requires_advance_payment': true},
      },
    });
    expect(r.payment.amount, 30000);
    expect(r.enrollment?.paymentStatus, 'partial');
    expect(r.enrollment?.canPay, isTrue);
  });

  test('enrollment can be paid only while pending/approved, not fully paid, and when advance payment is required', () {
    EnrollmentModel e(String status, String pay, bool advance) => EnrollmentModel.fromJson({
      'id': 1,
      'status': status,
      'payment_status': pay,
      'course': {'id': 9, 'title': 'x', 'requires_advance_payment': advance},
    });
    expect(e('pending', 'unpaid', true).canPay, isTrue);
    expect(e('approved', 'partial', true).canPay, isTrue);
    expect(e('pending', 'paid', true).canPay, isFalse);
    expect(e('cancelled', 'unpaid', true).canPay, isFalse);
    expect(e('rejected', 'unpaid', true).canPay, isFalse);
    expect(e('pending', 'unpaid', false).canPay, isFalse);
  });

  test('advance breakdown: due now = advance, rest is paid at the institute', () {
    final d = PaymentDetailsModel.fromJson({
      'enrollment_id': 1,
      'payment_status': 'unpaid',
      'currency': 'SYP',
      'amount_due': 15000,
      'advance_amount': 12000,
      'amount_paid': 0,
      'amount_remaining': 15000,
      'advance_remaining': 12000,
      'shamcash': {'available': true, 'address': 'abc'},
    });
    expect(d.hasPendingAdvance, isTrue);
    expect(d.amountToSendNow, 12000);
    expect(d.remainingAtInstitute, 3000);
    expect(d.advanceRequiredButUnavailable, isFalse);
  });

  test('advance required but ShamCash not connected is flagged', () {
    final d = PaymentDetailsModel.fromJson({
      'enrollment_id': 1,
      'payment_status': 'unpaid',
      'amount_due': 15000,
      'advance_amount': 12000,
      'amount_remaining': 15000,
      'advance_remaining': 12000,
      'shamcash': {'available': false},
    });
    expect(d.shamcash.canPay, isFalse);
    expect(d.advanceRequiredButUnavailable, isTrue);
  });

  test('after the advance is paid only the institute remainder is left', () {
    final d = PaymentDetailsModel.fromJson({
      'enrollment_id': 1,
      'payment_status': 'partial',
      'amount_due': 15000,
      'advance_amount': 12000,
      'amount_paid': 12000,
      'amount_remaining': 3000,
      'advance_remaining': 0,
      'shamcash': {'available': true, 'address': 'abc'},
    });
    expect(d.hasPendingAdvance, isFalse);
    expect(d.amountToSendNow, 3000);
    expect(d.remainingAtInstitute, 3000);
  });
}
