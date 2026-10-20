import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../core/models/app_models.dart';
import 'app_widgets.dart';
import 'design_system.dart';

class AppHomeSkeleton extends StatelessWidget {
  const AppHomeSkeleton({super.key, this.banner});

  /// مكان البانر بمقاسه الحقيقي (بانر الطالب أطول من بطاقة الزائر) — كي لا تقفز الصفحة عند وصول البيانات.
  final Widget? banner;

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
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md)),
          ),
          const SizedBox(height: 22),
          banner ??
              Container(
                height: 168,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.lg)),
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
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md)),
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
            height: InstituteMiniCard.railHeight(context),
            separatorWidth: 12,
            itemCount: 2,
            itemBuilder: (_, __) => const SizedBox(width: InstituteMiniCard.width, child: _SkeletonInstituteMiniCard()),
          ),
        ],
      ),
    );
  }
}

class AppGridSkeleton extends StatelessWidget {
  const AppGridSkeleton({
    super.key,
    this.itemCount = 6,
    this.padding = const EdgeInsets.all(16),
    this.poster = false,
    this.aurora = false,
  });

  final int itemCount;
  final EdgeInsetsGeometry padding;

  /// هيكل بطاقات «الملصق» ([CoursePosterCard]) بدل بطاقة التذكرة.
  final bool poster;

  /// هيكل بطاقات «Aurora Glass» ([CourseAuroraCard]) — يتقدّم على [poster].
  final bool aurora;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        itemCount: itemCount,
        gridDelegate: _skeletonGridDelegate(context, aurora: aurora, poster: poster),
        itemBuilder: (_, __) => _skeletonGridCard(aurora: aurora, poster: poster),
      ),
    );
  }
}

/// نفس [AppGridSkeleton] لكن كـ sliver، داخل CustomScrollView لصفحة يتحرك هيدرها مع المحتوى.
class AppSliverGridSkeleton extends StatelessWidget {
  const AppSliverGridSkeleton({
    super.key,
    this.itemCount = 6,
    this.padding = const EdgeInsets.all(16),
    this.poster = false,
    this.aurora = false,
  });

  final int itemCount;
  final EdgeInsetsGeometry padding;

  /// هيكل بطاقات «الملصق» ([CoursePosterCard]) بدل بطاقة التذكرة.
  final bool poster;

  /// هيكل بطاقات «Aurora Glass» ([CourseAuroraCard]) — يتقدّم على [poster].
  final bool aurora;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer.sliver(
      enabled: true,
      child: SliverPadding(
        padding: padding,
        sliver: SliverGrid.builder(
          itemCount: itemCount,
          gridDelegate: _skeletonGridDelegate(context, aurora: aurora, poster: poster),
          itemBuilder: (_, __) => _skeletonGridCard(aurora: aurora, poster: poster),
        ),
      ),
    );
  }
}

/// نفس شبكة البطاقة الحقيقية (أعمدة وارتفاع) — لا قفزة عند وصول البيانات.
SliverGridDelegate _skeletonGridDelegate(BuildContext context, {required bool aurora, required bool poster}) {
  if (aurora) return AppGridLayouts.auroraGridFor(context);
  return poster ? AppGridLayouts.posterGridFor(context) : AppGridLayouts.courseGridFor(context);
}

Widget _skeletonGridCard({required bool aurora, required bool poster}) {
  if (aurora) return const _SkeletonAuroraCard();
  return poster ? const _SkeletonPosterCard() : const _SkeletonCourseCard();
}

/// هيكل صفحة كل الدورات: البطاقة الأفقية نفسها مموّهة، فلا يقفز الارتفاع عند وصول البيانات.
class AppSliverBoardingSkeleton extends StatelessWidget {
  const AppSliverBoardingSkeleton({super.key, this.itemCount = 4, this.padding = const EdgeInsets.all(16)});

  final int itemCount;
  final EdgeInsetsGeometry padding;

  static final CourseModel _placeholder = CourseModel.fromJson({
    'id': 0,
    'title_ar': 'دورة تدريبية بعنوان من سطرين',
    'title_en': 'A training course with a two-line title',
    'price': '100000',
    'institute_name': 'Institute name',
    'start_date': '2026-10-22',
    'duration_hours': 8,
  });

  @override
  Widget build(BuildContext context) {
    return Skeletonizer.sliver(
      enabled: true,
      child: SliverPadding(
        padding: padding,
        sliver: SliverList.separated(
          itemCount: itemCount,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, __) => CourseBoardingCard(course: _placeholder),
        ),
      ),
    );
  }
}

