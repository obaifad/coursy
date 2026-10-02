import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../core/config/api_config.dart';
import '../../../core/locale/locale_rebuild.dart';
import '../../../core/models/app_models.dart';
import '../../../core/models/json_helpers.dart';
import '../../../core/services/favorites_service.dart';
import '../../../core/utils/course_registration_guard.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_skeletons.dart';
import '../../../widgets/app_widgets.dart';
import '../../../modules/auth/widgets/register_form_widgets.dart';
import '../../../widgets/design_system.dart';
import '../../../widgets/registration_closed_dialog.dart';
import '../controllers/course_details_controller.dart';
import '../../../core/locale/plural.dart';
import '../../../theme/app_motion.dart';

part 'course_details/header_widgets.dart';
part 'course_details/info_tabs.dart';
part 'course_details/reviews_tab.dart';
part 'course_details/enroll_bar.dart';

class CourseDetailsView extends GetView<CourseDetailsController> {
  const CourseDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final item = controller.course.value;
      if (item == null) {
        return const Scaffold(body: CourseDetailsSkeleton());
      }
      return _CourseDetailsShell(key: ValueKey(item.id), item: item, detailsController: controller);
    });
  }
}

class _CourseDetailsShell extends StatefulWidget {
  const _CourseDetailsShell({super.key, required this.item, required this.detailsController});

  final CourseModel item;
  final CourseDetailsController detailsController;

  @override
  State<_CourseDetailsShell> createState() => _CourseDetailsShellState();
}

