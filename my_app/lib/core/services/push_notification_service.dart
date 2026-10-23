import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../config/app_debug_log.dart';
import '../data/repositories/device_repository.dart';
import '../models/json_helpers.dart';
import '../navigation/push_navigation.dart';
import '../navigation/route_motion_builder.dart';
import '../push/push_local_notifications.dart';
import '../session/enrollment_status_coordinator.dart';
import '../session/remote_notification_sync.dart';
import '../storage/notification_delivery_store.dart';
import '../storage/token_storage.dart';
import '../utils/app_toast.dart';

/// FCM: أذونات، تسجيل التوكن، عرض الإشعارات، والتوجيه عند الضغط.
class PushNotificationService extends GetxService {
  PushNotificationService(this._tokenStorage, this._deviceRepository);

  final TokenStorage _tokenStorage;
  final DeviceRepository _deviceRepository;

  static const _storageKey = 'push_notifications_enabled';

  // getter وليس حقلاً: على الويب/Windows لا يُهيّأ Firebase، والوصول المبكر لـ instance يُسقط التطبيق عند الإقلاع.
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  late final GetStorage _prefs;

  StreamSubscription<String>? _tokenRefreshSub;

  /// تُحفظ لتُلغى قبل أي تسجيل ثانٍ (init مرتين كان يكرّر عرض كل إشعار وفتحه).
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  String? _lastSyncedToken;

  final notificationsEnabled = true.obs;
  final notificationsPermissionGranted = true.obs;
  final isToggling = false.obs;

  Future<void> init() async {
    if (kIsWeb) return;

    _prefs = GetStorage();
    notificationsEnabled.value = _prefs.read<bool>(_storageKey) ?? true;
    // نسخة للـ isolate الخلفي (لمن أوقف الإشعارات في إصدار سابق قبل وجود هذه النسخة).
    await PushLocalNotifications.saveUserEnabled(notificationsEnabled.value);

    await PushLocalNotifications.ensureInitialized(onTap: _openFromPayload);

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      await _messaging.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
    }

    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _messaging.onTokenRefresh.listen(_onTokenRefresh);
    _listenForegroundMessages();
    _listenOpenedFromBackground();
    await _handleInitialMessage();
    await _handleLaunchPayload();

