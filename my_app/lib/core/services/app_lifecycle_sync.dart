import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../modules/profile/controllers/my_courses_controller.dart';
import '../../modules/root/controllers/root_controller.dart';
import '../../routes/app_routes.dart';
import '../navigation/app_navigation.dart';
import '../navigation/home_scroll_reset.dart';
import '../storage/token_storage.dart';
import 'enrollment_sync_service.dart';
import 'push_notification_service.dart';

/// مزامنة عند العودة للتطبيق + مراقبة دورية (احتياطية) لحالة التسجيل.
/// المصدر الأساسي للتحديثات هو FCM — الاستطلاع هنا متباعد لتوفير البطارية والباقة.
class AppLifecycleSync extends GetxService with WidgetsBindingObserver {
  static const _pollInterval = Duration(minutes: 2);

  Timer? _pollTimer;
  bool _isForeground = true;

  /// المراقبة تبدأ من `main` (بعد seedStatuses) أو بعد تسجيل الدخول — لا نبدأها هنا
  /// حتى لا يسبق أول فحص تحميلَ الحالات المحفوظة.
  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
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
        _refreshVisibleTab();
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
      unawaited(_pollEnrollments(force: true));
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// العودة من الخلفية بعد مدة: الرئيسية أو «دوراتي» الظاهرة تُحدَّث إن كانت قديمة (دقيقتان)، كما عند
  /// الرجوع إليها من تبويب آخر — كانت تبقى على بيانات ما قبل الخروج حتى تبديل التبويب أو السحب للتحديث.
  void _refreshVisibleTab() {
    if (!Get.isRegistered<RootController>() || Get.currentRoute != AppRoutes.root) return;
    final tab = Get.find<RootController>().currentIndex.value;
    if (tab == 2) HomeScrollReset.notifyIfHomeVisible(scrollToTop: false);
    if (tab == 3 && Get.isRegistered<MyCoursesController>()) {
      unawaited(Get.find<MyCoursesController>().loadIfStale());
    }
  }

  Future<void> _onResume() async {
    if (!Get.find<TokenStorage>().isLoggedIn) return;

    AppNavigation.ensureRootBinding();

    if (Get.isRegistered<PushNotificationService>()) {
      await Get.find<PushNotificationService>().ensurePermissionsAndSyncToken(requestPermission: false);
    }
    await _pollEnrollments();
  }

  Future<void> _pollEnrollments({bool force = false}) async {
    if (!Get.isRegistered<EnrollmentSyncService>()) return;
    await Get.find<EnrollmentSyncService>().checkForStatusChanges(force: force);
  }
}
