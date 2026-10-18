part of '../app_widgets.dart';

/// بطاقة الدورة «Aurora Glass» (التصميم E في مراجعة التصميم): الغلاف يملأ البطاقة، فوقه توهّج «شفق»
/// ساطع بألوان التصنيف، وفي الأسفل لوح زجاجي مضبّب يحمل التصنيف والمستوى، العنوان، ثم التقييم والمدة.
/// في الأعلى: كبسولة السعر الداكنة وزر المفضلة الداكن متجاوران في زاوية النهاية.
///
/// التوهّج ثابت (بلا حركة دائمة تكلّف إطارات أثناء التمرير)، والضبابية حقيقية لكنها محصورة في اللوح.
/// عند الضغط تميل البطاقة قليلاً نحو الإصبع ويلمع سطحها؛ تقليل الحركة في النظام يلغي الميل.
class CourseAuroraCard extends StatefulWidget {
  const CourseAuroraCard({super.key, required this.course, this.onTap, this.onFavoritePressed});

  final CourseModel course;
  final VoidCallback? onTap;

  /// بديل لتبديل المفضلة الافتراضي (صفحة المفضلة: إزالة مع تلاشٍ وتراجع).
  final Future<void> Function()? onFavoritePressed;

  @override
  State<CourseAuroraCard> createState() => _CourseAuroraCardState();
}

class _CourseAuroraCardState extends State<CourseAuroraCard> {
  /// موضع اللمس داخل البطاقة (-1..1 على كل محور)؛ يبقى بعد الرفع كي يتلاشى اللمعان من مكانه.
  Offset _touch = Offset.zero;
  bool _pressed = false;

  /// أقصى ميل (≈4°).
  static const double _maxTilt = 0.07;

  void _down(Offset local, Size size) {
    if (size.isEmpty) return;
    setState(() {
      _pressed = true;
      _touch = Offset(
        (local.dx / size.width * 2 - 1).clamp(-1.0, 1.0),
        (local.dy / size.height * 2 - 1).clamp(-1.0, 1.0),
      );
    });
  }

  void _release() {
    if (_pressed) setState(() => _pressed = false);
  }

