import 'dart:async';

import 'package:get/get.dart';

import '../../../core/data/repositories/notification_repository.dart';
import '../../../core/locale/locale_request_guard.dart';
import '../../../core/models/app_models.dart';
import '../../../core/navigation/push_navigation.dart';
import '../../../core/navigation/route_settle.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/session/remote_notification_sync.dart';
import '../../../core/utils/app_toast.dart';

class NotificationsController extends GetxController with LatestLoadGuard, InitialLoadState, SettledLoad {
  final NotificationRepository _repository = Get.find();

  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final isMarkingAllRead = false.obs;
  final hasMore = true.obs;
  final loadMoreFailed = false.obs;
  final errorMessage = RxnString();
  final items = <NotificationModel>[].obs;
  int _page = 1;
  static const _perPage = 15;

  bool get hasUnread => items.any((n) => !n.isRead);

  @override
  void onInit() {
    super.onInit();
    afterRouteSettles(loadNotifications);
  }

  Future<void> loadNotifications() async {
    final session = beginLoad();
    isLoading.value = isInitialLoad;
    errorMessage.value = null;
    try {
      final result = await _repository.fetchNotificationsPage(page: 1, perPage: _perPage);
      applyIfCurrent(session, () {
        items.assignAll(result.items);
        // بعد النجاح فقط: تصفيره قبل الطلب كان يجعل «المزيد» بعد تحديث فاشل يكرّر الصفحة الثانية.
        _page = 1;
        hasMore.value = result.hasMore;
        markLoaded();
      });
    } on ApiCancelledException {
      return;
    } catch (e) {
      if (shouldApply(session)) errorMessage.value = userErrorMessage(e);
    } finally {
      applyIfCurrent(session, () => isLoading.value = false);
    }
  }

  Future<void> loadMoreNotifications() async {
    if (!hasMore.value || isLoadingMore.value || isLoading.value) return;
    isLoadingMore.value = true;
    loadMoreFailed.value = false;
    // إن أُعيد تحميل القائمة أثناء جلب الصفحة التالية تُهمل الصفحة القديمة بدل خلطها بالجديدة.
    final session = currentLoad();
    try {
      final nextPage = _page + 1;
      final result = await _repository.fetchNotificationsPage(page: nextPage, perPage: _perPage);
      applyIfCurrent(session, () {
        items.addAll(result.items);
        _page = nextPage;
        hasMore.value = result.hasMore;
      });
    } catch (_) {
      // الذيل يعرض الفشل مع «إعادة المحاولة» (كانت القائمة تنتهي بصمت عند انقطاع الشبكة).
      if (shouldApply(session)) loadMoreFailed.value = true;
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// الضغط على إشعار: يُعلَّم مقروءاً ويفتح وجهته كما يفعل الضغط على إشعار FCM — الدورة أو الحجز من `data`
  /// إن أرسلها الخادم، وإلا حسب نوع الإشعار كما كان.
  void openNotification(NotificationModel notification) {
    final data = RemoteNotificationSync.notificationToPushData(notification);
    final marking = markRead(notification);
    PushNavigation.openFromMessageData(data);
    // التحديث بعد وصول «مقروء» للخادم — وإلا قد تعيد القائمةُ المحدَّثة الإشعارَ غير مقروء.
    unawaited(marking.then((_) => RemoteNotificationSync.onMessageReceived(data)));
  }

  /// يعلّم الإشعار مقروءاً محلياً فوراً (تختفي النقطة) ثم على الخادم.
  Future<void> markRead(NotificationModel notification) async {
    if (notification.isRead || notification.id <= 0) return;
    _markLocally((n) => n.id == notification.id);
    try {
      await _repository.markRead(notification.id);
    } catch (_) {
      // يبقى مقروءاً هنا؛ إن لم يصل الطلب يعود غير مقروء عند التحديث التالي.
    }
  }

  Future<void> markAllRead() async {
    if (!hasUnread || isMarkingAllRead.value) return;
    isMarkingAllRead.value = true;
    final before = items.toList();
    _markLocally((_) => true);
    try {
      await _repository.markAllRead();
    } catch (e) {
      items.assignAll(before);
      AppToast.show('error'.tr, userErrorMessage(e));
    } finally {
      isMarkingAllRead.value = false;
    }
  }

  /// السحب يُخفي الإشعار من القائمة ويعلّمه مقروءاً (لا يوجد حذف على الخادم).
  void dismiss(NotificationModel notification) {
    items.removeWhere((n) => n.id == notification.id);
    if (notification.isRead || notification.id <= 0) return;
    unawaited(_repository.markRead(notification.id).catchError((Object _) {}));
  }

  void _markLocally(bool Function(NotificationModel n) test) {
    if (!items.any((n) => !n.isRead && test(n))) return;
    items.assignAll([for (final n in items) !n.isRead && test(n) ? n.copyWith(isRead: true) : n]);
  }

  void clearForLogout() {
    resetInitialLoad();
    items.clear();
    hasMore.value = true;
    errorMessage.value = null;
    isLoading.value = false;
    isLoadingMore.value = false;
    isMarkingAllRead.value = false;
    _page = 1;
  }
}
