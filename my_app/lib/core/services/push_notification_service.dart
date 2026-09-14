import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../config/app_debug_log.dart';
import '../data/repositories/device_repository.dart';
import '../navigation/push_navigation.dart';
import '../push/push_local_notifications.dart';
import '../session/remote_notification_sync.dart';
import '../storage/token_storage.dart';

/// FCM: أذونات، تسجيل التوكن، عرض الإشعارات، والتوجيه عند الضغط.
class PushNotificationService extends GetxService {
  PushNotificationService(this._tokenStorage, this._deviceRepository);

  final TokenStorage _tokenStorage;
  final DeviceRepository _deviceRepository;

  static const _storageKey = 'push_notifications_enabled';

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  late final GetStorage _prefs;

  StreamSubscription<String>? _tokenRefreshSub;
  String? _lastSyncedToken;

  final notificationsEnabled = true.obs;
  final notificationsPermissionGranted = true.obs;
  final isToggling = false.obs;

  Future<void> init() async {
    if (kIsWeb) return;

    _prefs = GetStorage();
    notificationsEnabled.value = _prefs.read<bool>(_storageKey) ?? true;

    await PushLocalNotifications.ensureInitialized(onTap: _openFromPayload);

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    _tokenRefreshSub = _messaging.onTokenRefresh.listen(_onTokenRefresh);
    _listenForegroundMessages();
    _listenOpenedFromBackground();
    await _handleInitialMessage();

    if (notificationsEnabled.value) {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        // Android 13+: طلب الإذن بعد ظهور الواجهة لضمان ظهور نافذة النظام.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(ensurePermissionsAndSyncToken());
        });
      } else {
        await ensurePermissionsAndSyncToken();
      }
    }
  }

  /// يطلب إذن الإشعارات (Android 13+) ثم يسجّل توكن FCM.
  Future<void> ensurePermissionsAndSyncToken() async {
    if (!notificationsEnabled.value) return;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      notificationsPermissionGranted.value = await PushLocalNotifications.hasAndroidPermission();
    }

    final granted = await _requestPermissions();
    notificationsPermissionGranted.value = granted;
    AppDebugLog.fcm('notifications enabled=${notificationsEnabled.value} permission=$granted');
    if (!granted) {
      AppDebugLog.fcm('notification permission not granted — token sync only');
    }
    await syncDeviceTokenIfLoggedIn(force: true);
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
          Get.snackbar('notifications_setting'.tr, 'notifications_permission_denied'.tr);
          return;
        }
        await _prefs.write(_storageKey, true);
        notificationsEnabled.value = true;
        notificationsPermissionGranted.value = true;
        clearSyncedToken();
        await syncDeviceTokenIfLoggedIn(force: true);
        Get.snackbar('notifications_setting'.tr, 'notifications_enabled_msg'.tr);
        return;
      }

      await _unregisterCurrentToken();
      await _messaging.deleteToken();
      await _prefs.write(_storageKey, false);
      notificationsEnabled.value = false;
      notificationsPermissionGranted.value = false;
      _lastSyncedToken = null;
      Get.snackbar('notifications_setting'.tr, 'notifications_disabled_msg'.tr);
    } catch (e) {
      AppDebugLog.fcm('toggle failed: $e');
      Get.snackbar('error'.tr, 'notifications_toggle_failed'.tr);
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
    final token = _lastSyncedToken ?? await _messaging.getToken();
    if (token == null || token.isEmpty) return;
    try {
      await _deviceRepository.unregisterDeviceToken(token);
      AppDebugLog.fcm('device token unregistered');
    } catch (e) {
      AppDebugLog.fcm('unregister token failed: $e');
    }
  }

  Future<void> _registerToken(String token, {bool force = false}) async {
    if (!_tokenStorage.isLoggedIn || !notificationsEnabled.value) return;
    if (!force && _lastSyncedToken == token) return;

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

  Future<bool> _requestPermissions() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final granted = await PushLocalNotifications.requestAndroidPermission();
      AppDebugLog.fcm('android POST_NOTIFICATIONS granted: $granted');
      return granted;
    }

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    AppDebugLog.fcm('ios permission: ${settings.authorizationStatus}');
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  void _listenForegroundMessages() {
    FirebaseMessaging.onMessage.listen((message) async {
      if (!notificationsEnabled.value) return;
      AppDebugLog.fcm(
        'foreground: id=${message.messageId} '
        'title=${message.notification?.title ?? message.data['title']} '
        'data=${message.data}',
      );
      await RemoteNotificationSync.onMessageReceived(Map<String, dynamic>.from(message.data));
      await PushLocalNotifications.showRemoteMessage(message);
    });
  }

  void _listenOpenedFromBackground() {
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageNavigation);
  }

  Future<void> _handleInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message == null) return;
    _scheduleNavigation(message);
  }

  void _scheduleNavigation(RemoteMessage message) {
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      _handleMessageNavigation(message);
    });
  }

  void _handleMessageNavigation(RemoteMessage message) {
    final data = Map<String, dynamic>.from(message.data);
    unawaited(RemoteNotificationSync.onMessageReceived(data));
    if (data.isEmpty && message.notification != null) {
      PushNavigation.openFromMessageData(const {});
      return;
    }
    PushNavigation.openFromMessageData(data);
  }

  void _openFromPayload(String payload) {
    final data = <String, dynamic>{};
    for (final part in payload.split('&')) {
      final idx = part.indexOf('=');
      if (idx <= 0) continue;
      data[part.substring(0, idx)] = part.substring(idx + 1);
    }
    unawaited(RemoteNotificationSync.onMessageReceived(data));
    PushNavigation.openFromMessageData(data);
  }

  void clearSyncedToken() {
    _lastSyncedToken = null;
  }

  @override
  void onClose() {
    _tokenRefreshSub?.cancel();
    super.onClose();
  }
}
