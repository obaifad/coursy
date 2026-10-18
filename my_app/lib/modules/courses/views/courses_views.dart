import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/locale/locale_rebuild.dart';
import '../../../core/models/app_models.dart';
import '../../../routes/app_routes.dart';
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
  const CoursesView({super.key, this.cardStyle = defaultCardStyle});

  /// تصميم بطاقات الدورات. للرجوع إلى بطاقات التذكرة الأفقية: [CourseCardStyle.boardingPass].
  static const CourseCardStyle defaultCardStyle = CourseCardStyle.auroraGlass;

  final CourseCardStyle cardStyle;

  @override
  Widget build(BuildContext context) => _CoursesScrollView(controller: controller, cardStyle: cardStyle);
}

class _CoursesScrollView extends StatefulWidget {
  const _CoursesScrollView({required this.controller, required this.cardStyle});

  final CoursesController controller;
  final CourseCardStyle cardStyle;

  @override
  State<_CoursesScrollView> createState() => _CoursesScrollViewState();
}

class _CoursesScrollViewState extends State<_CoursesScrollView> {
  /// الفراغ الذي يختفي عند النزول — مع مسافة انطواء الرأس يحدد متى يلتصق شريط الفلاتر (فيظهر ظله).
  static const double _filtersGap = 12;

  CoursesController get c => widget.controller;

  double _pinOffset() => AppBrandSliverAppBar.collapseDistance(context) + _filtersGap;

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
                badge: _countBadge(c.totalCount.value > c.courses.length ? c.totalCount.value : c.courses.length),
              ),
            ),
            // فراغ بين الرأس وشريط الفلاتر؛ يختفي بالنزول قبل أن يلتصق الشريط.
            const SliverToBoxAdapter(child: SizedBox(height: _filtersGap)),
            PinnedHeaderSliver(
              child: AppPinnedBar(
                scrollController: c.scrollController,
                pinOffset: _pinOffset,
                child: Obx(
                  () => Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // الترتيب أول عنصر في الصف: عند حافة البداية (يمين بالعربية، يسار بالإنجليزية) قبل
                      // التصنيفات، بلا عنوان «التصنيف» ولا صف مستقل. الصف يتبع Directionality فلا يُعكس يدوياً.
                      Padding(
                        padding: EdgeInsetsDirectional.only(start: hPad, end: 8),
                        child: CourseSortButton(selected: c.selectedSort.value, onSelected: c.selectSort),
                      ),
                      Expanded(
                        child: c.categories.isEmpty
                            ? const SizedBox(height: CourseSortButton.size)
                            : HorizontalCategoryFilters(
                                categories: c.categories.toList(growable: false),
                                selectedId: c.selectedCategoryId.value,
                                onSelected: c.selectCategory,
                                // الزر وحشوته يسبقانه: لا حشوة بداية مزدوجة (حشوة النهاية تبقى هامش الصفحة).
                                startInset: 0,
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
                // المشغّل هنا مستمع التمرير في المتحكم (ويحمّل كل الصفحات عند الترتيب)؛ الذيل يعرض الحالة فقط.
                child: AppLoadMoreFooter(
                  hasMore: false,
                  isLoading: c.isLoadingMore.value,
                  failed: c.loadMoreFailed.value,
                  onLoadMore: c.loadMoreCourses,
                  autoLoad: false,
                ),
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

    final aurora = widget.cardStyle == CourseCardStyle.auroraGlass;

    if (c.isLoading.value && c.courses.isEmpty) {
      return aurora
          ? AppSliverGridSkeleton(padding: gridPadding, aurora: true)
          : AppSliverBoardingSkeleton(padding: gridPadding);
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
    void open(CourseModel course) => Get.toNamed(AppRoutes.courseDetails, arguments: course);
    if (aurora) {
      return SliverPadding(
        padding: gridPadding,
        sliver: SliverGrid.builder(
          itemCount: courses.length,
          gridDelegate: AppGridLayouts.auroraGridFor(context),
          itemBuilder: (_, i) {
            final course = courses[i];
            return CourseAuroraCard(course: course, onTap: () => open(course));
          },
        ),
      );
    }
    return SliverPadding(
      padding: gridPadding,
      sliver: SliverList.separated(
        itemCount: courses.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final course = courses[i];
          return CourseBoardingCard(
            course: course,
            onTap: () => Get.toNamed(AppRoutes.courseDetails, arguments: course),
          );
        },
      ),
    );
  }
}

String? _countBadge(int count) => count > 0 ? pluralTr('category_courses_count', count) : null;
