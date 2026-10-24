import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/locale/locale_rebuild.dart';
import '../../../core/models/app_models.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_system_ui.dart';
import '../../../widgets/app_skeletons.dart';
import '../../../widgets/app_widgets.dart';
import '../../../widgets/design_system.dart';
import '../../../widgets/filter_chips.dart';
import '../../../widgets/skeleton_switch.dart';
import '../../../modules/auth/widgets/register_form_widgets.dart';
import '../controllers/category_courses_controller.dart';
import '../../../core/locale/plural.dart';

/// صفحة دورات تصنيف. التفاعلية مقسّمة إلى ثلاثة `Obx` صغيرة بدل واحدة تلفّ الصفحة كلها (كانت تقرأ نحو
/// تسع قيم، فأي تغيّر فيها — كعدّاد «المزيد» أو العنوان — يعيد بناء الشبكة كلها):
///  - الرأس: العنوان وعدد الدورات.
///  - المحتوى: الهيكل/الخطأ/الفراغ/الشبكة وصف الترتيب.
///  - ذيل «تحميل المزيد»: حالته وحدها.
class CategoryCoursesView extends GetView<CategoryCoursesController> {
  const CategoryCoursesView({super.key});

  @override
  Widget build(BuildContext context) {
    // رأس العلامة يمتد تحت شريط الحالة ويبقى مثبّتاً مطوياً — أيقونات بيضاء في كل حالات التمرير.
    return AppStatusBar(
      lightIcons: true,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.loadCourses,
          edgeOffset: MediaQuery.paddingOf(context).top + AppBrandSliverAppBar.toolbarHeight,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _Header(controller: controller),
              _Content(controller: controller),
              _LoadMoreFooter(controller: controller),
              SliverToBoxAdapter(child: SizedBox(height: AppLayout.scrollBottomInset(context))),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});

  final CategoryCoursesController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = localeRebuildToken;
      final count = controller.displayCount;
      return AppBrandSliverAppBar(
        title: controller.title.value,
        badge: count == 0 ? null : pluralTr('category_courses_count', count),
        onBack: Get.back,
      );
    });
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.controller});

  final CategoryCoursesController controller;

  @override
  Widget build(BuildContext context) {
    final hPad = AppLayout.horizontalPage(context);
    return Obx(() {
      final _ = localeRebuildToken;
      final loading = controller.isLoading.value;
      final sort = controller.selectedSort.value;
      // لقطة ثابتة لهذا البناء: الشبكة تبني عناصرها لاحقاً، وقراءة القائمة الحية بعد تغيّرها ترمي RangeError.
      final courses = loading ? const <CourseModel>[] : controller.courses.toList(growable: false);
      final error = loading ? null : controller.errorMessage.value;
      return AppSkeletonSwitch(
        sliver: true,
        loading: loading,
        skeleton: SliverMainAxisGroup(
          slivers: [
            // مكان صف الترتيب محجوز (غير مرئي) كي لا تنزل الشبكة عند وصول البيانات.
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
                child: Visibility(
                  visible: false,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: CourseSortDropdown(selected: sort, onSelected: (_) {}),
                ),
              ),
            ),
            AppSliverGridSkeleton(padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0), aurora: true),
          ],
        ),
        contentBuilder: (context) => SliverMainAxisGroup(
          slivers: [
            if (courses.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
                  child: CourseSortDropdown(selected: sort, onSelected: controller.selectSort),
                ),
              ),
            if (courses.isEmpty && error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AppLoadErrorState(message: error, onRetry: controller.loadCourses),
              )
            else if (courses.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AppEmptyState(
                  message: 'no_courses_in_category'.tr,
                  subtitle: 'browse_courses'.tr,
                  icon: Icons.category_outlined,
                  action: SizedBox(
                    width: 200,
                    child: RegisterGradientButton(label: 'browse_courses'.tr, onPressed: () => Get.back()),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                sliver: SliverGrid(
                  gridDelegate: AppGridLayouts.auroraGridFor(context),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => CourseAuroraCard(
                      key: ValueKey(courses[i].id),
                      course: courses[i],
                      onTap: () => Get.toNamed(AppRoutes.courseDetails, arguments: courses[i]),
                    ),
                    childCount: courses.length,
                    findChildIndexCallback: (key) {
                      final id = (key as ValueKey<int>).value;
                      final index = courses.indexWhere((c) => c.id == id);
                      return index < 0 ? null : index;
                    },
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({required this.controller});

  final CategoryCoursesController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value || controller.courses.isEmpty) {
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      }
      return SliverToBoxAdapter(
        child: AppLoadMoreFooter(
          hasMore: controller.hasMore.value,
          isLoading: controller.isLoadingMore.value,
          failed: controller.loadMoreFailed.value,
          onLoadMore: controller.loadMore,
        ),
      );
    });
  }
}
