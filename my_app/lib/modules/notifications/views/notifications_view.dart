import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';

import '../../../core/locale/locale_rebuild.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../auth/widgets/register_form_widgets.dart';
import '../../../core/responsive/responsive.dart';
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

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = localeRebuildToken;
      return Scaffold(
        appBar: AppBar(
          title: Text('notifications'.tr),
          actions: [
            Obx(() {
              if (!controller.hasUnread) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'notifications_mark_all_read'.tr,
                onPressed: controller.isMarkingAllRead.value ? null : controller.markAllRead,
                icon: const Icon(Icons.done_all_rounded),
              );
            }),
            IconButton(
              tooltip: 'refresh'.tr,
              onPressed: controller.loadNotifications,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const AppListSkeleton();
          }
          // لقطة واحدة لكل بناء: القائمة تُبنى لاحقاً أثناء التمرير، وقراءة القائمة الحية بعد تغيّرها ترمي RangeError.
          final items = controller.items.toList(growable: false);
          final hasMore = controller.hasMore.value;
          final loadingMore = controller.isLoadingMore.value;
          final error = controller.errorMessage.value;
          if (items.isEmpty && error != null) {
            return RefreshIndicator(
              onRefresh: controller.loadNotifications,
              child: AppEmptyState.scrollable(
                context: context,
                message: error,
                icon: Icons.cloud_off_outlined,
                action: FilledButton(onPressed: controller.loadNotifications, child: Text('retry'.tr)),
              ),
            );
          }
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: controller.loadNotifications,
              child: AppEmptyState.scrollable(
                context: context,
                message: 'notifications_empty'.tr,
                subtitle: 'notifications_empty_hint'.tr,
                icon: Icons.notifications_none_rounded,
                action: SizedBox(
                  width: 220,
                  child: RegisterGradientButton(label: 'browse_courses'.tr, onPressed: AppNavigation.openCoursesTab),
                ),
              ),
            );
          }
          return AppMaxWidth(
            child: RefreshIndicator(
              onRefresh: controller.loadNotifications,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16, 16, 16, AppLayout.scrollBottomInset(context)),
                itemBuilder: (_, i) {
                  if (i == items.length) {
                    return AppLoadMoreFooter(
                      hasMore: hasMore,
                      isLoading: loadingMore,
                      failed: controller.loadMoreFailed.value,
                      onLoadMore: controller.loadMoreNotifications,
                    );
                  }
                  final n = items[i];
                  return Dismissible(
                    key: ValueKey(n.id),
                    direction: DismissDirection.horizontal,
                    // بدونه يبقى العنصر المسحوب في الشجرة (خطأ Flutter في وضع التطوير).
                    onDismissed: (_) => controller.dismiss(n),
                    background: Container(
                      alignment: AlignmentDirectional.centerEnd,
                      padding: const EdgeInsetsDirectional.only(end: 20),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.shade100,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      onTap: () => controller.openNotification(n),
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
                itemCount: items.length + 1,
              ),
            ),
          );
        }),
      );
    });
  }
}