/// هيكل قوائم البطاقات الصفّية ([AppRowCard]) — نفس الارتفاع والصورة في جهة البداية.
class AppRowListSkeleton extends StatelessWidget {
  const AppRowListSkeleton({super.key, this.itemCount = 6, this.padding = const EdgeInsets.all(16)});

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
        itemBuilder: (_, __) => const _SkeletonRowCard(),
      ),
    );
  }
}

/// نفس [AppRowListSkeleton] كـ sliver، داخل CustomScrollView برأس ينطوي.
class AppSliverRowListSkeleton extends StatelessWidget {
  const AppSliverRowListSkeleton({super.key, this.itemCount = 6, this.padding = const EdgeInsets.all(16)});

  final int itemCount;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer.sliver(
      enabled: true,
      child: SliverPadding(
        padding: padding,
        sliver: SliverList.separated(
          itemCount: itemCount,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, __) => const _SkeletonRowCard(),
        ),
      ),
    );
  }
}

/// بيانات وهمية لهياكل تُبنى من البطاقة الحقيقية نفسها (كما [AppSliverBoardingSkeleton]): نفس الارتفاع
/// والحشوة بالضبط، فلا تقفز الصفحة حين تحلّ البطاقات الحقيقية مكانها.
abstract final class AppSkeletonData {
  static final InstituteModel institute = InstituteModel.fromJson({
    'id': 0,
    'name_ar': 'اسم المعهد التدريبي',
    'name_en': 'Training institute name',
    'average_rating': '4.5',
    'courses_count': 12,
    'city': {'id': 0, 'name_ar': 'دمشق', 'name_en': 'Damascus'},
  });

  static final CourseModel course = CourseModel.fromJson({
    'id': 0,
    'title_ar': 'عنوان الدورة التدريبية',
    'title_en': 'Training course title',
    'level': 'beginner',
    'price': '350000',
  });

  static final InstructorModel instructor = InstructorModel.fromJson({
    'id': 0,
    'name_ar': 'اسم المدرّس',
    'name_en': 'Instructor name',
    'specialization_ar': 'التخصص',
    'specialization_en': 'Specialization',
    'experience_years': 5,
    'is_private': 1,
  });
}

/// هيكل قائمة مدرّسين خصوصيين ([PrivateInstructorListCard]) كـ sliver — البطاقة الحقيقية ببيانات وهمية.
class AppSliverInstructorListSkeleton extends StatelessWidget {
  const AppSliverInstructorListSkeleton({super.key, this.itemCount = 6, required this.padding});

  final int itemCount;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer.sliver(
      enabled: true,
      child: SliverPadding(
        padding: padding,
        sliver: SliverList.separated(
          itemCount: itemCount,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, __) => PrivateInstructorListCard(instructor: AppSkeletonData.instructor),
        ),
      ),
    );
  }
}

/// نسخة sliver من [AppListSkeleton] — تحت رأس الصفحة داخل CustomScrollView.
class AppSliverListSkeleton extends StatelessWidget {
  const AppSliverListSkeleton({super.key, this.itemCount = 6, this.padding = const EdgeInsets.all(16)});

