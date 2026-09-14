import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

typedef PushNotificationTapHandler = void Function(String payload);

/// عرض إشعارات محلية — مشترك بين المقدمة والخلفية (data-only FCM).
abstract final class PushLocalNotifications {
  static const channelId = 'coursy_default';
  static const channelName = 'Coursy';

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  static Future<void> ensureInitialized({PushNotificationTapHandler? onTap}) async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    const iosSettings = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: onTap == null
          ? null
          : (response) {
              final payload = response.payload;
              if (payload == null || payload.isEmpty) return;
              onTap(payload);
            },
    );

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _android?.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          channelName,
          description: 'Coursy notifications',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        ),
      );
    }

    _initialized = true;
  }

  static Future<bool> requestAndroidPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;

    final android = _android;
    if (android == null) return true;

    final current = await android.areNotificationsEnabled();
    if (current == true) return true;

    final requested = await android.requestNotificationsPermission();
    if (requested != null) return requested;

    final after = await android.areNotificationsEnabled();
    return after ?? false;
  }

  static Future<bool> hasAndroidPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;
    final enabled = await _android?.areNotificationsEnabled();
    return enabled ?? true;
  }

  static Future<void> showRemoteMessage(RemoteMessage message, {bool requirePermission = true}) async {
    final parsed = parseRemoteMessage(message);
    if (parsed == null) return;
    await showRaw(
      id: message.hashCode,
      title: parsed.title,
      body: parsed.body,
      payload: parsed.payload,
      requirePermission: requirePermission,
    );
  }

  /// للخلفية/الإغلاق — لا نتحقق من الإذن داخل isolate منفصل.
  static Future<void> showRemoteMessageBackground(RemoteMessage message) =>
      showRemoteMessage(message, requirePermission: false);

  static Future<void> showRaw({
    required int id,
    required String title,
    required String body,
    String payload = '',
    bool requirePermission = true,
  }) async {
    if (title.trim().isEmpty && body.trim().isEmpty) return;

    if (requirePermission && !kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final granted = await hasAndroidPermission();
      if (!granted) return;
    }

    await ensureInitialized();

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Coursy notifications',
      importance: Importance.max,
      priority: Priority.high,
      visibility: NotificationVisibility.public,
      icon: '@drawable/ic_notification',
      playSound: true,
      enableVibration: true,
    );
    const iosDetails = DarwinNotificationDetails();

    await _plugin.show(
      id: id,
      title: title.trim().isEmpty ? 'Coursy' : title,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  static ({String title, String body, String payload})? parseRemoteMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    final title = notification?.title ??
        data['title']?.toString() ??
        data['notification_title']?.toString();
    final body = notification?.body ??
        data['body']?.toString() ??
        data['message']?.toString() ??
        data['notification_body']?.toString();

    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return null;
    }

    return (
      title: title ?? 'Coursy',
      body: body ?? '',
      payload: _encodePayload(data),
    );
  }

  static String _encodePayload(Map<String, dynamic> data) {
    if (data.isEmpty) return '';
    return data.entries.map((e) => '${e.key}=${e.value}').join('&');
  }
}
