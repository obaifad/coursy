part of '../design_system.dart';

/// بطاقة بيضاء ناعمة + ظل (مطابقة لأسلوب الـ UI Kit)
class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  static const radius = AppCorners.md;

  /// شكل ListTile/InkWell داخل البطاقة — ليتبع أثر الضغط زواياها.
  static const shape = RoundedRectangleBorder(borderRadius: radius);

  @override
  Widget build(BuildContext context) {
    // Material شفاف داخل الخلفية: ListTile/InkWell يرسمان التموّج عليه بدل أن تخفيه الخلفية الملوّنة
    // (Flutter يرفض ListTile تحت DecoratedBox ملوّن مباشرة).
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.card, borderRadius: AppCorners.md, boxShadow: AppShadows.card),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: AppCorners.md,
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: padding ?? const EdgeInsets.all(14), child: child),
      ),
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
    this.semanticLabel,
  });

  /// اسم الزر لقارئ الشاشة وللتلميح عند الضغط المطوّل.
  final String? semanticLabel;
  final VoidCallback onTap;
  final IconData icon;
  final bool filled;
  final double size;
  final Color? iconColor;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    const radius = AppRadius.sm;
    final resolvedIconColor = iconColor ?? (filled ? AppColors.textPrimary : AppColors.primary.withValues(alpha: 0.82));
    final label = semanticLabel;
    final button = Material(
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
    if (label == null) return button;
    return Tooltip(
      message: label,
      // onTap هنا لأن excludeSemantics يُسقط نقر InkWell — وإلا يُقرأ «زر» ولا يُفعَّل من TalkBack.
      child: Semantics(
        container: true,
        button: true,
        label: label,
        onTap: onTap,
        excludeSemantics: true,
        child: button,
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

  /// أقل عرض لتبويب لا نعرف نصّه (ليس Tab(text:)) في وضع التوزيع المتساوي قبل التحوّل للتمرير.
  static const double _minTabExtent = 84;

  /// ارتفاع التبويب = أقل مساحة لمس في إرشادات Android.
  static const double _tabHeight = 48;

  /// هامش حول النص داخل خلية التبويب (يشمل حشوة المؤشر) — كي لا يلامس النص حافة الكبسولة البيضاء.
  static const double _labelGutter = 16;

  static TextStyle get _labelStyle => AppFonts.tajawal(fontWeight: FontWeight.w700, fontSize: AppTextSize.sm);

  /// أعرض تسمية بين التبويبات، مقاسة بالخط الفعلي وحجم الخط في الجهاز. null = تبويب بلا نص معروف.
  static double? _widestLabel(BuildContext context, List<Widget> tabs) {
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    var widest = 0.0;
    for (final tab in tabs) {
      final text = tab is Tab ? tab.text : null;
      if (text == null) return null;
      final painter = TextPainter(
        text: TextSpan(text: text, style: _labelStyle),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      if (painter.width > widest) widest = painter.width;
      painter.dispose();
    }
    return widest;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(color: AppColors.indicatorFill, borderRadius: BorderRadius.circular(AppRadius.md)),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // توزيع متساوٍ بعرض الشريط ما دام أعرض نص يتّسع في خليته؛ التمرير فقط حين لا يتّسع فعلاً
            // (هاتف ضيق جداً أو خط كبير). كان الحد ثابتاً (84px) فتتحوّل 4 تبويبات قصيرة للتمرير على
            // هاتف 360dp وتنكمش يميناً بمؤشر ضيق، مع أن نصوصها تتّسع.
            final available = constraints.maxWidth - padding.horizontal;
            final perTab = tabs.isEmpty ? available : available / tabs.length;
            final widest = _widestLabel(context, tabs);
            final fits = widest != null ? widest + _labelGutter <= perTab : perTab >= _minTabExtent;
            final scrollable = isScrollable || !fits;
            return TabBar(
              controller: controller,
              isScrollable: scrollable,
              tabAlignment: scrollable ? TabAlignment.start : TabAlignment.fill,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: padding,
              labelPadding: scrollable ? const EdgeInsets.symmetric(horizontal: 16) : EdgeInsets.zero,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              splashBorderRadius: BorderRadius.circular(AppRadius.sm),
              indicator: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                boxShadow: const [BoxShadow(color: AppColors.shadowPurple, blurRadius: 10, offset: Offset(0, 3))],
              ),
              labelColor: AppColors.primaryInk,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: _labelStyle,
              unselectedLabelStyle: _labelStyle,
              // التبويب 48 (مساحة اللمس الدنيا) بدل 46 + سماكة مؤشر 2: الشريط يبقى 48 والكبسولة كما هي، فالمؤشر
              // هنا BoxDecoration يُرسم بارتفاع الشريط كله ولا يستعمل السماكة.
              indicatorWeight: 0,
              tabs: [
                for (final tab in tabs)
                  tab is Tab && tab.height == null
                      ? Tab(
                          key: tab.key,
                          text: tab.text,
                          icon: tab.icon,
                          iconMargin: tab.iconMargin,
                          height: _tabHeight,
                          child: tab.child,
                        )
                      : tab,
              ],
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

  /// حول الشريط داخل القسم: يترك له 48 (مساحة اللمس الدنيا للتبويب)؛ كان 6/8 فيبقى 46.
  static const EdgeInsets padding = EdgeInsets.fromLTRB(12, 5, 12, 7);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: sectionHeight,
      child: Padding(
        padding: padding,
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
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: AppTextSize.xl, color: AppColors.primaryInk),
        ),
        const SizedBox(height: 4),
        Text(
          item.label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: AppTextSize.xs),
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
    // العنوان و«عرض الكل» على خط أساس واحد: الزر داخل مساحة لمس 44 ونصّه في وسطها، فمحاذاة الأعلى كانت
    // تُنزله عن العنوان. خط الأساس يبقيهما على سطر واحد مهما اختلف حجماهما، ومع سطر فرعي أيضاً.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
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
    this.startInset,
    this.bottomInset = 0,
    this.rememberScroll = false,
    this.resetToken = 0,
  });

  final double height;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double separatorWidth;
  final double? edgeInset;

  /// حشوة بداية أول عنصر فقط (افتراضياً = [edgeInset]) — حين يسبق القائمة عنصر آخر في الصف.
  final double? startInset;

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
      padding: EdgeInsetsDirectional.only(start: isFirst ? (widget.startInset ?? inset) : 0, end: isLast ? inset : 0),
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
    this.startInset,
    this.bottomInset = 0,
    this.rememberScroll = false,
    this.resetToken = 0,
  });

  final double height;
  final List<Widget> children;
  final double separatorWidth;
  final double? edgeInset;

  /// حشوة بداية أول عنصر فقط (افتراضياً = [edgeInset]) — حين يسبق القائمة عنصر آخر في الصف.
  final double? startInset;
  final double bottomInset;
  final bool rememberScroll;
  final int resetToken;

  @override
  Widget build(BuildContext context) {
    return AppHorizontalListView(
      height: height,
      separatorWidth: separatorWidth,
      edgeInset: edgeInset,
      startInset: startInset,
      bottomInset: bottomInset,
      rememberScroll: rememberScroll,
      resetToken: resetToken,
      itemCount: children.length,
      itemBuilder: (_, i) => children[i],
    );
  }
}

