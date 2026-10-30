part of '../design_system.dart';

/// «Compact Row»: بطاقة صفّية بارتفاع 118px — الصورة/الشعار في جهة البداية، ثم العنوان والسطر الوصفي،
/// وسطر سفلي يجمع البيانات (المدة، التقييم…) والسعر أفقياً لقراءة سريعة. تُستخدم في قوائم المعاهد
/// والمفضلة ونتائج البحث ودوراتي. مع تكبير الخط يطول الصف بدل أن تتداخل نصوصه.
class AppRowCard extends StatelessWidget {
  const AppRowCard({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.footer,
    this.trailing,
    this.below,
    this.onTap,
    this.accentColor,
  });

  static const double height = 118;
  static const double padding = 12;

  /// الصورة مربّعة بارتفاع الصف ناقص الحشوة.
  static const double thumbSize = height - padding * 2;

  /// الصورة أو الشعار — يُعرض مربّعاً بزوايا [AppRadius.sm].
  final Widget leading;
  final Widget title;
  final Widget? subtitle;

  /// السطر السفلي (بيانات + سعر)، ملتصق بأسفل الصف بمحاذاة أسفل الصورة.
  final Widget? footer;

  /// في نهاية سطر العنوان (زر المفضلة، شارة الحالة…).
  final Widget? trailing;

  /// محتوى إضافي تحت الصف بفاصل (أزرار الحجز في دوراتي).
  final Widget? below;
  final VoidCallback? onTap;

  /// شريط ملوّن رفيع على حافة البداية (لون الحالة في «دوراتي»)؛ null = بلا شريط.
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final row = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: SizedBox.square(
              dimension: thumbSize,
              child: ClipRRect(borderRadius: AppCorners.sm, child: leading),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: thumbSize),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: title),
                          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
                        ],
                      ),
                      if (subtitle != null) ...[const SizedBox(height: 4), subtitle!],
                    ],
                  ),
                  if (footer != null) ...[const SizedBox(height: 8), footer!],
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppCorners.md,
        border: Border.all(color: AppColors.borderNeutral),
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: AppCorners.md,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.primary.withValues(alpha: 0.08),
          highlightColor: AppColors.primary.withValues(alpha: 0.04),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(padding),
                child: below == null
                    ? row
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          row,
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1, thickness: 1, color: AppColors.borderNeutral),
                          ),
                          below!,
                        ],
                      ),
              ),
              if (accentColor != null)
                PositionedDirectional(
                  start: 0,
                  top: 14,
                  bottom: 14,
                  width: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: const BorderRadiusDirectional.horizontal(end: Radius.circular(AppRadius.xs)),
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

/// عنوان الصف: سطران كحد أقصى، 15px بوزن العناوين.
class AppRowTitle extends StatelessWidget {
  const AppRowTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return BidiText(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.cardTitle());
  }
}

/// معلومة صغيرة بأيقونة (المدينة، المدة، عدد الدورات…).
class AppRowMeta extends StatelessWidget {
  const AppRowMeta({super.key, required this.icon, required this.text, this.iconColor, this.emphasized = false});

  final IconData icon;
  final String text;
  final Color? iconColor;

