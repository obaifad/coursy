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

class CourseDetailsView extends GetView<CourseDetailsController> {
  const CourseDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final item = controller.course.value;
      if (item == null) {
        return const Scaffold(body: CourseDetailsSkeleton());
      }
      return _CourseDetailsShell(
        key: ValueKey(item.id),
        item: item,
        detailsController: controller,
      );
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
  required CourseModel item,
  required bool showTitleInBar,
  required VoidCallback onFavorite,
}) {
  return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      forceElevated: showTitleInBar,
      title: AnimatedOpacity(
        opacity: showTitleInBar ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      actions: [
        Obx(() {
          final fav = Get.find<FavoritesService>();
          final isFav = fav.isCourseFavorite(item.id);
          return IconButton(
            onPressed: onFavorite,
            icon: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFav ? Colors.redAccent : null,
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
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.72),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 72, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.isFeatured)
                    _HeroBadge(
                      icon: Icons.star_rounded,
                      label: 'featured_course'.tr,
                      color: Colors.amber,
                    ),
                  const Spacer(),
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.institute,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
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
                          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
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
              SliverOverlapInjector(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
  bool shouldRebuild(covariant _CourseTabBarHeaderDelegate oldDelegate) =>
      oldDelegate.tabController != tabController;
}

class _CourseTabScrollBody extends StatelessWidget {
  const _CourseTabScrollBody({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}

class _AttributeBadges extends StatelessWidget {
  const _AttributeBadges({required this.item});
  final CourseModel item;

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[
      if (item.categoryName != null)
        _DetailBadge(
          icon: Icons.category_rounded,
          label: item.categoryName!,
          onTap: item.categoryId != null
              ? () => Get.toNamed(
                    AppRoutes.categoryCourses,
                    arguments: {'id': item.categoryId, 'name': item.categoryName},
                  )
              : null,
        ),
      if (item.studyType != null)
        _DetailBadge(icon: Icons.cast_for_education_rounded, label: item.studyType!),
      if (item.language != null && item.language!.isNotEmpty)
        _DetailBadge(icon: Icons.language_rounded, label: item.language!),
      _DetailBadge(
        icon: item.certificateAvailable ? Icons.verified_rounded : Icons.cancel_outlined,
        label: item.certificateAvailable ? 'course_certificate_yes'.tr : 'course_certificate_no'.tr,
        highlighted: item.certificateAvailable,
      ),
      if (item.isFeatured) _DetailBadge(icon: Icons.star_rounded, label: 'featured_course'.tr, highlighted: true),
      if (item.requiresAdvancePayment)
        _DetailBadge(icon: Icons.payments_outlined, label: 'course_advance_payment'.tr),
    ];

    if (badges.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(spacing: 8, runSpacing: 8, children: badges),
    );
  }
}

class _DetailBadge extends StatelessWidget {
  const _DetailBadge({
    required this.icon,
    required this.label,
    this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.primary.withValues(alpha: 0.1) : AppColors.indicatorFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted ? AppColors.primary.withValues(alpha: 0.25) : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: highlighted ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: highlighted ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return child;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: child);
  }
}

class _QuickStatsGrid extends StatelessWidget {
  const _QuickStatsGrid({required this.item});
  final CourseModel item;

  @override
  Widget build(BuildContext context) {
    final stats = <_StatItem>[
      if (item.durationHours != null && item.durationHours! > 0)
        _StatItem(Icons.schedule_rounded, 'hours_unit'.trParams({'n': '${item.durationHours}'})),
      if (item.sessionsCount != null && item.sessionsCount! > 0)
        _StatItem(Icons.event_note_rounded, 'sessions_unit'.trParams({'n': '${item.sessionsCount}'})),
      _StatItem(Icons.bar_chart_rounded, item.level),
      if (item.language != null && item.language!.isNotEmpty)
        _StatItem(Icons.translate_rounded, item.language!),
      if (item.studyType != null) _StatItem(Icons.laptop_mac_rounded, item.studyType!),
      _StatItem(Icons.groups_rounded, item.seatsLabel),
    ];

    if (stats.isEmpty) return const SizedBox.shrink();

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('course_stats_title'.tr, style: AppTypography.sectionTitle()),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stats.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 4.2,
            ),
            itemBuilder: (_, i) => _StatTile(stat: stats[i]),
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  const _StatItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.stat});
  final _StatItem stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.indicatorFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(stat.icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              stat.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, height: 1.15),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeatsProgressCard extends StatelessWidget {
  const _SeatsProgressCard({required this.item});
  final CourseModel item;

  @override
  Widget build(BuildContext context) {
    final max = item.maxStudents;
    final current = item.enrolledCountForCapacity;
    if (max == null || max <= 0) return const SizedBox.shrink();

    final progress = (current / max).clamp(0.0, 1.0);
    final remaining = (max - current).clamp(0, max);

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('course_capacity'.tr, style: AppTypography.sectionTitle()),
              const Spacer(),
              Text(
                'seats_available'.trParams({'n': '$remaining'}),
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'seats_filled'.trParams({'current': '$current', 'max': '$max'}),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (_, value, __) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: AppColors.indicatorFill,
                color: value > 0.85 ? Colors.orange : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseDateTimeline extends StatelessWidget {
  const _CourseDateTimeline({required this.item});
  final CourseModel item;

  @override
  Widget build(BuildContext context) {
    final steps = <_TimelineStep>[
      if (item.registrationDeadline != null)
        _TimelineStep(
          icon: Icons.hourglass_bottom_rounded,
          title: 'course_registration_deadline'.tr,
          date: JsonHelpers.formatDisplayDate(item.registrationDeadline),
        ),
      if (item.startDate != null)
        _TimelineStep(
          icon: Icons.play_circle_outline_rounded,
          title: 'course_start_date'.tr,
          date: JsonHelpers.formatDisplayDate(item.startDate),
        ),
      if (item.endDate != null)
        _TimelineStep(
          icon: Icons.flag_rounded,
          title: 'course_end_date'.tr,
          date: JsonHelpers.formatDisplayDate(item.endDate),
        ),
    ];

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('course_dates_title'.tr, style: AppTypography.sectionTitle()),
          const SizedBox(height: 16),
          ...List.generate(steps.length, (i) {
            final step = steps[i];
            final isLast = i == steps.length - 1;
            return _TimelineRow(step: step, showLine: !isLast);
          }),
        ],
      ),
    );
  }
}

class _TimelineStep {
  const _TimelineStep({required this.icon, required this.title, required this.date});
  final IconData icon;
  final String title;
  final String date;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.step, required this.showLine});
  final _TimelineStep step;
  final bool showLine;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(step.icon, size: 18, color: AppColors.primary),
              ),
              if (showLine)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: showLine ? 20 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(step.date, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.item});
  final CourseModel item;

  @override
  Widget build(BuildContext context) {
    return _CourseTabScrollBody(
      children: [
        _AttributeBadges(item: item),
        const SizedBox(height: 14),
        _QuickStatsGrid(item: item),
        const SizedBox(height: 14),
        _SeatsProgressCard(item: item),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'about_course'.tr,
          child: Text(
            item.description ?? 'no_description'.tr,
            style: const TextStyle(height: 1.55, fontSize: 15),
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'course_requirements'.tr,
          child: Text(
            (item.requirements != null && item.requirements!.trim().isNotEmpty)
                ? item.requirements!
                : 'no_requirements'.tr,
            style: const TextStyle(height: 1.55, fontSize: 15),
          ),
        ),
        if (item.institute.isNotEmpty) ...[
          const SizedBox(height: 16),
          _InstituteCard(item: item),
        ],
      ],
    );
  }
}

