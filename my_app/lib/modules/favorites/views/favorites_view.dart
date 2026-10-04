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
import '../../../widgets/app_skeletons.dart';
import '../../../widgets/app_widgets.dart';
import '../../../widgets/design_system.dart';
import '../../../widgets/guest_access.dart';
import '../controllers/favorites_controller.dart';

/// صفحة المفضلة: هيدر بنفسجي موحّد + شبكة بطاقات الدورات نفسها المستخدمة في التطبيق.
class FavoritesView extends GetView<FavoritesController> {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = localeRebuildToken;
      final count = controller.courses.length;
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeroHeader(
              title: 'favorites_title'.tr,
              subtitle: 'favorites_subtitle'.tr,
              badge: count > 0 ? pluralTr('category_courses_count', count) : null,
              onBack: Navigator.canPop(context) ? Get.back : null,
            ),
            Expanded(
              child: GuestGate(
                message: 'guest_favorites_hint'.tr,
                exploreCta: 'favorites_explore'.tr,
                onExplore: () {
                  AppNavigation.switchToTab(0);
                  Get.back();
                },
                child: _FavoritesBody(controller: controller),
              ),
            ),
          ],
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
      final hPad = AppLayout.horizontalPage(context);

      if (controller.isLoading.value) {
        return AppGridSkeleton(padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 8));
      }

      if (controller.courses.isEmpty) {
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
          itemCount: controller.courses.length,
          gridDelegate: AppGridLayouts.courseGridFor(context),
          itemBuilder: (_, i) {
            final course = controller.courses[i];
            return _FavoriteGridItem(key: ValueKey(course.id), course: course, controller: controller);
          },
        ),
      );
    });
  }
}

/// بطاقة الدورة الموحّدة + زر قلب دائري فوق الغلاف لإزالتها (مع تلاشٍ وتراجع).
class _FavoriteGridItem extends StatefulWidget {
  const _FavoriteGridItem({super.key, required this.course, required this.controller});

  final CourseModel course;
  final FavoritesController controller;

  @override
  State<_FavoriteGridItem> createState() => _FavoriteGridItemState();
}

class _FavoriteGridItemState extends State<_FavoriteGridItem> {
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
        child: Stack(
          children: [
            Positioned.fill(
              child: CourseCard(
                course: course,
                showActionButton: false,
                onTap: () => Get.toNamed(AppRoutes.courseDetails, arguments: course),
              ),
            ),
            PositionedDirectional(
              top: 8,
              end: 8,
              child: Material(
                color: Colors.white.withValues(alpha: 0.94),
                shape: const CircleBorder(),
                elevation: 2,
                shadowColor: Colors.black26,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _leaving ? null : _remove,
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(Icons.favorite_rounded, color: AppColors.danger, size: 20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