  /// النقطة الملموسة تغوص بعيداً عن العين: الحافة العليا تبتعد عند لمسها، وكذلك اليمنى واليسرى.
  Matrix4 _tilt(bool active) {
    final matrix = Matrix4.identity()..setEntry(3, 2, 0.0012);
    if (!active) return matrix;
    return matrix
      ..rotateX(_touch.dy * _maxTilt)
      ..rotateY(-_touch.dx * _maxTilt);
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    final tilts = !MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final spec = CourseCardMetrics.auroraSpec(
          constraints.maxWidth,
          textScale: CourseCardMetrics.textScaleOf(context),
        );
        // ارتفاع مفروض (خلية شبكة) يُحترم؛ وإلا الارتفاع الطبيعي.
        final height = constraints.hasTightHeight
            ? constraints.maxHeight
            : spec.height.clamp(0.0, constraints.maxHeight).toDouble();
        final size = Size(constraints.maxWidth, height);

        return AnimatedScale(
          scale: _pressed ? 0.98 : 1,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: size.width,
            height: size.height,
            transformAlignment: Alignment.center,
            transform: _tilt(_pressed && tilts),
            decoration: const BoxDecoration(borderRadius: AppCorners.lg, boxShadow: _auroraShadow),
            child: ClipRRect(
              borderRadius: AppCorners.lg,
              child: MergeSemantics(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CourseImageHero(
                      courseId: course.id,
                      child: _CourseCardImage(
                        course: course,
                        borderRadius: BorderRadius.zero,
                        fallbackSize: spec.compact ? 26 : 30,
                        // اللوح يغطي النصف السفلي — أيقونة البديل في الأعلى.
                        fallbackIconAlignment: const Alignment(0, -0.5),
                      ),
                    ),
                    const _AuroraScrim(),
                    // في نفس طبقة الصورة (بلا RepaintBoundary) كي يُضاف الضوء إلى بكسلاتها فعلاً.
                    CustomPaint(painter: _AuroraGlowPainter(colors: _auroraPaletteFor(course))),
                    // حافة زجاجية رفيعة حول البطاقة.
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: AppCorners.lg,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                      ),
                    ),
                    Positioned(
                      left: CourseAuroraSpec.inset,
                      right: CourseAuroraSpec.inset,
                      bottom: CourseAuroraSpec.inset,
                      height: spec.panelHeight,
                      child: _AuroraGlassPanel(course: course, spec: spec),
                    ),
                    // لمعان يتبع الإصبع أثناء الضغط.
                    IgnorePointer(
                      child: AnimatedOpacity(
                        opacity: _pressed ? 1 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment(_touch.dx, _touch.dy),
                              radius: 0.9,
                              colors: [Colors.white.withValues(alpha: 0.24), Colors.white.withValues(alpha: 0)],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // طبقة اللمس في الأعلى: تموّج InkWell يظهر فوق الغلاف لا تحته.
                    Semantics(
                      button: true,
                      child: Material(
                        type: MaterialType.transparency,
                        child: InkWell(
                          onTap: widget.onTap,
                          onTapDown: (details) => _down(details.localPosition, size),
                          onTapUp: (_) => _release(),
                          onTapCancel: _release,
                          splashColor: Colors.white.withValues(alpha: 0.12),
                          highlightColor: Colors.white.withValues(alpha: 0.04),
                        ),
                      ),
                    ),
                    // مساحة لمس المفضلة 44 حول دائرة 32: الصف يبدأ قبل الحافة بـ 6 كي تبعد الدائرة 10.
                    PositionedDirectional(
                      top: CourseAuroraSpec.topInset - 6,
                      start: CourseAuroraSpec.topInset,
                      end: CourseAuroraSpec.topInset - 6,
                      child: _AuroraTopRow(course: course, onFavoritePressed: widget.onFavoritePressed),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

const List<BoxShadow> _auroraShadow = [
  BoxShadow(color: Color(0x59312E81), blurRadius: 16, offset: Offset(0, 8), spreadRadius: -6),
  BoxShadow(color: AppColors.shadowNeutralSoft, blurRadius: 4, offset: Offset(0, 2)),
];

/// حبر الزجاج الداكن (نيلي شبه أسود) — أساس كل الطبقات الشفافة في البطاقة.
const Color _auroraInk = Color(0xFF0F0C28);

/// ثلاثة ألوان «شفق» لكل تصنيف: دورات التصنيف الواحد تتشابه، وتختلف عن غيرها في الشبكة.
const List<List<Color>> _auroraPalettes = [
  [Color(0xFF818CF8), Color(0xFF6C63FF), Color(0xFF22D3EE)],
  [Color(0xFF22D3EE), Color(0xFF3B82F6), Color(0xFF6366F1)],
  [Color(0xFFF472B6), Color(0xFFA855F7), Color(0xFF6366F1)],
  [Color(0xFFFBBF24), Color(0xFFF97316), Color(0xFFF43F5E)],
  [Color(0xFF38BDF8), Color(0xFF818CF8), Color(0xFF34D399)],
  [Color(0xFF34D399), Color(0xFF10B981), Color(0xFF22D3EE)],
];

/// ثابت بين التشغيلات: معرّف التصنيف، أو مجموع حروف اسمه (hashCode للنص لا يُضمن ثباته)، أو معرّف الدورة.
List<Color> _auroraPaletteFor(CourseModel course) {
  final name = course.categoryName?.trim() ?? '';
  final key = course.categoryId ?? (name.isEmpty ? course.id : name.codeUnits.fold<int>(0, (sum, c) => sum + c));
  return _auroraPalettes[key.abs() % _auroraPalettes.length];
}

/// تعتيم خفيف أعلى الغلاف (للشارات) وأقوى أسفله (للوح الزجاجي).
class _AuroraScrim extends StatelessWidget {
  const _AuroraScrim();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0, 0.38, 1],
          colors: [
            _auroraInk.withValues(alpha: 0.22),
            _auroraInk.withValues(alpha: 0),
            _auroraInk.withValues(alpha: 0.5),
          ],
        ),
      ),
    );
  }
}

/// ثلاث بقع «شفق» ساطعة تُمزج مع الصورة بـ BlendMode.screen: تفتّحها وتلوّنها بألوان التصنيف (كالتصميم)
/// بدل طبقة داكنة. بلا ImageFilter ولا حركة — رسم رخيص يصلح لشبكة تُمرَّر.
class _AuroraGlowPainter extends CustomPainter {
  const _AuroraGlowPainter({required this.colors});