class _CourseDetailsShellState extends State<_CourseDetailsShell> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ScrollController _scrollController;
  int _lastTabIndex = 0;

  CourseModel get item => widget.item;
  CourseDetailsController get controller => widget.detailsController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController = ScrollController();
    _lastTabIndex = _tabController.index;
    _tabController.addListener(_handleTabSelection);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == _lastTabIndex) return;
    _lastTabIndex = _tabController.index;
    _resetNestedScroll();
  }

  void _resetNestedScroll() {
    void clampAfterBuild([int attempt = 0]) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        final position = _scrollController.position;
        final clamped = position.pixels.clamp(position.minScrollExtent, position.maxScrollExtent);
        if ((position.pixels - clamped).abs() > 0.5) {
          position.jumpTo(clamped);
          if (attempt < 2) clampAfterBuild(attempt + 1);
        }
      });
    }

    clampAfterBuild();
  }

  Future<void> _openBooking() async {
    await CourseRegistrationGuard.openBooking(item);
    await controller.refreshEnrollment();
  }

  void _onRegistrationClosedTap() {
    RegistrationClosedDialog.show(item);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = localeRebuildToken;
      return Scaffold(
        backgroundColor: AppColors.surface,
        resizeToAvoidBottomInset: false,
        body: NestedScrollView(
          controller: _scrollController,
          physics: const ClampingScrollPhysics(),
          floatHeaderSlivers: true,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverMainAxisGroup(
                slivers: [
                  _buildCourseHeroSliver(
                    context: context,
                    item: item,
                    showTitleInBar: innerBoxIsScrolled,
                    onFavorite: controller.toggleFavorite,
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _CourseTabBarHeaderDelegate(tabController: _tabController),
                  ),
                ],
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            physics: const ClampingScrollPhysics(),
            children: [
              _CourseTabPage(
                storageKey: 'course_overview_${item.id}',
                child: Obx(
                  () => Skeletonizer(
                    enabled: controller.isLoading.value,
                    child: _OverviewTab(item: item),
                  ),
                ),
              ),
              _CourseTabPage(
                storageKey: 'course_schedule_${item.id}',
                child: Obx(
                  () => Skeletonizer(
                    enabled: controller.isLoading.value,
                    child: _ScheduleTab(item: item),
                  ),
                ),
              ),
              _CourseTabPage(
                storageKey: 'course_instructor_${item.id}',
                child: Obx(
                  () => Skeletonizer(
                    enabled: controller.isLoading.value,
                    child: _InstructorTab(item: item),
                  ),
                ),
              ),
              _CourseTabPage(
                storageKey: 'course_reviews_${item.id}',
                child: Obx(
                  () => Skeletonizer(
                    enabled: controller.isLoading.value,
                    child: _ReviewsTab(item: item),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Obx(
          () => _StickyEnrollBar(
            item: item,
            hasRegisteredEnrollment: controller.hasCourseEnrollment.value,
            onBook: _openBooking,
            onRegistrationClosed: _onRegistrationClosedTap,
            onFavorite: controller.toggleFavorite,
          ),
        ),
      );
    });
  }
}

/// يجب إرجاع [SliverAppBar] مباشرة داخل [headerSliverBuilder] وليس داخل Widget عادي.
SliverAppBar _buildCourseHeroSliver({
  required BuildContext context,
  required CourseModel item,
  required bool showTitleInBar,
  required VoidCallback onFavorite,
}) {
  // ارتفاع الغلاف يكبر مع تكبير الخط (إعدادات الجهاز، حتى 1.3×) — وإلا يفيض عنوان
  // من ثلاثة أسطر + اسم المعهد + صف التقييم عن الارتفاع الثابت.
  final expandedHeight = 320 * CourseCardMetrics.textScaleOf(context);
  return SliverAppBar(
    expandedHeight: expandedHeight,
    pinned: true,
    backgroundColor: AppColors.surface,
    surfaceTintColor: Colors.transparent,
    forceElevated: showTitleInBar,
    title: AnimatedOpacity(
      opacity: showTitleInBar ? 1 : 0,
      duration: AppMotion.fast,
      child: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
    actions: [
      Obx(() {
        final fav = Get.find<FavoritesService>();
        final isFav = fav.isCourseFavorite(item.id);
        return IconButton(
          onPressed: onFavorite,
          icon: Icon(
            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFav ? AppColors.danger : null,
          ),
        );
      }),
      const SizedBox(width: 4),
    ],
    flexibleSpace: FlexibleSpaceBar(
      background: Stack(
        fit: StackFit.expand,
        children: [
          _CourseHeroImage(imagePath: item.imageUrl),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withValues(alpha: 0.15), Colors.black.withValues(alpha: 0.72)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 72, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.isFeatured)
                  _HeroBadge(icon: Icons.star_rounded, label: 'featured_course'.tr, color: AppColors.ratingStar),
                const Spacer(),
                // ارتفاع الغلاف ثابت (320): العنوان محدود بثلاثة أسطر وأصغر على الهواتف،
                // وإلا دفع العنوان الطويل اسم المعهد والتقييم خارج الغلاف.
                Builder(
                  builder: (context) => Text(
                    item.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: MediaQuery.sizeOf(context).width < 480 ? 22 : 26,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      shadows: const [Shadow(color: Colors.black45, blurRadius: 8)],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.institute,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.ratingStar, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      item.rating.toStringAsFixed(1),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.people_alt_outlined, color: Colors.white70, size: 18),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.seatsLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _CourseTabPage extends StatelessWidget {
  const _CourseTabPage({required this.storageKey, required this.child});

  final String storageKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Builder(
        builder: (context) {
          return CustomScrollView(
            key: PageStorageKey<String>(storageKey),
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  AppLayout.readableInset(context),
                  12,
                  AppLayout.readableInset(context),
                  24,
                ),
                sliver: SliverToBoxAdapter(child: child),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CourseTabBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  _CourseTabBarHeaderDelegate({required this.tabController});

  final TabController tabController;

  static const double _height = AppTabBarSection.sectionHeight;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: AppColors.surface,
      elevation: overlapsContent ? 1.5 : 0,
      shadowColor: AppColors.primary.withValues(alpha: 0.15),
      child: SizedBox(
        height: AppTabBarSection.sectionHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
          child: AppSegmentedTabBar(
            controller: tabController,
            tabs: [
              Tab(text: 'tab_overview'.tr),
              Tab(text: 'tab_schedule'.tr),
              Tab(text: 'tab_instructor'.tr),
              Tab(text: 'tab_reviews'.tr),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CourseTabBarHeaderDelegate oldDelegate) => oldDelegate.tabController != tabController;
}

class _CourseTabScrollBody extends StatelessWidget {
  const _CourseTabScrollBody({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}