class _ScheduleTab extends GetView<CourseDetailsController> {
  const _ScheduleTab({required this.item});
  final CourseModel item;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final schedules = controller.schedules;
      return _CourseTabScrollBody(
        children: [
          if (_hasTimelineDates(item)) ...[
            _CourseDateTimeline(item: item),
            const SizedBox(height: 16),
          ],
          if (schedules.isEmpty)
            _SectionCard(
              title: 'schedule_title'.tr,
              child: Text('no_description'.tr, style: const TextStyle(color: AppColors.textSecondary)),
            )
          else
            _SectionCard(
              title: 'schedule_title'.tr,
              child: Column(
                children: schedules.map((s) => _ScheduleTile(schedule: s)).toList(),
              ),
            ),
        ],
      );
    });
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({required this.schedule});
  final ScheduleModel schedule;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.indicatorFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  JsonHelpers.weekdayLabel(schedule.dayOfWeek),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  '${schedule.startTime} - ${schedule.endTime}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructorTab extends StatelessWidget {
  const _InstructorTab({required this.item});
  final CourseModel item;

  @override
  Widget build(BuildContext context) {
    final instructor = item.instructor;
    if (instructor == null) {
      return _CourseTabScrollBody(
        children: [
          _SectionCard(
            title: 'tab_instructor'.tr,
            child: Text('no_description'.tr, style: const TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      );
    }

    return _CourseTabScrollBody(
      children: [
        SoftCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _InstructorAvatar(instructor: instructor),
              const SizedBox(height: 16),
              Text(instructor.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
              const SizedBox(height: 6),
              Text(
                instructor.specialization ?? 'instructor_default'.tr,
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'instructor_years'.trParams({
                  'role': instructor.specialization ?? 'instructor_default'.tr,
                  'years': '${instructor.experienceYears}',
                }),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              if (instructor.bio != null && instructor.bio!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(instructor.bio!, textAlign: TextAlign.center, style: const TextStyle(height: 1.55)),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Get.toNamed(AppRoutes.instructorDetails, arguments: instructor),
                  icon: const Icon(Icons.person_search_rounded, size: 18),
                  label: Text('view_instructor_profile'.tr),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Get.toNamed(AppRoutes.instructorCourses, arguments: instructor),
                  icon: const Icon(Icons.menu_book_rounded, size: 18),
                  label: Text('view_instructor_courses'.tr),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InstructorAvatar extends StatelessWidget {
  const _InstructorAvatar({required this.instructor});
  final InstructorModel instructor;

  @override
  Widget build(BuildContext context) {
    final url = instructor.resolvedImageUrl;
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 3),
        boxShadow: const [BoxShadow(color: AppColors.shadowSoft, blurRadius: 16, offset: Offset(0, 8))],
      ),
      child: ClipOval(
        child: url != null
            ? AppNetworkImage(url: url, fit: BoxFit.cover, ignorePointer: true)
            : Container(
                color: AppColors.indicatorFill,
                child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 42),
              ),
      ),
    );
  }
}

class _ReviewsTab extends GetView<CourseDetailsController> {
  const _ReviewsTab({required this.item});
  final CourseModel item;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final reviews = controller.reviews;
      final average = _reviewAverage(reviews);
      final distribution = _ratingDistribution(reviews);

      return _CourseTabScrollBody(
        children: [
          if (reviews.isNotEmpty) ...[
            SoftCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Text(
                        average.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                      Row(
                        children: List.generate(5, (i) {
                          return Icon(
                            i < average.round() ? Icons.star_rounded : Icons.star_border_rounded,
                            color: Colors.amber,
                            size: 18,
                          );
                        }),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'reviews_total'.trParams({'count': '${reviews.length}'}),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('rating_distribution'.tr, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        const SizedBox(height: 8),
                        ...List.generate(5, (i) {
                          final star = 5 - i;
                          final count = distribution[star] ?? 0;
                          final ratio = reviews.isEmpty ? 0.0 : count / reviews.length;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Text('$star', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: ratio,
                                      minHeight: 6,
                                      backgroundColor: AppColors.indicatorFill,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('$count', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('recent_reviews'.tr, style: AppTypography.sectionTitle()),
            const SizedBox(height: 10),
            ...reviews.take(8).map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ReviewCard(review: r),
                )),
          ] else
            _SectionCard(
              title: 'student_reviews'.tr,
              child: Text('no_description'.tr, style: const TextStyle(color: AppColors.textSecondary)),
            ),
          const SizedBox(height: 16),
          _ReviewFormSection(item: item),
        ],
      );
    });
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final ReviewModel review;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.indicatorFill,
                child: Text(
                  review.studentName.isNotEmpty ? review.studentName[0].toUpperCase() : '?',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.studentName.trim().isEmpty ? 'student'.tr : review.studentName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 14,
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(review.comment, style: const TextStyle(color: AppColors.textSecondary, height: 1.45)),
          ],
        ],
      ),
    );
  }
}

class _ReviewFormSection extends GetView<CourseDetailsController> {
  const _ReviewFormSection({required this.item});
  final CourseModel item;

  @override
  Widget build(BuildContext context) {
    if (!controller.isLoggedIn) return const SizedBox.shrink();

    if (controller.isCheckingEnrollment.value) {
      return _SectionCard(
        title: 'add_review'.tr,
        child: Skeletonizer(
          enabled: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 14, width: double.infinity, color: AppColors.indicatorFill),
              const SizedBox(height: 10),
              Container(height: 80, width: double.infinity, color: AppColors.indicatorFill),
            ],
          ),
        ),
      );
    }

    if (!controller.isEnrolled.value) {
      return _SectionCard(
        title: 'add_review'.tr,
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                controller.hasCourseEnrollment.value
                    ? 'review_completed_required'.tr
                    : 'review_not_enrolled_hint'.tr,
                style: const TextStyle(height: 1.4, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    if (controller.hasSubmittedReview.value) {
      return _SectionCard(
        title: 'add_review'.tr,
        child: Row(
          children: [
            const Icon(Icons.verified_rounded, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(child: Text('review_once_only'.tr, style: const TextStyle(color: AppColors.textSecondary))),
          ],
        ),
      );
    }

    return _SectionCard(
      title: 'add_review'.tr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RatingRow(label: 'rate_course'.tr, rating: controller.courseRating),
          if (item.instituteId != null) ...[
            const SizedBox(height: 8),
            _RatingRow(label: 'rate_institute'.tr, rating: controller.instituteRating),
          ],
          if (item.instructor != null) ...[
            const SizedBox(height: 8),
            _RatingRow(label: 'rate_instructor'.tr, rating: controller.instructorRating),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: controller.reviewCommentController,
            maxLines: 3,
            decoration: InputDecoration(hintText: 'review_comment_hint'.tr),
          ),
          const SizedBox(height: 12),
          Obx(
            () => SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: controller.isSubmittingReview.value ? null : controller.submitReviews,
                child: Text(controller.isSubmittingReview.value ? 'submitting_review'.tr : 'submit_review'.tr),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstituteCard extends StatelessWidget {
  const _InstituteCard({required this.item});
  final CourseModel item;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: item.instituteId != null
            ? () => Get.toNamed(AppRoutes.instituteDetails, arguments: item.instituteId)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('course_institute_section'.tr, style: AppTypography.sectionTitle()),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.school_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.institute, style: AppTypography.cardTitle()),
                      if (item.instituteCity != null)
                        Text(item.instituteCity!, style: AppTypography.cardSubtitle()),
                    ],
                  ),
                ),
                if (item.instituteId != null)
                  const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary),
              ],
            ),
            if (item.instituteAddress != null && item.instituteAddress!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _InstituteInfoLine(icon: Icons.place_outlined, text: item.instituteAddress!),
            ],
            if (item.institutePhone != null && item.institutePhone!.isNotEmpty)
              _InstituteInfoLine(icon: Icons.phone_outlined, text: item.institutePhone!),
          ],
        ),
      ),
    );
  }
}

