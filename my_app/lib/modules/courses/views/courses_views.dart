import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/locale/locale_rebuild.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/app_widgets.dart';
import '../../../widgets/app_skeletons.dart';
import '../../../widgets/design_system.dart';
import '../../../widgets/filter_chips.dart';
import '../controllers/courses_controller.dart';
import '../../../core/locale/plural.dart';

/// الهيدر وعنوان التصنيف يتحركان مع الدورات ويختفيان عند النزول؛ شريط التصنيفات والترتيب يلتصق
/// بالأعلى. (كان كل الجزء العلوي ثابتاً ويأكل نحو 300px، فلا يبقى للدورات إلا نافذة صغيرة في المنتصف.)
class CoursesView extends GetView<CoursesController> {
  const CoursesView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppTabSafeArea(child: _CoursesScrollView(controller: controller));
  }
}

class _CoursesScrollView extends StatefulWidget {
  const _CoursesScrollView({required this.controller});

  final CoursesController controller;

  @override
  State<_CoursesScrollView> createState() => _CoursesScrollViewState();
}

class _CoursesScrollViewState extends State<_CoursesScrollView> {
  /// الجزء الذي يختفي عند النزول — ارتفاعه يحدد متى يصبح شريط الفلاتر ملتصقاً (فيظهر ظله).
  final _scrollAwayKey = GlobalKey();

  CoursesController get c => widget.controller;

  double _pinOffset() {
    final box = _scrollAwayKey.currentContext?.findRenderObject() as RenderBox?;
    return box != null && box.hasSize ? box.size.height : double.infinity;
  }

  @override
  Widget build(BuildContext context) {
    final hPad = AppLayout.horizontalPage(context);
    return RefreshIndicator(
      onRefresh: c.loadCourses,
      child: Obx(() {
        final _ = localeRebuildToken;
        return CustomScrollView(
          controller: c.scrollController,
          key: const PageStorageKey('courses_tab'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                key: _scrollAwayKey,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Obx(
                    () => AppHeroHeader(
                      title: 'all_courses'.tr,
                      subtitle: 'browse_courses'.tr,
                      badge: _countBadge(c.totalCount.value > c.courses.length ? c.totalCount.value : c.courses.length),
                    ),
                  ),
                  const SizedBox(height: 10),
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
              child: AppPinnedBar(
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
      return AppSliverGridSkeleton(padding: gridPadding);
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
        gridDelegate: AppGridLayouts.courseGridFor(context),
        itemBuilder: (_, i) {
          final course = courses[i];
          return CourseCard(
            course: course,
            onTap: () => Get.toNamed(AppRoutes.courseDetails, arguments: course),
          );
        },
      ),
    );
  }
}

String? _countBadge(int count) => count > 0 ? pluralTr('category_courses_count', count) : null;
