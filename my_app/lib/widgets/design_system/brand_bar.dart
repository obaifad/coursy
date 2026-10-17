part of '../design_system.dart';

/// «Brand Bar»: رأس بنفسجي صلب ينطوي مع التمرير — لشاشات القوائم الرئيسية (الدورات، التصنيف، المعاهد،
/// المفضلة، دوراتي). ممتداً: كبسولة العدّاد ثم العنوان الكبير والسطر الفرعي؛ مطوياً: شريط أدوات بعنوان صغير
/// يبقى مثبّتاً. أيقونات شريط الحالة بيضاء في كل حالات التمرير لأن الشريط المثبّت يبقى تحتها دائماً.
///
/// زر الرجوع دائرة 40px تبدأ حافتها عند هامش المحتوى ([AppLayout.horizontalPage]) — نفس بداية العنوان —
/// في العربية والإنجليزية؛ منطقة اللمس 48px تمتد 4px حولها.
class AppBrandSliverAppBar extends StatelessWidget {
  const AppBrandSliverAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.badge,
    this.onBack,
    this.actions,
    this.bottom,
  });

  final String title;
  final String? subtitle;

  /// نص الكبسولة فوق العنوان (مثل «3 دورات»). صفّها محجوز حتى قبل وصول العدد فلا يقفز الرأس.
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

  /// الشاشات القصيرة (هاتف أفقي، 320×640): بلا السطر الفرعي كي لا يأكل الرأس نصف الشاشة.
  static bool isCompact(BuildContext context) => MediaQuery.sizeOf(context).height < 700;

  static bool _showsSubtitle(BuildContext context, String? subtitle) =>
      subtitle != null && subtitle.isNotEmpty && !isCompact(context);

  /// ارتفاع الجزء الممتد تحت شريط الأدوات: الكبسولة + العنوان الكبير + السطر الفرعي + الحشوة السفلية.
  static double collapseDistance(BuildContext context, {bool hasSubtitle = true}) {
    final s = CourseCardMetrics.textScaleOf(context);
    final pill = AppTextSize.xs * 1.25 * s + 10;
    final titleLine = AppTextSize.display * 1.2 * s;
    final subtitleLine = hasSubtitle && !isCompact(context) ? 4 + AppTextSize.md * 1.4 * s : 0.0;
    return (pill + 8 + titleLine + subtitleLine + 16).ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    final gutter = AppLayout.horizontalPage(context);
    final hasSubtitle = _showsSubtitle(context, subtitle);
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    return SliverAppBar(
      pinned: true,
      primary: true,
      automaticallyImplyLeading: false,
      toolbarHeight: toolbarHeight,
      expandedHeight: toolbarHeight + collapseDistance(context, hasSubtitle: hasSubtitle) + bottomHeight,
      backgroundColor: background,
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
      flexibleSpace: _BrandBarExpandedArea(
        title: title,
        subtitle: hasSubtitle ? subtitle : null,
        badge: badge,
        gutter: gutter,
        bottomHeight: bottomHeight,
      ),
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
    required this.subtitle,
    required this.badge,
    required this.gutter,
    required this.bottomHeight,
  });

  final String title;
  final String? subtitle;
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
        const ColoredBox(color: AppBrandSliverAppBar.background),
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
                  bottom: 16,
                  child: Opacity(
                    opacity: opacity,
                    child: ExcludeSemantics(
                      excluding: opacity == 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // بلا عدد بعد: كبسولة شفافة بنفس الحجم.
                          Opacity(
                            opacity: badge == null ? 0 : 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: AppCorners.full,
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                child: Text(
                                  badge ?? ' ',
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
                          ),
                          const SizedBox(height: 8),
                          Text(
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
                          if (subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.tajawal(
                                color: Colors.white.withValues(alpha: 0.88),
                                fontSize: AppTextSize.md,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
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
