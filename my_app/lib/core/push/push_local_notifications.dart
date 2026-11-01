import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef PushNotificationTapHandler = void Function(String payload);

/// عرض إشعارات محلية — مشترك بين المقدمة والخلفية (data-only FCM).
abstract final class PushLocalNotifications {
  static const channelId = 'coursy_default';
  static const channelName = 'Coursy';

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// مفتاح الإشعارات في الإعدادات. يُحفظ في [SharedPreferencesAsync] لأن الفحص الخلفي ومعالج FCM
  /// يعملان في isolate منفصل لا يرى GetStorage.
  static const userEnabledKey = 'push_notifications_enabled';

  /// false = المستخدم أوقف الإشعارات: لا يُعرض أي إشعار محلي (حالات التسجيل، الفحص الخلفي، FCM).
  static bool userEnabled = true;

  static Future<void> saveUserEnabled(bool enabled) async {
    userEnabled = enabled;
    try {
      await SharedPreferencesAsync().setBool(userEnabledKey, enabled);
    } catch (_) {}
  }

  /// للـ isolate الخلفي: يقرأ المفتاح المحفوظ (الافتراضي مفعّل).
  static Future<void> loadUserEnabled() async {
    try {
      userEnabled = await SharedPreferencesAsync().getBool(userEnabledKey) ?? true;
    } catch (_) {
      userEnabled = true;
    }
  }

  static AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  static PushNotificationTapHandler? _onTap;
  static bool _tapRegistered = false;

  /// [onTap] يُسجَّل حتى لو سبقت التهيئةُ (bootstrapFirebase يهيّئ بلا معالج قبل PushNotificationService) —
  /// كان يُتجاهل فلا يفعل الضغط على الإشعار المحلي شيئاً.
  static Future<void> ensureInitialized({PushNotificationTapHandler? onTap}) async {
    if (onTap != null) _onTap = onTap;
    if (_initialized && (_onTap == null || _tapRegistered)) return;

    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    // لا نطلب الإذن عند التهيئة على iOS: يُطلب بعد أول حجز أو من الإعدادات (PushNotificationService).
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onTap == null ? null : _onResponse,
    );
    _tapRegistered = _onTap != null;
    if (_initialized) return;

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

  static void _onResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    _onTap?.call(payload);
  }

  /// الإشعار المحلي الذي فتح التطبيق وهو مُغلق — في هذه الحالة لا يُستدعى معالج الضغط.
  static Future<String?> launchPayload() async {
    if (kIsWeb) return null;
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details == null || !details.didNotificationLaunchApp) return null;
      final payload = details.notificationResponse?.payload;
      return payload == null || payload.isEmpty ? null : payload;
    } catch (_) {
      return null;
    }
  }

  /// بيانات الإشعار ← نص JSON يُحمل مع الإشعار المحلي. كان `k=v&k=v`، فقيمة من الخادم فيها
  /// `&course_id=9` (عنوان أو رسالة) كانت تضيف مفتاحاً وتغيّر الشاشة التي يفتحها الضغط.
  static String encodePayload(Map<String, dynamic> data) {
    if (data.isEmpty) return '';
    return jsonEncode({for (final e in data.entries) e.key: e.value?.toString()});
  }

  /// عكس [encodePayload] → خريطة بيانات مثل `RemoteMessage.data`. يقبل أيضاً الصيغة القديمة
  /// `type=enrollment_approved&course_id=5` لإشعارات عُرضت قبل التحديث.
  static Map<String, dynamic> decodePayload(String payload) {
    if (payload.startsWith('{')) {
      try {
        final decoded = jsonDecode(payload);
        if (decoded is Map) return {for (final e in decoded.entries) '${e.key}': e.value};
      } catch (_) {}
      return <String, dynamic>{};
    }
    final data = <String, dynamic>{};
    for (final part in payload.split('&')) {
      final idx = part.indexOf('=');
      if (idx <= 0) continue;
      data[part.substring(0, idx)] = part.substring(idx + 1);
    }
    return data;
  }

  /// عند انتهاء الجلسة: لا تبقى في درج الإشعارات حالات تسجيل ودفع الحساب السابق.
  static Future<void> cancelAll() async {
    if (kIsWeb) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
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

  /// رقم العرض لإشعار من الخادم — نفسه من فحص القائمة ومن FCM، فيستبدل النظامُ النسخة الأولى إن وصلت الثانية.
  static int serverNotificationId(int notificationId) => notificationId + 500000;

  static Future<void> showRemoteMessage(RemoteMessage message, {bool requirePermission = true}) async {
    final parsed = parseRemoteMessage(message);
    if (parsed == null) return;
    final notificationId = int.tryParse('${message.data['notification_id'] ?? ''}');
    await showRaw(
      id: notificationId != null && notificationId > 0 ? serverNotificationId(notificationId) : message.hashCode,
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
    if (!userEnabled) return;
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
      // نص الإشعار (قبول التسجيل، تأكيد الدفع، اسم الكورس) لا يظهر على شاشة القفل إلا إن سمح المستخدم بذلك.
      visibility: NotificationVisibility.private,
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

    final title = notification?.title ?? data['title']?.toString() ?? data['notification_title']?.toString();
    final body =
        notification?.body ??
        data['body']?.toString() ??
        data['message']?.toString() ??
        data['notification_body']?.toString();

    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return null;
    }

    return (title: title ?? 'Coursy', body: body ?? '', payload: encodePayload(data));
  }
}
