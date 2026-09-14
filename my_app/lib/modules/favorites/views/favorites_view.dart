import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/locale/locale_rebuild.dart';
import '../../../core/models/app_models.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_widgets.dart';
import '../../../widgets/app_skeletons.dart';
import '../../../widgets/design_system.dart';
import '../../../widgets/guest_access.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../modules/auth/widgets/register_form_widgets.dart';
import '../controllers/favorites_controller.dart';

class FavoritesView extends GetView<FavoritesController> {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = localeRebuildToken;
      return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _FavoritesAppBar(onRefresh: controller.loadFavorites),
      body: GuestGate(
        message: 'guest_favorites_hint'.tr,
        exploreCta: 'favorites_explore'.tr,
        onExplore: () {
          AppNavigation.switchToTab(0);
          Get.back();
        },
        child: _FavoritesBody(controller: controller),
      ),
    );
    });
  }
}

class FavoritesTabView extends GetView<FavoritesController> {
  const FavoritesTabView({super.key});

  @override
  Widget build(BuildContext context) {
    FavoritesController.ensureRegistered();
    return ColoredBox(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppScreenHeader(
              title: 'favorites_title'.tr,
              subtitle: 'favorites_subtitle'.tr,
              logoInline: true,
              logoHeight: 44,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: controller.loadFavorites,
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'retry'.tr,
                  ),
                  TextButton(
                    onPressed: () => Get.toNamed(AppRoutes.favorites),
                    child: Text('view_all'.tr, style: GoogleFonts.tajawal(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            Expanded(child: _FavoritesBody(controller: controller, compactTop: true)),
          ],
        ),
      ),
    );
  }
}

class _FavoritesAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _FavoritesAppBar({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      leading: Navigator.canPop(context)
          ? IconButton(
              onPressed: Get.back,
              icon: const Icon(Icons.arrow_back_rounded),
            )
          : null,
      title: const AppLogo(height: 60,),
      actions: [
        IconButton(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'retry'.tr,
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

class _FavoritesBody extends StatelessWidget {
  const _FavoritesBody({required this.controller, this.compactTop = false});

  final FavoritesController controller;
  final bool compactTop;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const AppListSkeleton(itemCount: 4);
      }

      if (controller.courses.isEmpty) {
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.loadFavorites,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              SizedBox(height: MediaQuery.sizeOf(context).height * 0.12),
              AppEmptyState(
                message: 'favorites_empty'.tr,
                icon: Icons.favorite_border_rounded,
                iconSize: 56,
                circleSize: 120,
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
            ],
          ),
        );
      }

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: controller.loadFavorites,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20, compactTop ? 8 : 16, 20, 24),
          itemCount: controller.courses.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (_, i) {
            final course = controller.courses[i];
            return _FavoriteCourseCard(
              course: course,
              controller: controller,
            );
          },
        ),
      );
    });
  }
}

class _FavoriteCourseCard extends StatefulWidget {
  const _FavoriteCourseCard({required this.course, required this.controller});

  final CourseModel course;
  final FavoritesController controller;

  @override
  State<_FavoriteCourseCard> createState() => _FavoriteCourseCardState();
}

class _FavoriteCourseCardState extends State<_FavoriteCourseCard> with SingleTickerProviderStateMixin {
  late final AnimationController _heartController;
  late final Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      lowerBound: 0.85,
      upperBound: 1.15,
    );
    _heartScale = CurvedAnimation(parent: _heartController, curve: Curves.elasticOut);
    _heartController.value = 1;
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  Future<void> _removeFavorite() async {
    _heartController.forward(from: 0.85).then((_) => _heartController.reverse());
    await widget.controller.removeCourse(widget.course);
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    final removing = widget.controller.removingIds.contains(course.id);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Get.toNamed(AppRoutes.courseDetails, arguments: course),
        borderRadius: BorderRadius.circular(CourseCardMetrics.cardRadius),
        splashColor: AppColors.primary.withValues(alpha: 0.08),
        highlightColor: AppColors.primary.withValues(alpha: 0.04),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(CourseCardMetrics.cardRadius),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FavoriteCardImage(
                course: course,
                removing: removing,
                heartScale: _heartScale,
                onRemove: removing ? null : _removeFavorite,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.cardTitle(size: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      course.institute,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.cardSubtitle(size: 14),
                    ),
                    if (course.studyType != null || course.durationHours != null) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (course.studyType != null)
                            _FavoriteMetaChip(icon: Icons.cast_for_education_outlined, label: course.studyType!),
                          if (course.durationHours != null && course.durationHours! > 0)
                            _FavoriteMetaChip(
                              icon: Icons.schedule_rounded,
                              label: 'hours_unit'.trParams({'n': '${course.durationHours}'}),
                            ),
                          _FavoriteMetaChip(icon: Icons.bar_chart_rounded, label: course.level),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        if (course.rating > 0) ...[
                          const Icon(Icons.star_rounded, size: 18, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 4),
                          Text(
                            course.rating.toStringAsFixed(1),
                            style: GoogleFonts.tajawal(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF92400E),
                            ),
                          ),
                          const Spacer(),
                        ] else
                          const Spacer(),
                        CoursePriceText(price: course.price, amountSize: 16, currencySize: 11),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteCardImage extends StatelessWidget {
  const _FavoriteCardImage({
    required this.course,
    required this.removing,
    required this.heartScale,
    required this.onRemove,
  });

  final CourseModel course;
  final bool removing;
  final Animation<double> heartScale;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final url = course.resolvedImageUrl;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SizedBox(
        height: 140,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url != null)
              AppNetworkImage(
                url: url,
                width: double.infinity,
                height: 140,
                fit: BoxFit.cover,
                ignorePointer: true,
              )
            else
              const DecoratedBox(
                decoration: BoxDecoration(gradient: AppGradients.cardPlaceholder),
                child: Center(
                  child: Icon(Icons.school_rounded, color: Colors.white70, size: 44),
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.28)],
                ),
              ),
            ),
            PositionedDirectional(
              top: 12,
              end: 12,
              child: Material(
                color: Colors.white,
                elevation: 4,
                shadowColor: AppColors.primary.withValues(alpha: 0.25),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onRemove,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: Center(
                      child: removing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: AppInlineLoader(),
                            )
                          : ScaleTransition(
                              scale: heartScale,
                              child: const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 22),
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
}

class _FavoriteMetaChip extends StatelessWidget {
  const _FavoriteMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.indicatorFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
          ),
        ],
      ),
    );
  }
}
