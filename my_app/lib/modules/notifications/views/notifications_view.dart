import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/responsive/responsive.dart';
import '../../../widgets/app_skeletons.dart';
import '../../../widgets/design_system.dart';
import '../controllers/notifications_controller.dart';

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  IconData _iconFor(String type) {
    switch (type) {
      case 'approval':
        return Icons.check_circle_outline_rounded;
      case 'reminder':
        return Icons.schedule_rounded;
      case 'promotion':
      case 'promo':
        return Icons.local_offer_outlined;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
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
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 220),
                Center(child: Text('لا توجد إشعارات')),
              ],
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
                  label: const Text('تحميل المزيد'),
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
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                ),
                child: NotificationCard(
                  title: n.title,
                  subtitle: n.subtitle,
                  icon: _iconFor(n.type),
                  unread: !n.isRead,
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
  }
}
