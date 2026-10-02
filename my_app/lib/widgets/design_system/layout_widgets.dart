part of '../design_system.dart';

/// بطاقة بيضاء ناعمة + ظل (مطابقة لأسلوب الـ UI Kit)
class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.all(Radius.circular(20)),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );
  }
}

/// زر أيقونة دائري/مربّع ناعم (AppBar / Home)
class AppIconCircleButton extends StatelessWidget {
  const AppIconCircleButton({
    super.key,
    required this.onTap,
    required this.icon,
    this.filled = true,
    this.size = 44,
    this.iconColor,
    this.iconSize,
  });

  final VoidCallback onTap;
  final IconData icon;
  final bool filled;
  final double size;
  final Color? iconColor;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final radius = size >= 40 ? 14.0 : 12.0;
    final resolvedIconColor = iconColor ?? (filled ? AppColors.textPrimary : AppColors.primary.withValues(alpha: 0.82));
    return Material(
      color: filled ? AppColors.card : Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      elevation: 0,
      shadowColor: AppColors.shadowPurple,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: filled ? AppColors.card : AppColors.indicatorFill.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(radius),
            border: filled ? null : Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
            boxShadow: filled
                ? const [BoxShadow(color: AppColors.shadowSoft, blurRadius: 8, offset: Offset(0, 4))]
                : null,
          ),
          child: Icon(icon, color: resolvedIconColor, size: iconSize ?? size * 0.48),
        ),
      ),
    );
  }
}

/// شريط تبويبات يبدأ من حافة الشاشة حسب اتجاه اللغة (بدون فراغ زائد).
class AppEdgeTabBar extends StatelessWidget {
  const AppEdgeTabBar({super.key, required this.tabs, this.controller, this.edgeInset = 16, this.fill = false});

  final List<Widget> tabs;
  final TabController? controller;
  final double edgeInset;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      isScrollable: !fill,
      tabAlignment: fill ? TabAlignment.fill : TabAlignment.start,
      padding: EdgeInsets.zero,
      indicatorPadding: EdgeInsets.zero,
      dividerHeight: 0,
      labelPadding: fill ? EdgeInsets.zero : EdgeInsetsDirectional.only(start: edgeInset, end: 12),
      tabs: tabs,
    );
  }
}

/// تبويبات pill موحّدة عبر التطبيق (دوراتي، تفاصيل الدورة، المعاهد...).
class AppSegmentedTabBar extends StatelessWidget {
  const AppSegmentedTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.isScrollable = false,
    this.height = 48,
    this.padding = const EdgeInsets.all(4),
    this.margin = EdgeInsets.zero,
  });

  final TabController controller;
  final List<Widget> tabs;
  final bool isScrollable;
  final double height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  /// أقل عرض مقبول لكل تبويب في وضع التوزيع المتساوي (fill) قبل التحوّل للتمرير.
  static const double _minTabExtent = 84;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(color: AppColors.indicatorFill, borderRadius: BorderRadius.circular(16)),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // يتحوّل للتمرير تلقائياً عندما تضيق الخلايا (هواتف صغيرة + 4 تبويبات)
            // لمنع تجاوز RenderFlex، مع الإبقاء على التوزيع المتساوي على الشاشات الأوسع.
            final available = constraints.maxWidth - padding.horizontal;
            final perTab = tabs.isEmpty ? available : available / tabs.length;
            final scrollable = isScrollable || perTab < _minTabExtent;
            return TabBar(
              controller: controller,
              isScrollable: scrollable,
              tabAlignment: scrollable ? TabAlignment.start : TabAlignment.fill,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: padding,
              labelPadding: scrollable ? const EdgeInsets.symmetric(horizontal: 10) : EdgeInsets.zero,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              splashBorderRadius: BorderRadius.circular(12),
              indicator: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: AppColors.shadowPurple, blurRadius: 10, offset: Offset(0, 3))],
              ),
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: AppFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 13),
              unselectedLabelStyle: AppFonts.tajawal(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: tabs,
            );
          },
        ),
      ),
    );
  }
}

/// غلاف تبويبات pill بنفس مقاسات [CourseDetailsView].
class AppTabBarSection extends StatelessWidget {
  const AppTabBarSection({super.key, required this.controller, required this.tabs, this.isScrollable = false});

  final TabController controller;
  final List<Widget> tabs;
  final bool isScrollable;

