import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../navigation/app_navigation.dart';
import '../storage/token_storage.dart';
import 'enrollment_sync_service.dart';
import 'push_notification_service.dart';

/// مزامنة عند العودة للتطبيق + مراقبة دورية لحالة التسجيل.
class AppLifecycleSync extends GetxService with WidgetsBindingObserver {
  static const _pollInterval = Duration(seconds: 12);

  Timer? _pollTimer;
  bool _isForeground = true;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => startWatching());
  }

  @override
  void onClose() {
    stopWatching();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  /// يبدأ المراقبة فوراً (بعد الدخول أو فتح التطبيق).
  void startWatching() {
    if (!Get.find<TokenStorage>().isLoggedIn) return;
    _isForeground = true;
    unawaited(_pollEnrollments());
    _startPolling();
  }

  void stopWatching() {
    _stopPolling();
    _isForeground = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _isForeground = true;
        unawaited(_onResume());
        _startPolling();
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _isForeground = false;
        _stopPolling();
    }
  }

  void _startPolling() {
    if (!_isForeground || !Get.find<TokenStorage>().isLoggedIn) return;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (!_isForeground || !Get.find<TokenStorage>().isLoggedIn) return;
      unawaited(_pollEnrollments());
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _onResume() async {
    if (!Get.find<TokenStorage>().isLoggedIn) return;

    AppNavigation.ensureRootBinding();

    if (Get.isRegistered<PushNotificationService>()) {
      await Get.find<PushNotificationService>().ensurePermissionsAndSyncToken();
    }
    await _pollEnrollments();
  }

  Future<void> _pollEnrollments() async {
    if (!Get.isRegistered<EnrollmentSyncService>()) return;
    await Get.find<EnrollmentSyncService>().checkForStatusChanges();
  }
}
