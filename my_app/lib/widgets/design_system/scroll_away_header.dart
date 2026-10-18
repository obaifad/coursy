part of '../design_system.dart';

/// نمط قوائم التطبيق (كتبويب الدورات): الرأس يتحرك مع المحتوى ويختفي عند النزول، والشريط [pinned]
/// (فلاتر، ترتيب، تبويبات) يلتصق بالأعلى. فلا يأكل الجزء العلوي الثابت نصف الشاشة على الهواتف الصغيرة.
class AppScrollAwayHeaderView extends StatefulWidget {
  const AppScrollAwayHeaderView({
    super.key,
    required this.header,
    required this.slivers,
    this.pinned,
    this.controller,
    this.onRefresh,
    this.storageKey,
  });

  final Widget header;

  /// يبقى ظاهراً في الأعلى بعد اختفاء الرأس. null = الرأس وحده يختفي.
  final Widget? pinned;
  final List<Widget> slivers;

  /// متحكّم التمرير إن احتاجته الشاشة (تحميل المزيد، الرجوع للأعلى)؛ وإلا يُنشأ هنا ويُتخلّص منه.
  final ScrollController? controller;
  final Future<void> Function()? onRefresh;

  /// يحفظ موضع التمرير بين التبويبات (PageStorageKey).
  final Key? storageKey;

  @override
  State<AppScrollAwayHeaderView> createState() => _AppScrollAwayHeaderViewState();
}

class _AppScrollAwayHeaderViewState extends State<AppScrollAwayHeaderView> {
  final _headerKey = GlobalKey();
  ScrollController? _ownController;

  ScrollController get _controller => widget.controller ?? (_ownController ??= ScrollController());

  @override
  void dispose() {
    _ownController?.dispose();
    super.dispose();
  }

  double _pinOffset() {
    final box = _headerKey.currentContext?.findRenderObject() as RenderBox?;
    return box != null && box.hasSize ? box.size.height : double.infinity;
  }

  @override
  Widget build(BuildContext context) {
    final view = CustomScrollView(
      key: widget.storageKey,
      controller: _controller,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: KeyedSubtree(key: _headerKey, child: widget.header),
        ),
        if (widget.pinned != null)
          PinnedHeaderSliver(
            child: AppPinnedBar(scrollController: _controller, pinOffset: _pinOffset, child: widget.pinned!),
          ),
        ...widget.slivers,
      ],
    );
    final onRefresh = widget.onRefresh;
    return onRefresh == null ? view : RefreshIndicator(color: AppColors.primary, onRefresh: onRefresh, child: view);
  }
}

/// خلفية الصفحة تحت الشريط الملتصق (فلا تظهر البطاقات من خلفه)، وظل خفيف فقط حين يلتصق بالأعلى
/// والمحتوى يمرّ تحته — فيبدو الفاصل مقصوداً بدل حافة مقطوعة.
class AppPinnedBar extends StatefulWidget {
  const AppPinnedBar({super.key, required this.scrollController, required this.pinOffset, required this.child});

  final ScrollController scrollController;

  /// ارتفاع ما يختفي قبل أن يلتصق الشريط.
  final double Function() pinOffset;
  final Widget child;

  @override
  State<AppPinnedBar> createState() => _AppPinnedBarState();
}

