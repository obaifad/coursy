import 'package:get/get.dart';

import '../../../core/data/repositories/notification_repository.dart';
import '../../../core/models/app_models.dart';

class NotificationsController extends GetxController {
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
    isLoading.value = true;
    errorMessage.value = null;
    _page = 1;
    try {
      final result = await _repository.fetchNotificationsPage(page: _page, perPage: _perPage);
      items.assignAll(result.items);
      hasMore.value = result.hasMore;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
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
}