  final List<Color> colors;

  /// (مركز x، مركز y، شدة) نسبةً للبطاقة — أعلى البداية، منتصف النهاية، وأسفل الوسط.
  static const _spots = [(0.22, 0.2, 0.62), (0.82, 0.5, 0.55), (0.42, 0.82, 0.5)];

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.longestSide * 0.5;
    for (var i = 0; i < _spots.length; i++) {
      final (x, y, strength) = _spots[i];
      final center = Offset(size.width * x, size.height * y);
      final color = colors[i % colors.length];
      final paint = Paint()
        ..blendMode = BlendMode.screen
        ..shader = RadialGradient(
          stops: const [0, 0.55, 1],
          colors: [
            color.withValues(alpha: strength),
            color.withValues(alpha: strength * 0.45),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraGlowPainter oldDelegate) => !listEquals(oldDelegate.colors, colors);
}

/// كبسولة السعر الداكنة وزر المفضلة الداكن، متجاوران في زاوية النهاية (يسار بالعربية).
class _AuroraTopRow extends StatelessWidget {
  const _AuroraTopRow({required this.course, this.onFavoritePressed});

  final CourseModel course;
  final Future<void> Function()? onFavoritePressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // الضغط على السعر يفتح الدورة كباقي البطاقة.
        Flexible(
          child: IgnorePointer(child: _AuroraPricePill(course: course)),
        ),
        const SizedBox(width: 4),
        CourseFavoriteButton(courseId: course.id, diameter: 32, dark: true, onPressed: onFavoritePressed),
      ],
    );
  }
}

