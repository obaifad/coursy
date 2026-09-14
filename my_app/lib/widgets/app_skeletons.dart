import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../theme/app_colors.dart';
import 'design_system.dart';

class AppHomeSkeleton extends StatelessWidget {
  const AppHomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView(
        padding: EdgeInsetsDirectional.only(
          top: 4,
          bottom: 24,
          start: AppLayout.horizontalPage(context),
          end: AppLayout.horizontalPage(context),
        ),
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const AppHomeBrandLogo(height: 56),
                const AppIconCircleButton(onTap: _noop, icon: Icons.settings_outlined),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          const SizedBox(height: 22),
          Container(
            height: 168,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          const SizedBox(height: 22),
          const _SkeletonSectionHeader(),
          const SizedBox(height: 10),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, __) => Container(
                width: 116,
                height: 44,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const _SkeletonSectionHeader(),
          const SizedBox(height: 10),
          AppHorizontalListView(
            height: CourseCardMetrics.featuredListHeight(context),
            bottomInset: AppHorizontalListView.cardShadowBottomInset,
            separatorWidth: 12,
            itemCount: 2,
            itemBuilder: (_, __) => SizedBox(
              width: CourseCardMetrics.featuredCardWidth(context),
              height: CourseCardMetrics.featuredListHeight(context),
              child: const _SkeletonCourseCard(),
            ),
          ),
          const SizedBox(height: 22),
          const _SkeletonSectionHeader(),
          const SizedBox(height: 10),
          AppHorizontalListView(
            height: 200,
            separatorWidth: 12,
            itemCount: 2,
            itemBuilder: (_, __) => const SizedBox(width: 200, child: _SkeletonInstituteMiniCard()),
          ),
        ],
      ),
    );
  }
}

class AppGridSkeleton extends StatelessWidget {
  const AppGridSkeleton({super.key, this.itemCount = 6, this.padding = const EdgeInsets.all(16)});

  final int itemCount;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        itemCount: itemCount,
        gridDelegate: AppGridLayouts.courseGridFor(context),
        itemBuilder: (_, __) => const _SkeletonCourseCard(),
      ),
    );
  }
}

class AppListSkeleton extends StatelessWidget {
  const AppListSkeleton({super.key, this.itemCount = 6, this.padding = const EdgeInsets.all(16)});

  final int itemCount;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => const _SkeletonListTile(),
      ),
    );
  }
}

class AppDetailSkeleton extends StatelessWidget {
  const AppDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const CourseDetailsSkeleton();
  }
}

class CourseDetailsSkeleton extends StatelessWidget {
  const CourseDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(height: 320, color: AppColors.primary),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SkeletonTextBlock(width: 140),
                        const SizedBox(height: 12),
                        Container(
                          height: 48,
                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(
                      4,
                      (_) => Container(
                        width: 96,
                        height: 34,
                        decoration: BoxDecoration(color: AppColors.indicatorFill, borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SoftCard(
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.6,
                      children: List.generate(
                        4,
                        (_) => Container(
                          decoration: BoxDecoration(color: AppColors.indicatorFill, borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SkeletonTextBlock(width: 120),
                        const SizedBox(height: 12),
                        Container(
                          height: 10,
                          decoration: BoxDecoration(color: AppColors.indicatorFill, borderRadius: BorderRadius.circular(8)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 48,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: AppColors.indicatorFill, borderRadius: BorderRadius.circular(12)),
                ),
              ],
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                children: List.generate(3, (_) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: _SkeletonListTile(),
                    )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonCourseCard extends StatelessWidget {
  const _SkeletonCourseCard();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = CourseCardMetrics.layoutFor(constraints);
        final cardHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : layout.cardHeight;

        return SizedBox(
          height: cardHeight,
          width: constraints.maxWidth,
          child: SoftCard(
            padding: EdgeInsets.all(layout.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: layout.imageHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                SizedBox(height: layout.gapAfterImage),
                SizedBox(
                  height: layout.titleHeight,
                  child: const Align(
                    alignment: AlignmentDirectional.topStart,
                    child: Text(
                      'Course title placeholder',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                SizedBox(height: layout.gapAfterTitle),
                SizedBox(
                  height: layout.subtitleHeight,
                  child: const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text('Institute name', style: TextStyle(fontSize: 13)),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: layout.gapBeforeFooter),
                      SizedBox(
                        height: layout.chipsHeight,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.indicatorFill,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text('Online', style: TextStyle(fontSize: 11)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.indicatorFill,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text('24h', style: TextStyle(fontSize: 11)),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: layout.footerHeight,
                        child: Stack(
                          children: [
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('350000', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text('4.8', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                                  SizedBox(width: 3),
                                  Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SkeletonInstituteMiniCard extends StatelessWidget {
  const _SkeletonInstituteMiniCard();

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 88, decoration: const BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.vertical(top: Radius.circular(20)))),
          const Padding(
            padding: EdgeInsets.all(12),
            child: _SkeletonTextBlock(width: 150),
          ),
        ],
      ),
    );
  }
}

class _SkeletonListTile extends StatelessWidget {
  const _SkeletonListTile();

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Row(
        children: [
          Container(width: 72, height: 72, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16))),
          const SizedBox(width: 14),
          const Expanded(child: _SkeletonTextBlock(width: 180)),
        ],
      ),
    );
  }
}

class _SkeletonSectionHeader extends StatelessWidget {
  const _SkeletonSectionHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Text('Section title'),
        Spacer(),
        Text('Show all'),
      ],
    );
  }
}

class _SkeletonTextBlock extends StatelessWidget {
  const _SkeletonTextBlock({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Primary placeholder'),
          SizedBox(height: 8),
          Text('Secondary text'),
        ],
      ),
    );
  }
}

void _noop() {}