/// فشل التحميل (انقطاع الشبكة…) مع زر إعادة — بدل عرض قائمة فارغة توحي بعدم وجود بيانات.
class AppLoadErrorState extends StatelessWidget {
  const AppLoadErrorState({super.key, required this.message, required this.onRetry, this.compact = false});

  final String message;
  final VoidCallback onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      message: message,
      icon: Icons.cloud_off_outlined,
      compact: compact,
      action: FilledButton(onPressed: onRetry, child: Text('retry'.tr)),
    );
  }
}

/// ذيل «تحميل المزيد» الموحّد لكل القوائم: تحميل تلقائي عند الاقتراب من النهاية.
///
/// القوائم الكسولة لا تبني هذا العنصر إلا حين يقترب من الشاشة، فبناؤه هو إشارة الوصول للنهاية: يطلب
/// الصفحة التالية من تلقاء نفسه. الحالات:
/// - جاري التحميل: مؤشر دائري صغير في الوسط.
/// - فشل: «تعذّر تحميل المزيد» وزر «إعادة المحاولة» (لا إعادة تلقائية، كي لا تتكرر الطلبات بلا نهاية).
/// - يوجد المزيد: يُحجز مكان المؤشر ويبدأ الطلب (فلا يقفز المحتوى عند ظهوره).
/// - لا مزيد: لا شيء.
/// [autoLoad] = false حين يتولى الصفحة نفسها المشغّل (مستمع تمرير) فيعرض الذيل الحالة فقط.
class AppLoadMoreFooter extends StatefulWidget {
  const AppLoadMoreFooter({
    super.key,
    required this.hasMore,
    required this.isLoading,
    required this.failed,
    required this.onLoadMore,
    this.autoLoad = true,
  });

  final bool hasMore;
  final bool isLoading;
  final bool failed;
  final VoidCallback onLoadMore;
  final bool autoLoad;

  @override
  State<AppLoadMoreFooter> createState() => _AppLoadMoreFooterState();
}

class _AppLoadMoreFooterState extends State<AppLoadMoreFooter> {
  bool _scheduled = false;

  bool get _shouldTrigger => widget.autoLoad && widget.hasMore && !widget.isLoading && !widget.failed;

  /// بعد الإطار الحالي (لا أثناء البناء)، ومرة واحدة لكل بناء؛ المتحكم نفسه يتجاهل الطلب المكرر.
  void _maybeTrigger() {
    if (!_shouldTrigger || _scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (mounted && _shouldTrigger) widget.onLoadMore();
    });
  }

  @override
  Widget build(BuildContext context) {
    _maybeTrigger();
    if (widget.failed && !widget.isLoading) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('error_load_more_failed'.tr, textAlign: TextAlign.center, style: AppTypography.cardSubtitle()),
            TextButton.icon(
              onPressed: widget.onLoadMore,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('retry'.tr),
            ),
          ],
        ),
      );
    }
    if (widget.isLoading || widget.hasMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: AppInlineLoader()),
      );
    }
    return const SizedBox.shrink();
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

  /// كـ sliver يملأ ما تبقّى من القائمة (تبويب داخل [AppNestedTabScrollView]): نفس [scrollable] شكلاً.
  static Widget sliver({
    required String message,
    String? subtitle,
    IconData icon = Icons.inbox_outlined,
    Widget? action,
    bool compact = false,
  }) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: AppEmptyState(message: message, subtitle: subtitle, icon: icon, action: action, compact: compact),
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
                      fontWeight: FontWeight.w500,
                      fontSize: AppTextSize.md,
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
