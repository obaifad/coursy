import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../core/models/app_models.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_fonts.dart';
import '../../../widgets/app_widgets.dart';

/// بانر الدورات المميزة في الرئيسية — «البطاقات العائمة» (المقترح A): صورة الدورة تملأ بطاقة مرتفعة،
/// شارة وخصم فوقها، ولوح أبيض في أسفلها فيه العنوان والمعهد والمدة وزر حجز دائري. البطاقات الجانبية
/// أصغر (92%) وباهتة، وخلف الحالية توهّج بلون تصنيفها. تمرير تلقائي كل [interval] يتوقف عند اللمس،
/// ومؤشر كبسولة تنزلق بين النقاط.
class FeaturedCourseCarousel extends StatefulWidget {
  const FeaturedCourseCarousel({
    super.key,
    required this.courses,
    this.onOpenCourse,
    this.interval = const Duration(seconds: 5),
  });

  final List<CourseModel> courses;

  /// يُستدعى عند الضغط على البطاقة أو زرّها. الافتراضي: صفحة تفاصيل الدورة.
  final ValueChanged<CourseModel>? onOpenCourse;
  final Duration interval;

  static const _transition = Duration(milliseconds: 700);
  static const _viewportFraction = 0.84;
  static const _cardHeight = 214.0;

  /// فراغ 8px بين البطاقات (4 من كل جهة)، ومساحة فوقها وتحتها لظلّها.
  static const _pagePadH = 4.0;
  static const _pagePadTop = 10.0;
  static const _pagePadBottom = 20.0;

  /// البطاقات الجانبية: حجمها وشفافيتها عند ابتعادها شريحة كاملة عن المنتصف.
  static const _sideScale = 0.92;
  static const _sideOpacity = 0.55;

  @override
  State<FeaturedCourseCarousel> createState() => _FeaturedCourseCarouselState();
}

class _FeaturedCourseCarouselState extends State<FeaturedCourseCarousel> {
  late PageController _controller;
  final _index = ValueNotifier<int>(0);
  Timer? _timer;

  bool _held = false;
  bool _tickerEnabled = true;
  bool _reduceMotion = false;

  int get _count => widget.courses.length;

  /// أكثر من شريحة = قائمة لا نهائية (الصفحة الحالية % العدد) فينتقل التمرير التلقائي للأمام دائماً
  /// حتى من الأخيرة إلى الأولى، بدل الرجوع عبر كل الشرائح.
  int get _startPage => _count > 1 ? _count * 1000 : 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: FeaturedCourseCarousel._viewportFraction, initialPage: _startPage);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // الرئيسية داخل IndexedStack/تحت صفحات أخرى: TickerMode يتعطّل حين لا تكون ظاهرة، فلا نحرّك شيئاً حينها.
    // ignore: deprecated_member_use -- TickerMode.valuesOf exists only from Flutter 3.35; the project supports 3.32.
    _tickerEnabled = TickerMode.of(context);
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _restartTimer();
  }

  @override
  void didUpdateWidget(covariant FeaturedCourseCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.courses.length != _count) {
      _index.value = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) _controller.jumpToPage(_startPage);
      });
    }
    if (oldWidget.interval != widget.interval || oldWidget.courses.length != _count) _restartTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _index.dispose();
    super.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = null;
    if (_count < 2 || _held || !_tickerEnabled || _reduceMotion) return;
    _timer = Timer.periodic(widget.interval, (_) => _advance());
  }

  int get _currentPage => (_controller.page ?? _controller.initialPage.toDouble()).round();

  void _advance() {
    if (!mounted || _held || !_controller.hasClients) return;
    _controller.animateToPage(
      _currentPage + 1,
      duration: FeaturedCourseCarousel._transition,
      curve: Curves.easeInOutCubic,
    );
  }

  /// نقطة المؤشر: أقصر طريق إلى تلك الشريحة من الصفحة الحالية (القائمة لا نهائية).
  void _goTo(int index) {
    if (!_controller.hasClients) return;
    final current = _currentPage;
    final delta = index - current % _count;
    _controller.animateToPage(
      current + delta,
      duration: FeaturedCourseCarousel._transition,
      curve: Curves.easeInOutCubic,
    );
    _restartTimer();
  }

  void _hold() {
    _held = true;
    _timer?.cancel();
    _timer = null;
  }

  void _release() {
    _held = false;
    // مهلة كاملة بعد رفع الإصبع قبل الانتقال التالي.
    _restartTimer();
  }

  void _open(CourseModel course) {
    final callback = widget.onOpenCourse;
    if (callback != null) {
      callback(course);
    } else {
      Get.toNamed(AppRoutes.courseDetails, arguments: course);
    }
  }

  @override
  Widget build(BuildContext context) {
    final courses = widget.courses;
    if (courses.isEmpty) return const SizedBox.shrink();

    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.2);
    final cardHeight = FeaturedCourseCarousel._cardHeight * textScale;
    final pageHeight = cardHeight + FeaturedCourseCarousel._pagePadTop + FeaturedCourseCarousel._pagePadBottom;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: pageHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // التوهّج خلف البطاقة الحالية بلون تصنيفها — ظل كبير بلا فلتر تمويه (أرخص داخل PageView).
              Positioned(
                left: MediaQuery.sizeOf(context).width * 0.14,
                right: MediaQuery.sizeOf(context).width * 0.14,
                top: FeaturedCourseCarousel._pagePadTop + cardHeight * 0.25,
                height: cardHeight * 0.65,
                child: ValueListenableBuilder<int>(
                  valueListenable: _index,
                  builder: (context, i, _) => _Glow(color: _slideColor(courses[i % _count])),
                ),
              ),
              // Listener لا يدخل في تنافس الإيماءات: يرى اللمس دون أن يعطّل التمرير أو الضغط.
              Listener(
                onPointerDown: (_) => _hold(),
                onPointerUp: (_) => _release(),
                onPointerCancel: (_) => _release(),
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _count > 1 ? null : 1,
                  clipBehavior: Clip.none,
                  onPageChanged: (page) => _index.value = page % _count,
                  itemBuilder: (context, page) {
                    final course = courses[page % _count];
                    return _SideSlide(
                      controller: _controller,
                      page: page,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          FeaturedCourseCarousel._pagePadH,
                          FeaturedCourseCarousel._pagePadTop,
                          FeaturedCourseCarousel._pagePadH,
                          FeaturedCourseCarousel._pagePadBottom,
                        ),
                        child: _FloatingCard(
                          key: ValueKey<int>(course.id),
                          course: course,
                          onOpen: () => _open(course),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        if (_count > 1) _PillIndicator(count: _count, index: _index, onSelect: _goTo),
      ],
    );
  }
}

