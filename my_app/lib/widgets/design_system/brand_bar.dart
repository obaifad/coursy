part of '../design_system.dart';

/// «Brand Bar»: الرأس البنفسجي لشاشات القوائم الرئيسية (الدورات، التصنيف، المعاهد، المفضلة، دوراتي، البحث) —
/// بشكل الرأس الأصلي: تدرّج الهوية بنقش نقاط خفيف وتعتيم سفلي، وزوايا سفلية مدوّرة 28. مضغوط: سطر واحد
/// فيه العنوان الكبير في البداية وكبسولة العدّاد في النهاية، فيكون الرأس نحو 104px (كان نحو 165)؛ ينطوي مع
/// التمرير إلى شريط أدوات بعنوان صغير يبقى مثبّتاً.
/// أيقونات شريط الحالة بيضاء في كل حالات التمرير لأن الشريط المثبّت يبقى تحتها دائماً.
///
/// زر الرجوع دائرة 40px تبدأ حافتها عند هامش المحتوى ([AppLayout.horizontalPage]) — نفس بداية العنوان —
/// في العربية والإنجليزية؛ منطقة اللمس 48px تمتد 4px حولها.
class AppBrandSliverAppBar extends StatelessWidget {
  const AppBrandSliverAppBar({super.key, required this.title, this.badge, this.onBack, this.actions, this.bottom});

  final String title;

  /// نص الكبسولة في نهاية سطر العنوان (مثل «3 دورات»). تظهر حين يصل العدد؛ ارتفاع السطر ثابت فلا يقفز الرأس.
  final String? badge;

  /// إن وُجد يظهر زر الرجوع في بداية شريط الأدوات.
  final VoidCallback? onBack;
  final List<Widget>? actions;

  /// شريط مثبّت تحت الرأس (تبويبات…) — بخلفية الصفحة لا البنفسجي.
  final PreferredSizeWidget? bottom;

  static const double toolbarHeight = 56;
  static const double backButtonSize = 40;
  static const double _backTapTarget = 48;
  static const Color background = AppColors.primaryStrong;

  /// زوايا الرأس السفلية (كالرأس الأصلي).
  static const double bottomRadius = 28;

  /// الحشوة السفلية تحت سطر العنوان.
  static const double _bottomPad = 14;

  /// ارتفاع الجزء الممتد تحت شريط الأدوات: سطر العنوان + الحشوة السفلية (56 + 48 = 104 بحجم الخط العادي).
  static double collapseDistance(BuildContext context) {
    final s = CourseCardMetrics.textScaleOf(context);
    return (AppTextSize.display * 1.2 * s + _bottomPad).ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    final gutter = AppLayout.horizontalPage(context);
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    return SliverAppBar(
      pinned: true,
      primary: true,
      automaticallyImplyLeading: false,
      toolbarHeight: toolbarHeight,
      expandedHeight: toolbarHeight + collapseDistance(context) + bottomHeight,
      // الخلفية يرسمها flexibleSpace (تدرّج بزوايا مدوّرة)؛ الشفافية تُظهر الصفحة عند الزوايا.
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: AppSystemUi.lightIcons,
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
      // الدائرة تبدأ عند الهامش: حشوة (الهامش − 4) ثم منطقة لمس 48 تتوسطها الدائرة.
      leadingWidth: onBack == null ? 0 : gutter - (_backTapTarget - backButtonSize) / 2 + _backTapTarget,
      leading: onBack == null ? null : AppBrandBackButton(onPressed: onBack!, gutter: gutter),
      titleSpacing: onBack == null ? gutter : 8,
      centerTitle: false,
      title: _BrandBarCollapsedTitle(title: title),
      actions: actions,
      flexibleSpace: _BrandBarExpandedArea(title: title, badge: badge, gutter: gutter, bottomHeight: bottomHeight),
      bottom: bottom,
    );
  }
}

/// زر الرجوع في [AppBrandSliverAppBar]: دائرة بيضاء شفافة 40px، حافتها على [gutter].
class AppBrandBackButton extends StatelessWidget {
  const AppBrandBackButton({super.key, required this.onPressed, required this.gutter});

