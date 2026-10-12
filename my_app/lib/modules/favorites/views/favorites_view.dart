import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/locale/locale_rebuild.dart';
import '../../../core/locale/plural.dart';
import '../../../core/models/app_models.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../core/services/favorites_service.dart';
import '../../../core/storage/token_storage.dart';
import '../../../modules/auth/widgets/register_form_widgets.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_system_ui.dart';
import '../../../widgets/app_skeletons.dart';
import '../../../widgets/app_widgets.dart';
import '../../../widgets/design_system.dart';
import '../../../widgets/guest_access.dart';
import '../controllers/favorites_controller.dart';

/// صفحة المفضلة: هيدر بنفسجي موحّد + شبكة بطاقات الدورات نفسها المستخدمة في التطبيق.
/// الهيدر يتحرك مع البطاقات ويختفي عند النزول (كتبويب الدورات)؛ للضيف يبقى فوق دعوة الدخول.
class FavoritesView extends GetView<FavoritesController> {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = localeRebuildToken;
      final count = controller.courses.length;
      final header = AppHeroHeader(
        title: 'favorites_title'.tr,
        subtitle: 'favorites_subtitle'.tr,
        badge: count > 0 ? pluralTr('category_courses_count', count) : null,
        onBack: Navigator.canPop(context) ? Get.back : null,
      );
      // الرأس البنفسجي يمتد تحت شريط الحالة.
      return AppStatusBar(
        lightIcons: true,
        child: Scaffold(
          backgroundColor: AppColors.surface,
          body: Get.find<TokenStorage>().isLoggedIn
              ? _FavoritesBody(controller: controller, header: header)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    Expanded(
                      child: GuestGate(
                        message: 'guest_favorites_hint'.tr,
                        exploreCta: 'favorites_explore'.tr,
                        onExplore: () {
                          AppNavigation.switchToTab(0);
                          Get.back();
                        },
                        child: const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
        ),
      );
    });
  }
}

class _FavoritesBody extends StatelessWidget {
  const _FavoritesBody({required this.controller, required this.header});

  final FavoritesController controller;
  final Widget header;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hPad = AppLayout.horizontalPage(context);
      // لقطة واحدة لكل بناء: الشبكة تبني عناصرها لاحقاً، وقراءة القائمة الحية بعد تغيّرها ترمي RangeError.
      final courses = controller.courses.toList(growable: false);
      final error = controller.errorMessage.value;

      final Widget content;
      if (controller.isLoading.value) {
        content = AppSliverGridSkeleton(padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 8));
      } else if (courses.isEmpty && error != null) {
        content = SliverFillRemaining(
          hasScrollBody: false,
          child: AppEmptyState(
            message: error,
            icon: Icons.cloud_off_outlined,
            action: FilledButton(onPressed: controller.loadFavorites, child: Text('retry'.tr)),
          ),
        );
      } else if (courses.isEmpty) {
        content = SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppLayout.readableInset(context, min: 24), vertical: 24),
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
        );
      } else {
        content = SliverPadding(
          padding: EdgeInsets.fromLTRB(hPad, 16, hPad, AppLayout.scrollBottomInset(context)),
          sliver: SliverGrid.builder(
            itemCount: courses.length,
            gridDelegate: AppGridLayouts.courseGridFor(context),
            itemBuilder: (_, i) {
              final course = courses[i];
              return _FavoriteGridItem(key: ValueKey(course.id), course: course, controller: controller);
            },
          ),
        );
      }

      return AppScrollAwayHeaderView(onRefresh: controller.loadFavorites, header: header, slivers: [content]);
    });
  }
}

/// بطاقة الدورة الموحّدة؛ قلبها هنا يزيل الدورة (مع تلاشٍ وتراجع).
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
            onPressed: () => Get.find<FavoritesService>().toggleCourse(course.id, showFeedback: false),
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
        child: CourseCard(
          course: course,
          onTap: () => Get.toNamed(AppRoutes.courseDetails, arguments: course),
          onFavoritePressed: _remove,
        ),
      ),
    );
  }
}
