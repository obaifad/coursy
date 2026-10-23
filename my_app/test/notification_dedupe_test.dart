import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/push/push_local_notifications.dart';
import 'package:my_app/core/storage/notification_delivery_store.dart';

/// «تم استلام الحجز» كان يظهر مرتين: فحص قائمة الخادم وFCM يعرضان الإشعار نفسه، ولا يرى أحدهما الآخر.
void main() {
  late NotificationDeliveryStore store;
  setUp(() => store = NotificationDeliveryStore());

  test('whichever path shows it first, the second one with the same notification id is skipped', () {
    expect(store.claimShown(notificationId: 42, type: 'enrollment_pending', enrollmentId: 7), isTrue);
    expect(store.claimShown(notificationId: 42, type: 'enrollment_pending', enrollmentId: 7), isFalse);
  });

  test('a push without notification_id still matches by type and enrollment', () {
    expect(store.claimShown(notificationId: 42, type: 'enrollment_pending', enrollmentId: 7), isTrue);
    expect(store.claimShown(type: 'Enrollment_Pending ', enrollmentId: 7), isFalse);
  });

  test('the next status of the same enrollment is not swallowed', () {
    expect(store.claimShown(notificationId: 42, type: 'enrollment_pending', enrollmentId: 7), isTrue);
    expect(store.claimShown(notificationId: 43, type: 'enrollment_approved', enrollmentId: 7), isTrue);
  });

  test('another enrollment is not swallowed', () {
    expect(store.claimShown(type: 'enrollment_pending', enrollmentId: 7), isTrue);
    expect(store.claimShown(type: 'enrollment_pending', enrollmentId: 8), isTrue);
  });

  test('nothing to match on: never treated as a duplicate', () {
    expect(store.claimShown(type: 'promo'), isTrue);
    expect(store.claimShown(type: 'promo'), isTrue);
  });

  test('both paths use the same display id, so a racing second copy replaces the first', () {
    expect(PushLocalNotifications.serverNotificationId(42), PushLocalNotifications.serverNotificationId(42));
    expect(PushLocalNotifications.serverNotificationId(42), 500042, reason: 'the list check used id + 500000');
  });
}