  final VoidCallback onPressed;
  final double gutter;

  static const Key circleKey = ValueKey('brand-bar-back-circle');

  @override
  Widget build(BuildContext context) {
    const size = AppBrandSliverAppBar.backButtonSize;
    const target = AppBrandSliverAppBar._backTapTarget;
    return Padding(
      padding: EdgeInsetsDirectional.only(start: gutter - (target - size) / 2),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Semantics(
          button: true,
          label: 'back'.tr,
          child: Tooltip(
            message: 'back'.tr,
            child: InkResponse(
              onTap: onPressed,
              radius: target / 2,
              child: SizedBox.square(
                dimension: target,
                child: Center(
                  child: Container(
                    key: circleKey,
                    width: size,
                    height: size,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// نسبة انطواء الرأس: 0 ممتد بالكامل، 1 مطوي إلى شريط الأدوات.
double _brandBarCollapse(BuildContext context) {
  final settings = context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
  if (settings == null) return 0;
  final range = settings.maxExtent - settings.minExtent;
  if (range <= 0) return 1;
  return ((settings.maxExtent - settings.currentExtent) / range).clamp(0.0, 1.0);
}

/// العنوان الصغير في شريط الأدوات — يظهر فقط حين يقترب الرأس من الانطواء الكامل.
class _BrandBarCollapsedTitle extends StatelessWidget {
  const _BrandBarCollapsedTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final t = _brandBarCollapse(context);
    final opacity = ((t - 0.6) / 0.4).clamp(0.0, 1.0);
    return Opacity(
      opacity: opacity,
      child: ExcludeSemantics(
        excluding: opacity == 0,
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.tajawal(color: Colors.white, fontSize: AppTextSize.xl, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _BrandBarExpandedArea extends StatelessWidget {
  const _BrandBarExpandedArea({
    required this.title,
    required this.badge,
    required this.gutter,
    required this.bottomHeight,
  });

  final String title;
  final String? badge;
  final double gutter;
  final double bottomHeight;

  @override
  Widget build(BuildContext context) {
    final t = _brandBarCollapse(context);
    // يتلاشى المحتوى الممتد في أول 60% من الانطواء، قبل أن يظهر العنوان الصغير.
    final opacity = (1 - t / 0.6).clamp(0.0, 1.0);
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: bottomHeight,
          child: const ClipRRect(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppBrandSliverAppBar.bottomRadius)),
            child: _BrandBarBackground(),
          ),
        ),
        if (bottomHeight > 0)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: bottomHeight,
            child: ColoredBox(color: Theme.of(context).scaffoldBackgroundColor),
          ),
        // المحتوى الممتد يُقصّ تحت شريط الأدوات: ينزلق تحته عند الانطواء بدل أن يمرّ خلف زر الرجوع.
        Positioned(
          top: MediaQuery.paddingOf(context).top + AppBrandSliverAppBar.toolbarHeight,
          left: 0,
          right: 0,
          bottom: bottomHeight,
          child: ClipRect(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                PositionedDirectional(
                  start: gutter,
                  end: gutter,
                  bottom: AppBrandSliverAppBar._bottomPad,
                  child: Opacity(
                    opacity: opacity,
                    child: ExcludeSemantics(
                      excluding: opacity == 0,
                      // سطر واحد: العنوان في البداية، والعدّاد في النهاية (يظهر حين يصل العدد).
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.tajawal(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: AppTextSize.display,
                                height: 1.2,
                              ),
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 10),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: AppCorners.full,
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                child: Text(
                                  badge!,
                                  maxLines: 1,
                                  style: AppFonts.tajawal(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: AppTextSize.xs,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// خلفية الرأس الأصلي: تدرّج الهوية، نقش نقاط خفيف، وتعتيم يزداد نحو الأسفل.
class _BrandBarBackground extends StatelessWidget {
  const _BrandBarBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGradients.heroBanner),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const BrandBannerPattern(),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withValues(alpha: 0.05), Colors.black.withValues(alpha: 0.38)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