  static const double sectionHeight = 60;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: sectionHeight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        child: AppSegmentedTabBar(controller: controller, isScrollable: isScrollable, tabs: tabs),
      ),
    );
  }
}

/// يمنع تداخل المحتوى مع شريط الحالة في التبويبات والشاشات.
class AppTabSafeArea extends StatelessWidget {
  const AppTabSafeArea({super.key, required this.child, this.top = true, this.bottom = false});

  final Widget child;
  final bool top;
  final bool bottom;

  @override
  Widget build(BuildContext context) {
    return SafeArea(top: top, bottom: bottom, child: child);
  }
}

/// عنوان شاشة داخل التبويب مع احترام المنطقة الآمنة.
class AppTabScreenHeader extends StatelessWidget {
  const AppTabScreenHeader({super.key, required this.title, this.padding});

  final String title;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 0),
      child: Text(title, style: AppTypography.tabScreenTitle()),
    );
  }
}

/// إحصائيات أفقية (الملف الشخصي وغيره).
class AppStatsRow extends StatelessWidget {
  const AppStatsRow({super.key, required this.items});

  final List<AppStatItem> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) Container(width: 1, height: 36, color: AppColors.borderSoft),
          Expanded(child: _AppStatCell(item: items[i])),
        ],
      ],
    );
  }
}

class AppStatItem {
  const AppStatItem({required this.value, required this.label});

  final String value;
  final String label;
}

class _AppStatCell extends StatelessWidget {
  const _AppStatCell({required this.item});

  final AppStatItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          item.value,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primary),
        ),
        const SizedBox(height: 4),
        Text(
          item.label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// عنوان قسم + اختياري "عرض الكل"
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({super.key, required this.title, this.subtitle, this.actionLabel, this.onAction});

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.sectionTitle(), textAlign: TextAlign.start),
              if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: AppTypography.pageSubtitle(), textAlign: TextAlign.start),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(padding: EdgeInsetsDirectional.zero, minimumSize: const Size(48, 44)),
            child: Text(actionLabel!, style: AppTypography.actionLabel()),
          ),
      ],
    );
  }
}

/// قائمة أفقية موحّدة — تتبع [Directionality] دائماً:
/// في RTL يبدأ أول عنصر من أقصى اليمين ويملأ نحو اليسار، وفي LTR العكس.
///
/// لا تستخدم `reverse` إطلاقاً — اتجاه التمرير يُشتق تلقائياً من اتجاه اللغة،
/// لضمان محاذاة متطابقة عبر كل القوائم (بطاقات وشرائح) حاضراً ومستقبلاً.
class AppHorizontalListView extends StatefulWidget {
  const AppHorizontalListView({
    super.key,
    required this.height,
    required this.itemCount,
    required this.itemBuilder,
    this.separatorWidth = 12,
    this.edgeInset,
    this.bottomInset = 0,
    this.rememberScroll = false,
    this.resetToken = 0,
  });

  final double height;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double separatorWidth;
  final double? edgeInset;

  /// حشو سفلي للحاوية — يمنع قص ظل البطاقات (Box Shadow) عند حافة القائمة.
  final double bottomInset;

  /// false = لا يحفظ موضع التمرير (مُفضّل للقوائم القصيرة في الرئيسية).
  final bool rememberScroll;

  /// عند تغيّره تُعاد القائمة لنقطة البداية (يُستخدم مع العودة للرئيسية).
  final int resetToken;

  /// مساحة كافية لظل البطاقات ذات الـ boxShadow (مثلاً featured course cards).
  static const double cardShadowBottomInset = 28;

  @override
  State<AppHorizontalListView> createState() => _AppHorizontalListViewState();
}