  final int itemCount;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer.sliver(
      enabled: true,
      child: SliverPadding(
        padding: padding,
        sliver: SliverList.separated(
          itemCount: itemCount,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, __) => const _SkeletonListTile(),
        ),
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
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
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
                        decoration: BoxDecoration(
                          color: AppColors.indicatorFill,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
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
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.6,
                      children: List.generate(
                        4,
                        (_) => Container(
                          decoration: BoxDecoration(
                            color: AppColors.indicatorFill,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
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
                          decoration: BoxDecoration(
                            color: AppColors.indicatorFill,
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 48,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.indicatorFill,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              ],
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                children: List.generate(
                  3,
                  (_) => const Padding(padding: EdgeInsets.only(bottom: 12), child: _SkeletonListTile()),
                ),
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
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                SizedBox(height: layout.gapAfterImage),
                SizedBox(
                  height: layout.titleHeight,
                  child: const Align(
                    alignment: AlignmentDirectional.topStart,
                    child: Text('Course title placeholder', maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                ),
                SizedBox(height: layout.gapAfterTitle),
                SizedBox(
                  height: layout.subtitleHeight,
                  child: const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text('Institute name', style: TextStyle(fontSize: AppTextSize.sm)),
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
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: const Text('Online', style: TextStyle(fontSize: AppTextSize.xs)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.indicatorFill,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: const Text('24h', style: TextStyle(fontSize: AppTextSize.xs)),
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
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                '350000',
                                style: TextStyle(fontSize: AppTextSize.sm, fontWeight: FontWeight.w700),
                              ),
                            ),
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    '4.8',
                                    style: TextStyle(fontSize: AppTextSize.sm, fontWeight: FontWeight.w700),
                                  ),
                                  SizedBox(width: 3),
                                  Icon(Icons.star_rounded, size: 16, color: AppColors.ratingStar),
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

class _SkeletonPosterCard extends StatelessWidget {
  const _SkeletonPosterCard();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spec = CourseCardMetrics.posterSpec(constraints.maxWidth);
        return DecoratedBox(
          decoration: const BoxDecoration(color: AppColors.card, borderRadius: AppCorners.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
                  ),
                ),
              ),
              SizedBox(
                height: spec.stripHeight,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: CoursePosterSpec.padding),
                  child: Row(
                    children: [
                      Text(
                        '350,000',
                        style: TextStyle(fontSize: AppTextSize.lg, fontWeight: FontWeight.w800),
                      ),
                      Spacer(),
                      Text('4.8', style: TextStyle(fontSize: AppTextSize.sm)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// هيكل [CourseAuroraCard]: غلاف بزاوية lg ولوح سفلي بارتفاع اللوح الزجاجي الحقيقي.
class _SkeletonAuroraCard extends StatelessWidget {
  const _SkeletonAuroraCard();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spec = CourseCardMetrics.auroraSpec(
          constraints.maxWidth,
          textScale: CourseCardMetrics.textScaleOf(context),
        );
        return DecoratedBox(
          decoration: const BoxDecoration(color: AppColors.primary, borderRadius: AppCorners.lg),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(CourseAuroraSpec.inset),
              child: SizedBox(
                height: spec.panelHeight,
                child: DecoratedBox(
                  decoration: const BoxDecoration(color: AppColors.card, borderRadius: AppCorners.md),
                  // نفس خانات اللوح الحقيقي (التصنيف، سطرا العنوان، سطر البيانات) وحشوته: نصوص الهيكل
                  // بارتفاعها الطبيعي كانت أطول من اللوح فتفيض (23 px عند 411 dp).
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: spec.panelPadding,
                      vertical: CourseAuroraSpec.panelPaddingV,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: spec.categoryHeight,
                          child: const Text('البرمجة • مبتدئ', maxLines: 1, style: TextStyle(fontSize: AppTextSize.xs)),
                        ),
                        const SizedBox(height: CourseAuroraSpec.gapAfterCategory),
                        SizedBox(
                          height: spec.titleHeight,
                          child: Text(
                            'عنوان الدورة',
                            maxLines: 2,
                            style: TextStyle(fontSize: spec.titleSize, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(height: CourseAuroraSpec.gapAfterTitle),
                        SizedBox(
                          height: spec.metaHeight,
                          child: const Text('350,000', maxLines: 1, style: TextStyle(fontSize: AppTextSize.xs)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SkeletonRowCard extends StatelessWidget {
  const _SkeletonRowCard();

  @override
  Widget build(BuildContext context) {
    // البطاقة الصفّية الحقيقية نفسها بنصوص وهمية: نفس ارتفاعها (118 أو أكثر مع تكبير الخط) بكل اللغات —
    // النسخة المرسومة يدوياً كانت أطول بالعربية (170 بدل 118) فتقفز القوائم عند وصول البيانات.
    return const AppRowCard(
      leading: ColoredBox(color: AppColors.primary),
      title: AppRowTitle('اسم العنصر في القائمة'),
      subtitle: AppRowMeta(icon: Icons.apartment_rounded, text: 'المعهد • المدينة'),
      footer: AppRowMetaLine(
        items: [AppRowMeta(icon: Icons.schedule_rounded, text: '12 أسبوعاً')],
      ),
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
          Container(
            height: 88,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
            ),
          ),
          const Padding(padding: EdgeInsets.all(12), child: _SkeletonTextBlock(width: 150)),
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
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.md)),
          ),
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
    return const Row(children: [Text('Section title'), Spacer(), Text('Show all')]);
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
        children: [Text('Primary placeholder'), SizedBox(height: 8), Text('Secondary text')],
      ),
    );
  }
}

void _noop() {}