    // لا نطلب الإذن عند الإقلاع (إرشادات Apple وGoogle): يُطلب بعد أول حجز، حيث للإشعارات سبب واضح
    // (قبول التسجيل وتأكيد الدفع)، أو من الإعدادات. هنا نقرأ الحالة ونسجّل التوكن فقط.
    if (notificationsEnabled.value) {
      unawaited(ensurePermissionsAndSyncToken(requestPermission: false));
    }
  }

  /// بعد حجز ناجح: يطلب الإذن مرة واحدة إن لم يكن ممنوحاً (نافذة النظام لا تظهر إن رُفض نهائياً).
  /// يُستدعى بعد بدء الانتقال من صفحة الحجز.
  Future<void> requestPermissionAfterBooking() async {
    if (kIsWeb || !notificationsEnabled.value) return;
    if (await _hasPermission()) return;
    // نافذة النظام على Android لا تظهر أثناء انتقال الصفحات، وإطار واحد لا يكفي: ننتظر استقرار كل
    // الانتقالات (الرئيسية، وصفحة الدفع إن فُتحت بعدها).
    await RouteMotion.whenSettled();
    // في الخلفية لا تظهر النافذة، ويُستهلك الطلب الوحيد بلا فائدة (Android يكفّ عن عرضها بعد رفضين).
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      AppDebugLog.fcm('permission after booking skipped: app not in foreground');
      return;
    }
    await ensurePermissionsAndSyncToken();
  }

  /// يطلب إذن الإشعارات (Android 13+) ثم يسجّل توكن FCM.
  ///
  /// [requestPermission] = false (عند العودة للتطبيق): نقرأ حالة الإذن فقط بدون إظهار نافذة النظام.
  /// التوكن يُرسل للخادم فقط إذا تغيّر منذ آخر تسجيل ناجح.
  Future<void> ensurePermissionsAndSyncToken({bool requestPermission = true}) async {
    if (kIsWeb || !notificationsEnabled.value) return;

    final granted = requestPermission ? await _requestPermissions() : await _hasPermission();
    notificationsPermissionGranted.value = granted;
    AppDebugLog.fcm('notifications enabled=${notificationsEnabled.value} permission=$granted');
    if (!granted) {
      AppDebugLog.fcm('notification permission not granted — token sync only');
    }
    await syncDeviceTokenIfLoggedIn();
  }

  Future<void> syncDeviceTokenIfLoggedIn({bool force = false}) async {
    if (!_tokenStorage.isLoggedIn || !notificationsEnabled.value) return;
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        AppDebugLog.fcm('getToken returned empty');
        return;
      }
      await _registerToken(token, force: force);
    } catch (e) {
      AppDebugLog.fcm('getToken failed: $e');
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    if (kIsWeb) return;
    if (isToggling.value) return;
    if (enabled) {
      if (notificationsEnabled.value && notificationsPermissionGranted.value) return;
    } else if (!notificationsEnabled.value) {
      return;
    }

    isToggling.value = true;
    try {
      if (enabled) {
        final granted = await _requestPermissions();
        notificationsPermissionGranted.value = granted;
        if (!granted) {
          AppToast.show('notifications_setting'.tr, 'notifications_permission_denied'.tr);
          return;
        }
        await _prefs.write(_storageKey, true);
        await PushLocalNotifications.saveUserEnabled(true);
        notificationsEnabled.value = true;
        notificationsPermissionGranted.value = true;
        clearSyncedToken();
        await syncDeviceTokenIfLoggedIn(force: true);
        // لا إشعار: المفتاح نفسه يعرض الحالة الجديدة.
        return;
      }

      // الإيقاف محلياً أولاً: إن فشل إلغاء التسجيل (بلا إنترنت) يبقى المفتاح مطفأً ولا تُعرض إشعارات.
      await _prefs.write(_storageKey, false);
      await PushLocalNotifications.saveUserEnabled(false);
      await _unregisterCurrentToken();
      notificationsEnabled.value = false;
      notificationsPermissionGranted.value = false;
      _lastSyncedToken = null;
      try {
        await _messaging.deleteToken();
      } catch (e) {
        AppDebugLog.fcm('deleteToken failed: $e');
      }
      // لا إشعار: المفتاح نفسه يعرض الحالة الجديدة.
    } catch (e) {
      AppDebugLog.fcm('toggle failed: $e');
      AppToast.show('error'.tr, 'notifications_toggle_failed'.tr);
    } finally {
      isToggling.value = false;
    }
  }

  Future<void> onLogout() async {
    if (kIsWeb) return;
    try {
      await _unregisterCurrentToken();
    } catch (e) {
      AppDebugLog.fcm('logout unregister failed: $e');
    } finally {
      clearSyncedToken();
    }
  }

  Future<void> _unregisterCurrentToken() async {
    if (!_tokenStorage.isLoggedIn) return;
    try {
      final token = _lastSyncedToken ?? await _messaging.getToken();
      if (token == null || token.isEmpty) return;
      await _deviceRepository.unregisterDeviceToken(token);
      AppDebugLog.fcm('device token unregistered');
    } catch (e) {
      AppDebugLog.fcm('unregister token failed: $e');
    }
  }

  Future<void> _registerToken(String token, {bool force = false}) {
    if (!_tokenStorage.isLoggedIn || !notificationsEnabled.value) return Future<void>.value();
    if (!force && _lastSyncedToken == token) return Future<void>.value();
    // طلبات متزامنة (init + post-launch + resume) تشترك في نفس التسجيل الجاري.
    final running = _registering;
    if (running != null) return running;
    final future = _registerWithRetry(token);
    _registering = future;
    return future.whenComplete(() => _registering = null);
  }

  Future<void>? _registering;

  Future<void> _registerWithRetry(String token) async {
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        AppDebugLog.fcm('registering device token (${token.length} chars) attempt=$attempt');
        await _deviceRepository.registerDeviceToken(token);
        _lastSyncedToken = token;
        AppDebugLog.fcm('device token registered on server');
        AppDebugLog.fcm('FCM token (for backend): $token');
        return;
      } catch (e) {
        AppDebugLog.fcm('register token failed (attempt $attempt): $e');
        if (attempt == 3) {
          _lastSyncedToken = null;
          return;
        }
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      }
    }
  }

  Future<void> _onTokenRefresh(String token) => _registerToken(token, force: true);

  Future<bool> _hasPermission() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return PushLocalNotifications.hasAndroidPermission();
    }
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<bool> _requestPermissions() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final granted = await PushLocalNotifications.requestAndroidPermission();
      AppDebugLog.fcm('android POST_NOTIFICATIONS granted: $granted');
      return granted;
    }

    final settings = await _messaging.requestPermission(alert: true, badge: true, sound: true, provisional: false);
    AppDebugLog.fcm('ios permission: ${settings.authorizationStatus}');
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  void _listenForegroundMessages() {
    _foregroundSub?.cancel();
    _foregroundSub = FirebaseMessaging.onMessage.listen((message) async {
      if (!notificationsEnabled.value) return;
      AppDebugLog.fcm(
        'foreground: id=${message.messageId} '
        'title=${message.notification?.title ?? message.data['title']} '
        'data=${message.data}',
      );
      final data = Map<String, dynamic>.from(message.data);
      await _recordDelivered(data);
      await RemoteNotificationSync.onMessageReceived(data);
      await PushLocalNotifications.showRemoteMessage(message);
    });
  }

  /// FCM أوصل الإشعار: لا يعيد عرضَه فحصُ إشعارات الخادم الدوري، ولا مراقبُ حالة التسجيل بإشعار محلي ثانٍ
  /// عند اكتشاف التغيّر نفسه (كان قبول التسجيل يظهر مرتين والتطبيق مفتوح).
  Future<void> _recordDelivered(Map<String, dynamic> data) async {
    try {
      final notificationId = JsonHelpers.parseIntOrNull(data['notification_id']);
      if (notificationId != null && Get.isRegistered<NotificationDeliveryStore>()) {
        await Get.find<NotificationDeliveryStore>().markDelivered([notificationId]);
      }
      if (Get.isRegistered<EnrollmentStatusCoordinator>()) {
        await Get.find<EnrollmentStatusCoordinator>().recordServerPush(data);
      }
    } catch (e) {
      AppDebugLog.fcm('record delivered failed: $e');
    }
  }

  void _listenOpenedFromBackground() {
    _openedSub?.cancel();
    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageNavigation);
  }

  /// فُتح التطبيق بالضغط على إشعار FCM وهو مغلق. شاشة البداية ما زالت ظاهرة: PushNavigation يؤجّل
  /// الوجهة حتى تنتقل (كان التأخير الثابت 600ms يفتحها قبل ذلك فيمسحها offAllNamed).
  Future<void> _handleInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message == null) return;
    _handleMessageNavigation(message);
  }

  /// أو بالضغط على إشعار محلي (عُرض والتطبيق مفتوح ثم أُغلق) — معالج الضغط لا يُستدعى في هذه الحالة.
  Future<void> _handleLaunchPayload() async {
    final payload = await PushLocalNotifications.launchPayload();
    if (payload != null) _openFromPayload(payload);
  }

  void _handleMessageNavigation(RemoteMessage message) {
    _open(Map<String, dynamic>.from(message.data));
  }

  void _openFromPayload(String payload) => _open(PushLocalNotifications.decodePayload(payload));

  void _open(Map<String, dynamic> data) {
    unawaited(_recordDelivered(data).then((_) => RemoteNotificationSync.onMessageReceived(data)));
    PushNavigation.open(data);
  }

  void clearSyncedToken() {
    _lastSyncedToken = null;
  }

  @override
  void onClose() {
    _tokenRefreshSub?.cancel();
    _foregroundSub?.cancel();
    _openedSub?.cancel();
    super.onClose();
  }
}