class _InstituteInfoLine extends StatelessWidget {
  const _InstituteInfoLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: AppColors.textSecondary, height: 1.35))),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.sectionTitle()),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _StickyEnrollBar extends StatelessWidget {
  const _StickyEnrollBar({
    required this.item,
    required this.hasRegisteredEnrollment,
    required this.onBook,
    required this.onRegistrationClosed,
    required this.onFavorite,
  });

  final CourseModel item;
  final bool hasRegisteredEnrollment;
  final VoidCallback onBook;
  final VoidCallback onRegistrationClosed;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final registrationClosed = item.isRegistrationClosed;
    final alreadyRegistered = hasRegisteredEnrollment;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: const [
          BoxShadow(color: Color(0x336C63FF), blurRadius: 18, offset: Offset(0, -6)),
          BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _StickyPriceColumn(item: item),
              const SizedBox(width: 10),
              Obx(() {
                final fav = Get.find<FavoritesService>();
                final isFav = fav.isCourseFavorite(item.id);
                return Material(
                  color: isFav ? Colors.redAccent.withValues(alpha: 0.12) : AppColors.indicatorFill,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: InkWell(
                    onTap: onFavorite,
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 52,
                      height: 52,
                      child: Icon(
                        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFav ? Colors.redAccent : AppColors.primary,
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 10),
              Expanded(
                child: registrationClosed
                    ? OutlinedButton(
                        onPressed: onRegistrationClosed,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          foregroundColor: const Color(0xFF9C4A00),
                          side: const BorderSide(color: Color(0xFFFFD8A8)),
                          backgroundColor: const Color(0xFFFFF8F0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'registration_closed_action'.tr,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      )
                    : RegisterGradientButton(
                        label: alreadyRegistered ? 'enrollment_registered'.tr : 'book_now'.tr,
                        onPressed: alreadyRegistered ? null : onBook,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StickyStrikethroughPrice extends StatelessWidget {
  const _StickyStrikethroughPrice({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
    );

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        text,
        Positioned.fill(
          child: Align(
            alignment: Alignment.center,
            child: FractionallySizedBox(
              widthFactor: 1,
              child: Container(
                height: 1.1,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StickyPriceColumn extends StatelessWidget {
  const _StickyPriceColumn({required this.item});
  final CourseModel item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.hasDiscount && item.originalPriceLabel != null)
          _StickyStrikethroughPrice(label: item.originalPriceLabel!),
        CoursePriceText(price: item.price, amountSize: 20, currencySize: 12),
      ],
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.label, required this.rating});
  final String label;
  final RxInt rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
        Obx(
          () => Row(
            children: List.generate(5, (i) {
              final star = i + 1;
              return IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => rating.value = star,
                icon: Icon(
                  star <= rating.value ? Icons.star_rounded : Icons.star_border_rounded,
                  color: Colors.amber,
                  size: 22,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _CourseHeroImage extends StatelessWidget {
  const _CourseHeroImage({required this.imagePath});
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final url = ApiConfig.resolveMediaUrl(imagePath);
    if (url == null) return _fallback();
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.isFinite ? constraints.maxWidth : null;
        final h = constraints.maxHeight.isFinite ? constraints.maxHeight : null;
        return AppNetworkImage(
          url: url,
          width: w,
          height: h,
          fit: BoxFit.cover,
          ignorePointer: true,
          errorWidget: _fallback(),
        );
      },
    );
  }

  Widget _fallback() {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.category),
      child: const Center(child: Icon(Icons.school_rounded, color: Colors.white, size: 64)),
    );
  }
}

bool _hasTimelineDates(CourseModel item) {
  return item.registrationDeadline != null || item.startDate != null || item.endDate != null;
}

double _reviewAverage(List<ReviewModel> reviews) {
  if (reviews.isEmpty) return 0;
  return reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
}

Map<int, int> _ratingDistribution(List<ReviewModel> reviews) {
  final map = <int, int>{};
  for (final review in reviews) {
    map[review.rating] = (map[review.rating] ?? 0) + 1;
  }
  return map;
}
