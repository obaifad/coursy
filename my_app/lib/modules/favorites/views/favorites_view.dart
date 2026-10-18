import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/locale/locale_rebuild.dart';
import '../../../core/locale/plural.dart';
import '../../../core/models/app_models.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../core/services/favorites_service.dart';
import '../../../modules/auth/widgets/register_form_widgets.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_system_ui.dart';
import '../../../widgets/app_skeletons.dart';
import '../../../widgets/app_widgets.dart';
import '../../../widgets/design_system.dart';
import '../../../widgets/guest_access.dart';
import '../controllers/favorites_controller.dart';

/// صفحة المفضلة: رأس العلامة ينطوي مع التمرير، والدورات بطاقات صفّية مضغوطة بزر قلب لإزالتها.
class FavoritesView extends GetView<FavoritesController> {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = localeRebuildToken;
      final count = controller.courses.length;
      // رأس العلامة يمتد تحت شريط الحالة ويبقى مثبّتاً مطوياً.
      return AppStatusBar(
        lightIcons: true,
        child: Scaffold(
          backgroundColor: AppColors.surface,
          body: NestedScrollView(
            headerSliverBuilder: (context, _) => [
              AppBrandSliverAppBar(
                title: 'favorites_title'.tr,
                badge: count > 0 ? pluralTr('category_courses_count', count) : null,
                onBack: Navigator.canPop(context) ? Get.back : null,
              ),
            ],
            body: GuestGate(
              message: 'guest_favorites_hint'.tr,
              exploreCta: 'favorites_explore'.tr,
              onExplore: () {
                AppNavigation.switchToTab(0);
                Get.back();
              },
              child: _FavoritesBody(controller: controller),
            ),
          ),
        ),
      );
    });
  }
}

class _FavoritesBody extends StatelessWidget {
  const _FavoritesBody({required this.controller});

  final FavoritesController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hPad = AppLayout.readableInset(context);
      // لقطة واحدة لكل بناء: القائمة تبني عناصرها لاحقاً، وقراءة القائمة الحية بعد تغيّرها ترمي RangeError.
      final courses = controller.courses.toList(growable: false);

      if (controller.isLoading.value) {
        return CustomScrollView(
          physics: const NeverScrollableScrollPhysics(),
          slivers: [AppSliverGridSkeleton(padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 8), aurora: true)],
        );
      }

      if (courses.isEmpty && controller.errorMessage.value != null) {
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.loadFavorites,
          child: AppEmptyState.scrollable(
            context: context,
            message: controller.errorMessage.value!,
            icon: Icons.cloud_off_outlined,
            action: FilledButton(onPressed: controller.loadFavorites, child: Text('retry'.tr)),
          ),
        );
      }

      if (courses.isEmpty) {
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.loadFavorites,
          child: LayoutBuilder(
            builder: (context, constraints) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                SizedBox(
                  height: constraints.maxHeight,
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: AppLayout.readableInset(context, min: 24)),
                      child: AppEmptyState(
                        message: 'favorites_empty_title'.tr,
                        subtitle: 'favorites_empty'.tr,
                        icon: Icons.favorite_border_rounded,
                        iconSize: 52,
                        circleSize: 112,
                        action: SizedBox(
                          width: 220,
                          child: RegisterGradientButton(
                            label: 'favorites_explore'.tr,
                            onPressed: () {
                              AppNavigation.switchToTab(0);
                              if (Get.currentRoute == AppRoutes.favorites) Get.back();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: controller.loadFavorites,
        child: GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(hPad, 16, hPad, AppLayout.scrollBottomInset(context)),
          gridDelegate: AppGridLayouts.auroraGridFor(context),
          itemCount: courses.length,
          itemBuilder: (_, i) {
            final course = courses[i];
            return _FavoriteItem(key: ValueKey(course.id), course: course, controller: controller);
          },
        ),
      );
    });
  }
}

/// بطاقة الدورة الموحّدة (Aurora)؛ قلبها هنا يزيل الدورة (مع تلاشٍ وتراجع).
class _FavoriteItem extends StatefulWidget {
  const _FavoriteItem({super.key, required this.course, required this.controller});

  final CourseModel course;
  final FavoritesController controller;

  @override
  State<_FavoriteItem> createState() => _FavoriteItemState();
}

class _FavoriteItemState extends State<_FavoriteItem> {
  bool _leaving = false;

  Future<void> _remove() async {
    if (_leaving) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    HapticFeedback.selectionClick();
    setState(() => _leaving = true);
    // ندع التلاشي يظهر قبل حذف العنصر من القائمة.
    await Future<void>.delayed(const Duration(milliseconds: 240));
    final course = widget.course;
    await widget.controller.removeCourse(course);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          content: Text('favorite_removed'.tr),
          action: SnackBarAction(
            label: 'undo'.tr,
            onPressed: () => Get.find<FavoritesService>().toggleCourse(course.id),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    return AnimatedOpacity(
      opacity: _leaving ? 0 : 1,
      duration: const Duration(milliseconds: 220),
      child: AnimatedScale(
        scale: _leaving ? 0.92 : 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeIn,
        child: CourseAuroraCard(
          course: course,
          onTap: () => Get.toNamed(AppRoutes.courseDetails, arguments: course),
          onFavoritePressed: _leaving ? null : _remove,
        ),
      ),
    );
  }
}
