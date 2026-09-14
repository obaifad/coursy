import 'package:get/get.dart';

import '../../../core/data/repositories/notification_repository.dart';
import '../../../core/locale/locale_request_guard.dart';
import '../../../core/models/app_models.dart';
import '../../../core/network/api_exception.dart';

class NotificationsController extends GetxController with LatestLoadGuard {
  final NotificationRepository _repository = Get.find();

  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final errorMessage = RxnString();
  final items = <NotificationModel>[].obs;
  int _page = 1;
  static const _perPage = 15;

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    final session = beginLoad();
    isLoading.value = true;
    errorMessage.value = null;
    _page = 1;
    try {
      final result = await _repository.fetchNotificationsPage(page: _page, perPage: _perPage);
      applyIfCurrent(session, () {
        items.assignAll(result.items);
        hasMore.value = result.hasMore;
      });
    } on ApiCancelledException {
      return;
    } catch (e) {
      if (shouldApply(session)) errorMessage.value = e.toString();
    } finally {
      applyIfCurrent(session, () => isLoading.value = false);
    }
  }

  Future<void> loadMoreNotifications() async {
    if (!hasMore.value || isLoadingMore.value || isLoading.value) return;
    isLoadingMore.value = true;
    try {
      final nextPage = _page + 1;
      final result = await _repository.fetchNotificationsPage(page: nextPage, perPage: _perPage);
      items.addAll(result.items);
      _page = nextPage;
      hasMore.value = result.hasMore;
    } catch (_) {
      hasMore.value = false;
    } finally {
      isLoadingMore.value = false;
    }
  }

  void clearForLogout() {
    items.clear();
    hasMore.value = true;
    errorMessage.value = null;
    isLoading.value = false;
    isLoadingMore.value = false;
    _page = 1;
  }
}