class _AuroraPricePill extends StatelessWidget {
  const _AuroraPricePill({required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    final parts = course.price.trim().split(RegExp(r'\s+'));
    final amount = parts.first;
    final currency = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    final onRequest = amount == '—';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _auroraInk.withValues(alpha: 0.45),
        borderRadius: AppCorners.full,
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text.rich(
            maxLines: 1,
            TextSpan(
              children: [
                TextSpan(
                  text: onRequest ? 'price_on_request'.tr : amount,
                  style: AppFonts.tajawal(
                    fontSize: AppTextSize.sm,
                    fontWeight: onRequest ? FontWeight.w600 : FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                if (!onRequest && currency.isNotEmpty)
                  TextSpan(
                    text: ' $currency',
                    style: AppFonts.tajawal(
                      fontSize: AppTextSize.xs,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// اللوح الزجاجي: ضبابية حقيقية للغلاف تحته + حبر داكن شفاف (تباين النص الأبيض) + حافة فاتحة.
class _AuroraGlassPanel extends StatelessWidget {
  const _AuroraGlassPanel({required this.course, required this.spec});

  final CourseModel course;
  final CourseAuroraSpec spec;

  /// ضبابية مع تشبّع أعلى قليلاً: زجاج ملوّن بألوان الصورة لا رمادي باهت.
  static final ui.ImageFilter _frost = ui.ImageFilter.compose(
    outer: const ColorFilter.matrix(_saturate),
    inner: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
  );

  /// مصفوفة تشبّع ×1.3 (أوزان الإضاءة Rec. 709).
  static const List<double> _saturate = [
    1.2364, -0.2146, -0.0218, 0, 0, //
    -0.0636, 1.0854, -0.0218, 0, 0, //
    -0.0636, -0.2146, 1.2782, 0, 0, //
    0, 0, 0, 1, 0,
  ];

  static const double _frostedInkAlpha = 0.34;
  static const double _flatInkAlpha = 0.52;

  /// التمويه الحقيقي (BackdropFilter) أغلى ما في البطاقة: يُوقَف أثناء حركة الانتقال (فتح صفحة أو إغلاقها)
  /// بلوح معتّم أخفّ يحاكيه، ويعود حين تستقر الصفحة.
  @override
  Widget build(BuildContext context) {
    return RouteMotionBuilder(
      builder: (context, inMotion) {
        final decorated = DecoratedBox(
          decoration: BoxDecoration(
            color: _auroraInk.withValues(alpha: inMotion ? _flatInkAlpha : _frostedInkAlpha),
            borderRadius: AppCorners.md,
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: _content(),
        );
        return ClipRRect(
          borderRadius: AppCorners.md,
          child: inMotion ? decorated : BackdropFilter(filter: _frost, child: decorated),
        );
      },
    );
  }

  Widget _content() {
    const white = Colors.white;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spec.panelPadding, vertical: CourseAuroraSpec.panelPaddingV),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: spec.categoryHeight,
            child: _AuroraCategoryLine(course: course),
          ),
          const SizedBox(height: CourseAuroraSpec.gapAfterCategory),
          SizedBox(
            height: spec.titleHeight,
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: BidiText(
                course.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.tajawal(
                  fontSize: spec.titleSize,
                  fontWeight: FontWeight.w800,
                  height: CourseAuroraSpec.titleLineHeight,
                  color: white,
                ),
              ),
            ),
          ),
          const SizedBox(height: CourseAuroraSpec.gapAfterTitle),
          SizedBox(
            height: spec.metaHeight,
            child: _AuroraMetaLine(course: course),
          ),
        ],
      ),
    );
  }
}

/// «البرمجة · مبتدئ» بأبيض خافت. لا مستوى غير معروف.
class _AuroraCategoryLine extends StatelessWidget {
  const _AuroraCategoryLine({required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    final category = course.categoryName?.trim() ?? '';
    final level = (course.levelCode ?? '').trim().isEmpty ? '' : course.level.trim();
    final text = [category, level].where((p) => p.isNotEmpty).join(' · ');
    if (text.isEmpty) return const SizedBox.shrink();
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppFonts.tajawal(
          fontSize: AppTextSize.xs,
          fontWeight: FontWeight.w700,
          height: 1.3,
          color: Colors.white.withValues(alpha: 0.86),
        ),
      ),
    );
  }
}

/// «★ 4.8 · 8 أسابيع»: التقييم (أو «بلا تقييم») ثم المدة بالأسابيع، أو بالساعات/الجلسات إن غاب التاريخان.
class _AuroraMetaLine extends StatelessWidget {
  const _AuroraMetaLine({required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    final weeks = course.durationWeeks;
    final duration = weeks != null ? pluralTr('card_weeks', weeks) : (course.duration == '—' ? '' : course.duration);
    final style = AppFonts.tajawal(
      fontSize: AppTextSize.xs,
      fontWeight: FontWeight.w600,
      height: 1.2,
      color: Colors.white.withValues(alpha: 0.92),
    );
    return Row(
      children: [
        if (course.hasRating) ...[
          const Icon(Icons.star_rounded, size: 13, color: AppColors.ratingStar),
          const SizedBox(width: 3),
          Text(course.rating.toStringAsFixed(1), textDirection: TextDirection.ltr, style: style),
        ] else
          Flexible(
            child: Text('rating_none_short'.tr, maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
          ),
        if (duration.isNotEmpty) ...[
          Text('  ·  ', style: style),
          Flexible(
            child: Text(duration, maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
          ),
        ],
      ],
    );
  }
}
