import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_skeletons.dart';
import '../../../widgets/design_system.dart';
import '../controllers/instructor_subject_instructors_controller.dart';

class InstructorSubjectInstructorsView extends GetView<InstructorSubjectInstructorsController> {
  const InstructorSubjectInstructorsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading = controller.isLoading.value;
      final instructors = controller.instructors;
      final title = controller.title.value;
      final count = controller.instructorsCount.value;

      return Scaffold(
        backgroundColor: AppColors.surface,
        body: isLoading
            ? const AppListSkeleton(itemCount: 4)
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: controller.loadInstructors,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    _SubjectHeroHeader(title: title, instructorsCount: count),
                    if (controller.errorMessage.value != null && instructors.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              controller.errorMessage.value!,
                              textAlign: TextAlign.center,
                              style: AppTypography.pageSubtitle(),
                            ),
                          ),
                        ),
                      )
                    else if (instructors.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'no_instructors_in_subject'.tr,
                              textAlign: TextAlign.center,
                              style: AppTypography.pageSubtitle(),
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: AppLayout.scrollPadding(context),
                        sliver: SliverList.separated(
                          itemCount: instructors.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final item = instructors[i];
                            return PrivateInstructorListCard(
                              instructor: item,
                              onTap: () => Get.toNamed(AppRoutes.instructorDetails, arguments: item),
                            );
                          },
                        ),
                      ),
                    if (!isLoading && instructors.isNotEmpty && controller.hasMore.value)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            AppLayout.horizontalPage(context),
                            12,
                            AppLayout.horizontalPage(context),
                            AppLayout.scrollBottomInset(context),
                          ),
                          child: Obx(() {
                            final loadingMore = controller.isLoadingMore.value;
                            return OutlinedButton.icon(
                              onPressed: loadingMore ? null : controller.loadMore,
                              icon: loadingMore
                                  ? const AppInlineLoader()
                                  : const Icon(Icons.expand_more_rounded),
                              label: Text('load_more'.tr),
                            );
                          }),
                        ),
                      )
                    else
                      SliverToBoxAdapter(child: SizedBox(height: AppLayout.scrollBottomInset(context))),
                  ],
                ),
              ),
      );
    });
  }
}

class _SubjectHeroHeader extends StatelessWidget {
  const _SubjectHeroHeader({required this.title, required this.instructorsCount});

  final String title;
  final int instructorsCount;

  @override
  Widget build(BuildContext context) {
    final hPad = AppLayout.horizontalPage(context);
    final compact = MediaQuery.sizeOf(context).height < 700;
    final titleSize = compact ? 22.0 : 24.0;

    return SliverToBoxAdapter(
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppGradients.heroBanner),
          child: Stack(
            children: [
              const BrandBannerPattern(),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.38),
                    ],
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(8, 4, hPad, compact ? 16 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: Get.back,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                      SizedBox(height: compact ? 6 : 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          'instructor_subject_count'.trParams({'count': '$instructorsCount'}),
                          style: GoogleFonts.tajawal(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.tajawal(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: titleSize,
                          height: 1.2,
                        ),
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 4),
                        Text(
                          'instructor_subject_subtitle'.tr,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.tajawal(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