/// لون الشريحة من تصنيف الدورة (خريطة صغيرة في التطبيق — بلا تغيير في الخادم).
Color _slideColor(CourseModel course) {
  final name = (course.categoryName ?? '').toLowerCase();
  bool has(List<String> words) => words.any(name.contains);
  if (has(['تصم', 'design'])) return const Color(0xFFEC4899);
  if (has(['أعمال', 'business', 'تسويق', 'marketing'])) return const Color(0xFF0EA5E9);
  if (has(['لغ', 'language'])) return const Color(0xFF14B8A6);
  if (has(['مال', 'financ', 'account'])) return const Color(0xFFF59E0B);
  if (has(['عمار', 'هندس', 'architect', 'engineer'])) return const Color(0xFFF97316);
  return AppColors.primaryStrong;
}

/// يصغّر البطاقة ويبهتها كلما ابتعدت عن المنتصف (92% و55% عند شريحة كاملة)، من موضع التمرير نفسه.
class _SideSlide extends StatelessWidget {
  const _SideSlide({required this.controller, required this.page, required this.child});

  final PageController controller;
  final int page;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // البطاقة نفسها طبقة مخزّنة: التمرير يغيّر الشفافية والمقياس فقط فوقها بلا إعادة رسمها (صورة وظلال).
    return AnimatedBuilder(
      animation: controller,
      child: RepaintBoundary(child: child),
      builder: (context, child) {
        final position = controller.hasClients && controller.position.haveDimensions
            ? controller.page ?? page.toDouble()
            : controller.initialPage.toDouble();
        final t = (position - page).abs().clamp(0.0, 1.0);
        return Opacity(
          opacity: 1 - (1 - FeaturedCourseCarousel._sideOpacity) * t,
          child: Transform.scale(scale: 1 - (1 - FeaturedCourseCarousel._sideScale) * t, child: child),
        );
      },
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    // طبقة مستقلة: لونه وحده يتحرك (600ms)، فلا يُعاد رسم ما حوله معه، ولا يُعاد رسمه مع التمرير.
    return RepaintBoundary(
      child: IgnorePointer(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.full),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: 40)],
          ),
        ),
      ),
    );
  }
}

class _FloatingCard extends StatelessWidget {
  const _FloatingCard({super.key, required this.course, required this.onOpen});

