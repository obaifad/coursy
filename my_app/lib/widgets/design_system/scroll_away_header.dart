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
        SliverToBoxAdapter(child: KeyedSubtree(key: _headerKey, child: widget.header)),
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