class _AppPinnedBarState extends State<AppPinnedBar> {
  bool _pinned = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_update);
  }

  @override
  void didUpdateWidget(AppPinnedBar oldWidget) {
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
    // أول موضع فقط: نفس المتحكّم قد يُربط مؤقتاً بقائمتين أثناء انتقال الصفحات.
    final pinned = sc.hasClients && sc.positions.first.pixels >= widget.pinOffset() - 0.5;
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

/// يعرف متى طُوي الرأس (صورة / تدرّج) تحت شريط علوي مثبّت — من إشعارات التمرير الخارجي فقط
/// (التبويبات والقوائم الداخلية أعمق فلا تُحسب). [collapseOffset] = ما يُمرَّر قبل اختفاء الرأس تقريباً.
class CollapsingHeroScope extends StatefulWidget {
  const CollapsingHeroScope({super.key, required this.collapseOffset, required this.builder});

  final double collapseOffset;
  final Widget Function(BuildContext context, bool collapsed) builder;

  @override
  State<CollapsingHeroScope> createState() => _CollapsingHeroScopeState();
}

class _CollapsingHeroScopeState extends State<CollapsingHeroScope> {
  bool _collapsed = false;

  bool _onScroll(ScrollUpdateNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    final collapsed = n.metrics.pixels >= widget.collapseOffset;
    if (collapsed != _collapsed) setState(() => _collapsed = collapsed);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollUpdateNotification>(
      onNotification: _onScroll,
      child: widget.builder(context, _collapsed),
    );
  }
}

/// ألوان شريط علوي فوق رأس داكن: أبيض (مع أيقونات شريط حالة فاتحة) فوق الغلاف، وداكن بعد طيّه على خلفية
/// الصفحة. (ثيم AppBar يحدد ألواناً داكنة صريحة، فـ foregroundColor وحده لا يكفي.)
abstract final class HeroAppBarStyle {
  static Color foreground(bool collapsed) => collapsed ? AppColors.textPrimary : Colors.white;

  static IconThemeData icons(bool collapsed) => IconThemeData(color: foreground(collapsed));

  static TextStyle title(bool collapsed) => AppFonts.tajawal(
    fontWeight: FontWeight.w800,
    fontSize: AppTextSize.xl,
    color: foreground(collapsed),
  ).copyWith(shadows: collapsed ? null : const [Shadow(color: Color(0x66000000), blurRadius: 8)]);

  static SystemUiOverlayStyle overlay(bool collapsed) => collapsed ? AppSystemUi.darkIcons : AppSystemUi.lightIcons;
}

/// مقاسات رأس صفحات التفاصيل (المعهد، المدرّس) وتوزيع محتواه.
///
/// الارتفاع يُحسب من محتوى الرأس نفسه: شريط الأدوات + الصورة الدائرية + اسم من سطرين + شريط التبويبات في
/// الأسفل. كان ارتفاعاً ثابتاً (200/220) يتوسّط فيه الشعار مساحةً يغطي آخرها شريط التبويبات، وتتغيّر
/// أطراف الرأس مع ارتفاع شريط الحالة، فيلامس الشعار عنوان الشريط على الهواتف ذات الشق.
abstract final class AppDetailHero {
  static const double tabBarHeight = 60;
  static const double gapTop = 12;
  static const double gapMid = 10;
  static const double gapBottom = 14;

  /// اسم الكيان تحت الصورة: سطران كحد أقصى.
  static double nameHeight(BuildContext context) => AppTextSize.xxl * 1.25 * 2 * CourseCardMetrics.textScaleOf(context);

  /// ارتفاع SliverAppBar الممتد (دون شريط الحالة، وشريط التبويبات فيه).
  static double expandedHeight(BuildContext context, {required double avatarSize}) =>
      kToolbarHeight + gapTop + avatarSize + gapMid + nameHeight(context) + gapBottom + tabBarHeight;

  /// موضع التمرير الذي يُعدّ الرأس عنده مطوياً (يتحوّل لون الشريط ويظهر عنوانه).
  static double collapseOffset(BuildContext context, {required double avatarSize}) =>
      expandedHeight(context, avatarSize: avatarSize) - kToolbarHeight - tabBarHeight - 24;
}

/// محتوى رأس التفاصيل: الخلفية، وفوقها الصورة الدائرية والاسم متوسّطان في المساحة الظاهرة فعلاً
/// (بين شريط الأدوات وشريط التبويبات). يتلاشى المحتوى عند الطيّ قبل أن يظهر عنوان الشريط الصغير.
class AppDetailHeroContent extends StatelessWidget {
  const AppDetailHeroContent({super.key, required this.background, required this.avatar, required this.name});

  final Widget background;
  final Widget avatar;
  final String name;

  @override
  Widget build(BuildContext context) {
    final t = _brandBarCollapse(context);
    final opacity = (1 - t / 0.6).clamp(0.0, 1.0);
    return Stack(
      fit: StackFit.expand,
      children: [
        background,
        Positioned(
          top: MediaQuery.paddingOf(context).top + kToolbarHeight + AppDetailHero.gapTop,
          bottom: AppDetailHero.tabBarHeight + AppDetailHero.gapBottom,
          left: 20,
          right: 20,
          child: Opacity(
            opacity: opacity,
            child: ExcludeSemantics(
              excluding: opacity == 0,
              child: Column(
                children: [
                  avatar,
                  const SizedBox(height: AppDetailHero.gapMid),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Text(
                        name,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.tajawal(
                          color: Colors.white,
                          fontSize: AppTextSize.xxl,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ).copyWith(shadows: const [Shadow(color: Color(0x66000000), blurRadius: 8)]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