  /// قيمة بارزة (التقييم): نص أغمق بوزن التسميات.
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: iconColor ?? AppColors.textHint),
        const SizedBox(width: 4),
        Flexible(
          child: BidiText(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.tajawal(
              fontSize: AppTextSize.sm,
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
              height: 1.3,
              color: emphasized ? AppColors.textBody : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// صف معلومات أفقي: كل عنصر بحجمه الطبيعي، وحين لا يتسع العرض يُقصّ الأطول وحده بـ «…».
///
/// لا Flexible متساوية: كانت تعطي كل عنصر نصف العرض، فيحجز التقييم القصير («★ 4.4») نصفاً لا يحتاجه
/// وتُقصّ المدة إلى «120…» بجانب فراغ. هنا العنصر الذي يحتاج أقل من نصيبه العادل يأخذ حاجته، والباقي
/// يتوزّع على الأطول.
class AppRowMetaLine extends MultiChildRenderObjectWidget {
  const AppRowMetaLine({super.key, required List<Widget> items, this.spacing = 12}) : super(children: items);

  final double spacing;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMetaLine(spacing: spacing, textDirection: Directionality.of(context));

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderMetaLine)
      ..spacing = spacing
      ..textDirection = Directionality.of(context);
  }
}

class _MetaLineParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderMetaLine extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _MetaLineParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _MetaLineParentData> {
  _RenderMetaLine({required double spacing, required TextDirection textDirection})
    : _spacing = spacing,
      _textDirection = textDirection;

  double _spacing;
  set spacing(double value) {
    if (value == _spacing) return;
    _spacing = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _MetaLineParentData) child.parentData = _MetaLineParentData();
  }

  List<RenderBox> get _children {
    final list = <RenderBox>[];
    var child = firstChild;
    while (child != null) {
      list.add(child);
      child = childAfter(child);
    }
    return list;
  }

  double get _gaps => math.max(0, childCount - 1) * _spacing;

  /// العرض المخصّص لكل عنصر: من يحتاج أقل من نصيبه يأخذ حاجته، والأطول يتقاسمون الباقي.
  List<double> _widths(double maxWidth, double height) {
    final kids = _children;
    final needs = [for (final c in kids) c.getMaxIntrinsicWidth(height)];
    final widths = List<double>.of(needs);
    if (!maxWidth.isFinite) return widths;
    var remaining = math.max(0.0, maxWidth - _gaps);
    final order = List<int>.generate(kids.length, (i) => i)..sort((a, b) => needs[a].compareTo(needs[b]));
    for (var k = 0; k < order.length; k++) {
      final share = remaining / (order.length - k);
      final i = order[k];
      if (needs[i] <= share) {
        remaining -= needs[i];
      } else {
        for (final j in order.skip(k)) {
          widths[j] = share;
        }
        break;
      }
    }
    return widths;
  }

  Size _layout(BoxConstraints constraints, {required bool dry}) {
    final kids = _children;
    final widths = _widths(constraints.maxWidth, double.infinity);
    var height = 0.0;
    final sizes = <Size>[];
    for (var i = 0; i < kids.length; i++) {
      final c = BoxConstraints(maxWidth: widths[i], maxHeight: constraints.maxHeight);
      final size = dry ? kids[i].getDryLayout(c) : (kids[i]..layout(c, parentUsesSize: true)).size;
      sizes.add(size);
      height = math.max(height, size.height);
    }
    // مثل Row: يملأ العرض المتاح، والعناصر من جهة البداية.
    final contentWidth = sizes.fold<double>(0, (sum, s) => sum + s.width) + _gaps;
    final size = constraints.constrain(
      Size(constraints.maxWidth.isFinite ? constraints.maxWidth : contentWidth, height),
    );
    if (!dry) {
      final rtl = _textDirection == TextDirection.rtl;
      var x = 0.0;
      for (var i = 0; i < kids.length; i++) {
        final w = sizes[i].width;
        final dx = rtl ? size.width - x - w : x;
        (kids[i].parentData! as _MetaLineParentData).offset = Offset(dx, (height - sizes[i].height) / 2);
        x += w + _spacing;
      }
    }
    return size;
  }

  @override
  void performLayout() => size = _layout(constraints, dry: false);

  @override
  Size computeDryLayout(BoxConstraints constraints) => _layout(constraints, dry: true);

  @override
  double computeMinIntrinsicWidth(double height) => computeMaxIntrinsicWidth(height);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _children.fold<double>(0, (sum, c) => sum + c.getMaxIntrinsicWidth(height)) + _gaps;

  @override
  double computeMinIntrinsicHeight(double width) => computeMaxIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) {
    final kids = _children;
    final widths = _widths(width, double.infinity);
    var height = 0.0;
    for (var i = 0; i < kids.length; i++) {
      height = math.max(height, kids[i].getMaxIntrinsicHeight(widths[i]));
    }
    return height;
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      defaultComputeDistanceToHighestActualBaseline(baseline);

  @override
  void paint(PaintingContext context, Offset offset) => defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

/// أيقونة بجانب نص قد يلتفّ لأكثر من سطر: بارتفاع سطره الأول وعلى منتصفه (ويتبع تكبير الخط)، في صف
/// بمحاذاة البداية. بمحاذاة الوسط كانت تقع بين السطرين، وبحشوة علوية ثابتة تنحرف عند تكبير الخط.
class AppFirstLineIcon extends StatelessWidget {
  const AppFirstLineIcon(this.icon, {super.key, this.textStyle, this.size = 20, this.color});

  final IconData icon;

  /// نمط النص المجاور (يُدمج مع النمط الافتراضي كما يفعل Text).
  final TextStyle? textStyle;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final painter = TextPainter(
      text: TextSpan(text: ' ', style: DefaultTextStyle.of(context).style.merge(textStyle)),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final line = painter.preferredLineHeight;
    painter.dispose();
    // أيقونة أعلى من السطر تتجاوزه بالتساوي فوقه وتحته، فيبقى منتصفها على منتصف السطر.
    return SizedBox(
      width: size,
      height: line,
      child: OverflowBox(
        maxHeight: math.max(line, size),
        child: Icon(icon, size: size, color: color),
      ),
    );
  }
}
