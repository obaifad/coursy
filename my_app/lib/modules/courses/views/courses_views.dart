import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/locale/locale_rebuild.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_widgets.dart';
import '../../../widgets/app_skeletons.dart';
import '../../../widgets/design_system.dart';
import '../../../widgets/filter_chips.dart';
import '../controllers/courses_controller.dart';
import '../../../core/locale/plural.dart';

/// رأس العلامة ينطوي إلى شريط أدوات مثبّت عند النزول، وعنوان التصنيف يختفي معه؛ شريط التصنيفات والترتيب
/// يلتصق تحت الرأس المطوي. (كان كل الجزء العلوي ثابتاً ويأكل نحو 300px، فلا يبقى للدورات إلا نافذة صغيرة.)
/// الرأس البنفسجي يمتد تحت شريط الحالة بنفسه — لذلك بلا SafeArea علوية.
class CoursesView extends GetView<CoursesController> {
  const CoursesView({super.key});

  @override
  Widget build(BuildContext context) => _CoursesScrollView(controller: controller);
}

class _CoursesScrollView extends StatefulWidget {
  const _CoursesScrollView({required this.controller});

  final CoursesController controller;

  @override
  State<_CoursesScrollView> createState() => _CoursesScrollViewState();
}

class _CoursesScrollViewState extends State<_CoursesScrollView> {
  /// عنوان «التصنيفات» الذي يختفي عند النزول — مع مسافة انطواء الرأس يحدد متى يلتصق شريط الفلاتر (فيظهر ظله).
  final _scrollAwayKey = GlobalKey();

  CoursesController get c => widget.controller;

  double _pinOffset() {
    final box = _scrollAwayKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return double.infinity;
    return AppBrandSliverAppBar.collapseDistance(context) + box.size.height;
  }

  @override
  Widget build(BuildContext context) {
    final hPad = AppLayout.horizontalPage(context);
    return RefreshIndicator(
      onRefresh: c.loadCourses,
      // المؤشر تحت شريط الأدوات المثبّت لا خلفه.
      edgeOffset: MediaQuery.paddingOf(context).top + AppBrandSliverAppBar.toolbarHeight,
      child: Obx(() {
        final _ = localeRebuildToken;
        return CustomScrollView(
          controller: c.scrollController,
          key: const PageStorageKey('courses_tab'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            Obx(
              () => AppBrandSliverAppBar(
                title: 'all_courses'.tr,
                subtitle: 'browse_courses'.tr,
                badge: _countBadge(c.totalCount.value > c.courses.length ? c.totalCount.value : c.courses.length),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                key: _scrollAwayKey,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 14),
                  Obx(
                    () => c.categories.isEmpty
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(hPad, 0, hPad, 0),
                            child: Text('filter_categories'.tr, style: AppTypography.filterSectionLabel()),
                          ),
                  ),
                ],
              ),
            ),
            PinnedHeaderSliver(
              child: _PinnedFiltersBar(
                scrollController: c.scrollController,
                pinOffset: _pinOffset,
                child: Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (c.categories.isNotEmpty) ...[
                        HorizontalCategoryFilters(
                          categories: c.categories.toList(growable: false),
                          selectedId: c.selectedCategoryId.value,
                          onSelected: c.selectCategory,
                        ),
                        const SizedBox(height: 10),
                      ],
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(hPad, 0, hPad, 0),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: CourseSortDropdown(selected: c.selectedSort.value, onSelected: c.selectSort),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Obx(() => _content(context, hPad)),
            Obx(
              () => SliverToBoxAdapter(
                child: c.isLoadingMore.value
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: AppInlineLoader()),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: AppLayout.scrollBottomInset(context, rootTab: true))),
          ],
        );
      }),
    );
  }

  Widget _content(BuildContext context, double hPad) {
    // لقطة واحدة لكل بناء: عدد العناصر والعناصر نفسها من القائمة ذاتها — قراءة القائمة الحية داخل
    // itemBuilder بعد تغيّرها كانت ترمي RangeError.
    final courses = c.sortedCourses.toList(growable: false);
    final error = c.errorMessage.value;
    final gridPadding = EdgeInsets.fromLTRB(hPad, 12, hPad, 0);

    if (c.isLoading.value && c.courses.isEmpty) {
      return AppSliverGridSkeleton(padding: gridPadding, poster: true);
    }
    if (courses.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: error != null
            ? AppEmptyState(
                message: error,
                icon: Icons.cloud_off_outlined,
                action: FilledButton(onPressed: c.loadCourses, child: Text('retry'.tr)),
              )
            : AppEmptyState(message: 'no_courses'.tr, icon: Icons.menu_book_outlined),
      );
    }
    return SliverPadding(
      padding: gridPadding,
      sliver: SliverGrid.builder(
        itemCount: courses.length,
        gridDelegate: AppGridLayouts.posterGridFor(context),
        itemBuilder: (_, i) {
          final course = courses[i];
          return CoursePosterCard(
            course: course,
            onTap: () => Get.toNamed(AppRoutes.courseDetails, arguments: course),
          );
        },
      ),
    );
  }
}

/// خلفية الصفحة تحت شريط الفلاتر (فلا تظهر البطاقات من خلفه)، وظل خفيف فقط حين يلتصق بالأعلى
/// والدورات تمرّ تحته — فيبدو الفاصل مقصوداً بدل حافة مقطوعة.
class _PinnedFiltersBar extends StatefulWidget {
  const _PinnedFiltersBar({required this.scrollController, required this.pinOffset, required this.child});

  final ScrollController scrollController;
  final double Function() pinOffset;
  final Widget child;

  @override
  State<_PinnedFiltersBar> createState() => _PinnedFiltersBarState();
}

class _PinnedFiltersBarState extends State<_PinnedFiltersBar> {
  bool _pinned = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_update);
  }

  @override
  void didUpdateWidget(_PinnedFiltersBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_update);
      widget.scrollController.addListener(_update);
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_update);
    super.dispose();
  }

  void _update() {
    final sc = widget.scrollController;
    final pinned = sc.hasClients && sc.offset >= widget.pinOffset() - 0.5;
    if (pinned != _pinned) setState(() => _pinned = pinned);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: _pinned ? 0.10 : 0),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: widget.child,
    );
  }
}

String? _countBadge(int count) => count > 0 ? pluralTr('category_courses_count', count) : null;
