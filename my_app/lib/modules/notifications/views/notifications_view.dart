import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/locale/locale_rebuild.dart';
import '../../../core/navigation/push_navigation.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/session/remote_notification_sync.dart';
import '../../../core/models/app_models.dart';
import '../../../widgets/app_skeletons.dart';
import '../../../widgets/design_system.dart';
import '../controllers/notifications_controller.dart';

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  IconData _iconFor(String type) {
    switch (type) {
      case 'enrollment':
      case 'enrollment_pending':
      case 'pending':
        return Icons.hourglass_top_rounded;
      case 'approval':
      case 'enrollment_approved':
      case 'approved':
        return Icons.check_circle_outline_rounded;
      case 'enrollment_rejected':
      case 'rejected':
      case 'enrollment_cancelled':
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'reminder':
        return Icons.schedule_rounded;
      case 'promotion':
      case 'promo':
        return Icons.local_offer_outlined;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  Future<void> _onNotificationTap(NotificationModel notification) async {
    final data = RemoteNotificationSync.notificationToPushData(notification);
    await RemoteNotificationSync.onMessageReceived(data);
    PushNavigation.openFromMessageData(data);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = localeRebuildToken;
      return Scaffold(
      appBar: AppBar(
        title: Text('notifications'.tr),
        actions: [
          IconButton(onPressed: controller.loadNotifications, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const AppListSkeleton();
        }
        if (controller.items.isEmpty) {
          return RefreshIndicator(
            onRefresh: controller.loadNotifications,
            child: AppEmptyState.scrollable(
              context: context,
              message: 'notifications_empty'.tr,
              icon: Icons.notifications_none_rounded,
            ),
          );
        }
        return AppMaxWidth(
          child: RefreshIndicator(
          onRefresh: controller.loadNotifications,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemBuilder: (_, i) {
              if (i == controller.items.length) {
                if (!controller.hasMore.value) return const SizedBox.shrink();
                return OutlinedButton.icon(
                  onPressed: controller.isLoadingMore.value ? null : controller.loadMoreNotifications,
                  icon: controller.isLoadingMore.value
                      ? const AppInlineLoader()
                      : const Icon(Icons.expand_more_rounded),
                  label: Text('load_more'.tr),
                );
              }
              final n = controller.items[i];
              return Dismissible(
                key: ValueKey(n.id),
                direction: DismissDirection.horizontal,
                background: Container(
                  alignment: AlignmentDirectional.centerEnd,
                  padding: const EdgeInsetsDirectional.only(end: 20),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _onNotificationTap(n),
                  child: NotificationCard(
                    title: n.title.trim().isEmpty ? 'notification_default_title'.tr : n.title,
                    subtitle: n.subtitle,
                    icon: _iconFor(n.type),
                    unread: !n.isRead,
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: controller.items.length + 1,
          ),
          ),
        );
      }),
    );
    });
  }
}