class _AppHorizontalListViewState extends State<AppHorizontalListView> {
  late ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController(keepScrollOffset: widget.rememberScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToStart());
  }

  @override
  void didUpdateWidget(covariant AppHorizontalListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resetToken != oldWidget.resetToken) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToStart());
    }
    if (widget.rememberScroll != oldWidget.rememberScroll) {
      _controller.dispose();
      _controller = ScrollController(keepScrollOffset: widget.rememberScroll);
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToStart());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _jumpToStart() {
    if (!_controller.hasClients) return;
    final target = _controller.position.minScrollExtent;
    if ((_controller.offset - target).abs() > 0.5) {
      _controller.jumpTo(target);
    }
  }

  double _edgeInset(BuildContext context) => widget.edgeInset ?? AppLayout.horizontalPage(context);

  Widget _itemWithEdgeInsets(BuildContext context, int index) {
    final child = widget.itemBuilder(context, index);
    final inset = _edgeInset(context);
    if (inset <= 0) return child;

    final isFirst = index == 0;
    final isLast = index == widget.itemCount - 1;
    if (!isFirst && !isLast) return child;

    return Padding(
      padding: EdgeInsetsDirectional.only(start: isFirst ? inset : 0, end: isLast ? inset : 0),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount == 0) return const SizedBox.shrink();
    // ملاحظة: لا نمرّر `reverse` — اتجاه التمرير يُشتق من Directionality،
    // فيبدأ أول عنصر من اليمين في RTL ومن اليسار في LTR بشكل موحّد.
    return SizedBox(
      height: widget.height + widget.bottomInset,
      width: double.infinity,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: EdgeInsets.only(bottom: widget.bottomInset),
        itemCount: widget.itemCount,
        separatorBuilder: (_, __) => SizedBox(width: widget.separatorWidth),
        itemBuilder: (context, index) => _itemWithEdgeInsets(context, index),
      ),
    );
  }
}

/// صف أفقي جاهز من عناصر — ترتيب منطقي RTL (العنصر الأول يميناً).
class AppHorizontalScrollRow extends StatelessWidget {
  const AppHorizontalScrollRow({
    super.key,
    required this.height,
    required this.children,
    this.separatorWidth = 8,
    this.edgeInset,
    this.bottomInset = 0,
    this.rememberScroll = false,
    this.resetToken = 0,
  });

  final double height;
  final List<Widget> children;
  final double separatorWidth;
  final double? edgeInset;
  final double bottomInset;
  final bool rememberScroll;
  final int resetToken;

  @override
  Widget build(BuildContext context) {
    return AppHorizontalListView(
      height: height,
      separatorWidth: separatorWidth,
      edgeInset: edgeInset,
      bottomInset: bottomInset,
      rememberScroll: rememberScroll,
      resetToken: resetToken,
      itemCount: children.length,
      itemBuilder: (_, i) => children[i],
    );
  }
}

/// حالة فارغة موحّدة — نفس المظهر في كل الصفحات.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.message,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.action,
    this.compact = false,
    this.iconColor,
    this.iconBackgroundColor,
    this.iconSize,
    this.circleSize,
  });

  final String message;
  final String? subtitle;
  final IconData icon;
  final Widget? action;
  final bool compact;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final double? iconSize;
  final double? circleSize;

  /// للقوائم القابلة للسحب (RefreshIndicator / TabBarView).
  static Widget scrollable({
    required BuildContext context,
    required String message,
    String? subtitle,
    IconData icon = Icons.inbox_outlined,
    Widget? action,
    bool compact = false,
    Color? iconColor,
    Color? iconBackgroundColor,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: AppEmptyState(
              message: message,
              subtitle: subtitle,
              icon: icon,
              action: action,
              compact: compact,
              iconColor: iconColor,
              iconBackgroundColor: iconBackgroundColor,
            ),
          ),
        );
      },
    );
  }

  /// داخل SoftCard أو قسم أفقي في الصفحة الرئيسية.
  static Widget inline({required String message, IconData icon = Icons.inbox_outlined, String? subtitle}) {
    return AppEmptyState(message: message, subtitle: subtitle, icon: icon, compact: true);
  }

  @override
  Widget build(BuildContext context) {
    final tint = iconColor ?? AppColors.primary;
    final circle = circleSize ?? (compact ? 52.0 : 104.0);
    final iconSz = iconSize ?? (compact ? 26.0 : 52.0);
    final verticalPad = compact ? 16.0 : 24.0;
    final horizontalPad = compact ? 16.0 : 32.0;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPad, vertical: verticalPad),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: circle,
              height: circle,
              decoration: BoxDecoration(
                color: iconBackgroundColor ?? tint.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: iconSz, color: tint),
            ),
            SizedBox(height: compact ? 12 : 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: compact
                  ? const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    )
                  : AppTypography.sectionTitle(),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              SizedBox(height: compact ? 4 : 8),
              Text(subtitle!, textAlign: TextAlign.center, style: AppTypography.pageSubtitle()),
            ],
            if (action != null) ...[SizedBox(height: compact ? 12 : 24), action!],
          ],
        ),
      ),
    );
  }
}