  final CourseModel course;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.lg);
    final percent = course.discountPercent;
    final badge = course.isFeatured ? 'featured_course'.tr : (course.categoryName?.trim() ?? '');

    return Semantics(
      button: true,
      label: course.title,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: const [
            BoxShadow(color: Color(0x73111827), blurRadius: 20, spreadRadius: -10, offset: Offset(0, 14)),
            BoxShadow(color: Color(0x14111827), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Material(
            color: AppColors.card,
            child: InkWell(
              onTap: onOpen,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _Cover(course: course),
                  // تعتيم خفيف أعلى الصورة: الشارة البيضاء تُقرأ فوق أي صورة فاتحة.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment(0, -0.2),
                        colors: [Color(0x59000000), Color(0x00000000)],
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    top: 12,
                    start: 12,
                    end: 12,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(child: _DarkBadge(label: badge.isEmpty ? 'featured_course'.tr : badge)),
                        const Spacer(),
                        if (percent != null) ...[const SizedBox(width: 8), _DiscountPill(percent: percent)],
                      ],
                    ),
                  ),
                  PositionedDirectional(
                    start: 10,
                    end: 10,
                    bottom: 10,
                    child: _InfoPanel(course: course, onOpen: onOpen),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// صورة الدورة (أو المدرّس) بعرض البطاقة كله؛ بلا صورة: تدرّج بلون التصنيف وأيقونته.
class _Cover extends StatelessWidget {
  const _Cover({required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    final imageUrl = course.resolvedImageUrl ?? course.instructor?.resolvedImageUrl;
    final fallback = _CoverFallback(course: course);
    return RepaintBoundary(
      child: imageUrl == null
          ? fallback
          : AppNetworkImage(url: imageUrl, fit: BoxFit.cover, ignorePointer: true, errorWidget: fallback),
    );
  }
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback({required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    final color = _slideColor(course);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [color, Color.lerp(color, AppColors.primaryStrong, 0.55)!],
        ),
      ),
      // الأيقونة في الجزء العلوي الظاهر فوق اللوح الأبيض.
      child: Align(
        alignment: const Alignment(0, -0.35),
        child: Icon(courseCategoryIcon(course.categoryName, rounded: true), color: Colors.white, size: 52),
      ),
    );
  }
}

class _DarkBadge extends StatelessWidget {
  const _DarkBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: const Color(0x8C111827), borderRadius: BorderRadius.circular(AppRadius.full)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt_rounded, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.tajawal(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: AppTextSize.xs,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscountPill extends StatelessWidget {
  const _DiscountPill({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: const Color(0xFFFFC94D), borderRadius: BorderRadius.circular(AppRadius.full)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          'banner_discount'.trParams({'percent': '$percent'}),
          maxLines: 1,
          style: AppFonts.tajawal(
            color: const Color(0xFF4A2A00),
            fontWeight: FontWeight.w800,
            fontSize: AppTextSize.xs,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

/// اللوح السفلي: أبيض شبه معتم (92%) بدل الزجاج المموّه — التمويه مكلف داخل PageView على الهواتف الضعيفة.
class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.course, required this.onOpen});

  final CourseModel course;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final duration = course.duration;
    final sub = [course.institute.trim(), if (duration != '—') duration].where((s) => s.isNotEmpty).join(' · ');

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: const [BoxShadow(color: Color(0x1F111827), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.tajawal(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: AppTextSize.lg,
                      height: 1.3,
                    ),
                  ),
                  if (sub.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.tajawal(
                        color: const Color(0xFF585669),
                        fontWeight: FontWeight.w500,
                        fontSize: AppTextSize.xs,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            _GoButton(onTap: onOpen),
          ],
        ),
      ),
    );
  }
}

class _GoButton extends StatelessWidget {
  const _GoButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // الدائرة المرئية 44 ومساحة اللمس 48.
    return AppTapTarget(
      label: 'book_now'.tr,
      onTap: onTap,
      child: Tooltip(
        message: 'book_now'.tr,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Color(0x595B52F0), blurRadius: 12, offset: Offset(0, 6))],
          ),
          child: Material(
            color: AppColors.primaryStrong,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              // arrow_forward ينعكس تلقائياً في العربية فيشير لليسار.
              child: const SizedBox.square(
                dimension: 44,
                child: Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// نقاط رمادية وكبسولة بنفسجية تنزلق فوق النقطة الحالية (بارتداد خفيف)، وتنعكس في العربية.
/// كل نقطة تنقل إلى شريحتها، بمساحة لمس أوسع من النقطة نفسها.
class _PillIndicator extends StatelessWidget {
  const _PillIndicator({required this.count, required this.index, required this.onSelect});

  final int count;
  final ValueNotifier<int> index;
  final ValueChanged<int> onSelect;

  static const _dot = 8.0;
  static const _gap = 14.0;
  static const _pill = 22.0;
  static const _pitch = _dot + _gap;

  /// حول كل نقطة: مساحة اللمس 24×24 حولها (8 من كل جهة).
  static const _touchInset = 8.0;

  /// الارتفاع الكلي (النقاط + 4 فوقها وتحتها) — كما كان.
  static const _height = _dot + 8;

  @override
  Widget build(BuildContext context) {
    final width = count * _dot + (count - 1) * _gap;
    // الصندوق يشمل مساحات اللمس كلها: كانت النقاط داخل صندوق بارتفاع 8 والمساحة حولها خارجه، فلا يصلها
    // اللمس (Flutter يختبر اللمس داخل حدود الأب فقط) — عملياً 8px فقط. نفس المكان والشكل.
    // قارئ الشاشة: عنصر واحد قابل للضبط (اسحب للأعلى/للأسفل) بدل ثلاث نقاط صغيرة.
    return ValueListenableBuilder<int>(
      valueListenable: index,
      builder: (context, current, _) => Semantics(
        container: true,
        value: '${current + 1} / $count',
        increasedValue: current + 1 < count ? '${current + 2} / $count' : null,
        decreasedValue: current > 0 ? '$current / $count' : null,
        onIncrease: current + 1 < count ? () => onSelect(current + 1) : null,
        onDecrease: current > 0 ? () => onSelect(current - 1) : null,
        child: ExcludeSemantics(
          child: SizedBox(
            width: width + 2 * _touchInset,
            height: _height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < count; i++)
                  PositionedDirectional(
                    key: ValueKey('carousel-dot-$i'),
                    start: i * _pitch,
                    top: (_height - _dot) / 2 - _touchInset,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelect(i),
                      child: const Padding(
                        padding: EdgeInsets.all(_touchInset),
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: Color(0x2E111827), shape: BoxShape.circle),
                          child: SizedBox.square(dimension: _dot),
                        ),
                      ),
                    ),
                  ),
                AnimatedPositionedDirectional(
                  key: const ValueKey('carousel-pill'),
                  duration: const Duration(milliseconds: 400),
                  curve: const Cubic(0.34, 1.3, 0.5, 1),
                  start: _touchInset + current * _pitch - (_pill - _dot) / 2,
                  top: (_height - _dot) / 2,
                  width: _pill,
                  height: _dot,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.primaryStrong,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                    ),
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

/// مكان البانر أثناء التحميل: نفس مقاس البطاقات العائمة (الحالية في المنتصف والجانبيتان أصغر وباهتتان)
/// ومؤشرها، بوميض هادئ — فلا تظهر بطاقة بديلة ثم تُستبدل.
/// [shimmer] = false حين يكون داخل هيكل صفحة يضيف الوميض بنفسه ([AppHomeSkeleton]).
class FeaturedCourseCarouselPlaceholder extends StatelessWidget {
  const FeaturedCourseCarouselPlaceholder({super.key, this.shimmer = true});

  final bool shimmer;

  /// الارتفاع الكلي (الشرائح + المؤشر) — مطابق لـ [FeaturedCourseCarousel] بعدة شرائح.
  static double heightOf(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.2);
    return FeaturedCourseCarousel._cardHeight * textScale +
        FeaturedCourseCarousel._pagePadTop +
        FeaturedCourseCarousel._pagePadBottom +
        _PillIndicator._dot +
        8;
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.2);
    final cardHeight = FeaturedCourseCarousel._cardHeight * textScale;
    final width = MediaQuery.sizeOf(context).width;
    final page = width * FeaturedCourseCarousel._viewportFraction;
    final cardWidth = page - FeaturedCourseCarousel._pagePadH * 2;
    final radius = BorderRadius.circular(AppRadius.lg);

    Widget card(double scale, double opacity) => Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: radius),
        ),
      ),
    );

    final content = SizedBox(
      height: heightOf(context),
      child: Column(
        children: [
          SizedBox(
            height: cardHeight + FeaturedCourseCarousel._pagePadTop + FeaturedCourseCarousel._pagePadBottom,
            child: Padding(
              padding: const EdgeInsets.only(
                top: FeaturedCourseCarousel._pagePadTop,
                bottom: FeaturedCourseCarousel._pagePadBottom,
              ),
              // الحالية في المنتصف، وحافتا الجارتين ظاهرتان كما في الشرائح الحقيقية.
              child: OverflowBox(
                maxWidth: double.infinity,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    card(FeaturedCourseCarousel._sideScale, FeaturedCourseCarousel._sideOpacity),
                    const SizedBox(width: FeaturedCourseCarousel._pagePadH * 2),
                    card(1, 1),
                    const SizedBox(width: FeaturedCourseCarousel._pagePadH * 2),
                    card(FeaturedCourseCarousel._sideScale, FeaturedCourseCarousel._sideOpacity),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: _PillIndicator._gap),
                  Container(
                    width: i == 0 ? _PillIndicator._pill : _PillIndicator._dot,
                    height: _PillIndicator._dot,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
    return ExcludeSemantics(child: shimmer ? Skeletonizer(enabled: true, child: content) : content);
  }
}
