import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/app_models.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_fonts.dart';
import '../../../widgets/app_widgets.dart';
import '../../../widgets/design_system.dart';

/// تدرّج البانر من ألوان الهوية نفسها ([AppColors]): الأغمق عند النص (لتباين الأبيض) والأفتح عند الصورة.
const _bannerGradient = LinearGradient(
  colors: [AppColors.primary, AppColors.primaryLight],
  begin: AlignmentDirectional.centerStart,
  end: AlignmentDirectional.centerEnd,
);

/// بانر الدورات المميزة في الرئيسية: شرائح أفقية بحواف الجيران ظاهرة، تمرير تلقائي كل [interval]،
/// يتوقف عند لمس البطاقة ويستأنف بعد رفع الإصبع، ومؤشر نقاط في الأسفل (بلا أسهم).
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
  static const _viewportFraction = 0.88;
  static const _cardHeight = 210.0;
  static const _pagePadH = 5.0;
  static const _pagePadTop = 4.0;
  static const _pagePadBottom = 16.0;

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

  void _advance() {
    if (!mounted || _held || !_controller.hasClients) return;
    final current = (_controller.page ?? _controller.initialPage.toDouble()).round();
    _controller.animateToPage(current + 1, duration: FeaturedCourseCarousel._transition, curve: Curves.easeInOutCubic);
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
        // Listener لا يدخل في تنافس الإيماءات: يرى اللمس دون أن يعطّل التمرير أو الضغط.
        Listener(
          onPointerDown: (_) => _hold(),
          onPointerUp: (_) => _release(),
          onPointerCancel: (_) => _release(),
          child: SizedBox(
            height: pageHeight,
            child: PageView.builder(
              controller: _controller,
              itemCount: _count > 1 ? null : 1,
              clipBehavior: Clip.none,
              onPageChanged: (page) => _index.value = page % _count,
              itemBuilder: (context, page) {
                final course = courses[page % _count];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                    FeaturedCourseCarousel._pagePadH,
                    FeaturedCourseCarousel._pagePadTop,
                    FeaturedCourseCarousel._pagePadH,
                    FeaturedCourseCarousel._pagePadBottom,
                  ),
                  child: _CourseBannerCard(key: ValueKey<int>(course.id), course: course, onOpen: () => _open(course)),
                );
              },
            ),
          ),
        ),
        if (_count > 1) _DotsIndicator(count: _count, index: _index),
      ],
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({required this.count, required this.index});

  final int count;
  final ValueNotifier<int> index;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ValueListenableBuilder<int>(
        valueListenable: index,
        builder: (context, current, _) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == current ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == current ? AppColors.primary : AppColors.indicatorFill,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CourseBannerCard extends StatelessWidget {
  const _CourseBannerCard({super.key, required this.course, required this.onOpen});

  final CourseModel course;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22);
    return Semantics(
      button: true,
      label: course.title,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: const [BoxShadow(color: AppColors.shadowPrimary, blurRadius: 18, offset: Offset(0, 8))],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Material(
            color: Colors.transparent,
            child: Ink(
              decoration: const BoxDecoration(gradient: _bannerGradient),
              child: InkWell(
                onTap: onOpen,
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(18, 16, 16, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 55,
                        child: _TextSide(course: course, onOpen: onOpen),
                      ),
                      const SizedBox(width: 14),
                      Expanded(flex: 45, child: _ImageSide(course: course)),
                    ],
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

class _TextSide extends StatelessWidget {
  const _TextSide({required this.course, required this.onOpen});

  final CourseModel course;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final duration = course.duration;
    final instructor = course.instructor?.name.trim() ?? '';
    // سطران كحد أقصى: المعهد والمدة، والمدرّس بديل لأيٍّ منهما إن غاب.
    final meta = <(IconData, String)>[
      if (course.institute.trim().isNotEmpty) (Icons.apartment_rounded, course.institute.trim()),
      if (duration != '—') (Icons.schedule_rounded, duration),
      if (instructor.isNotEmpty) (Icons.person_outline_rounded, instructor),
    ].take(2);
    final badge = course.isFeatured ? 'featured_course'.tr : (course.categoryName?.trim() ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GlassBadge(label: badge.isEmpty ? 'featured_course'.tr : badge),
        const SizedBox(height: 10),
        Text(
          course.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.tajawal(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17, height: 1.35),
        ),
        const SizedBox(height: 8),
        for (final (icon, text) in meta) _MetaRow(icon: icon, text: text),
        const Spacer(),
        _PrimaryButton(label: 'book_now'.tr, onTap: onOpen),
      ],
    );
  }
}

/// كبسولة زجاجية شبه شفافة — بلا BackdropFilter (الخلفية تدرّج ناعم، والضبابية مكلفة داخل PageView).
class _GlassBadge extends StatelessWidget {
  const _GlassBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                style: AppFonts.tajawal(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.tajawal(
                color: Colors.white.withValues(alpha: 0.92),
                fontWeight: FontWeight.w500,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: AppColors.shadowPrimaryStrong, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            // يصغّر المحتوى بدل أن يفيض على الشاشات الضيقة أو مع خط كبير.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    style: AppFonts.tajawal(color: AppColors.primaryDark, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  const SizedBox(width: 6),
                  // arrow_forward ينعكس تلقائياً في العربية فيشير لليسار.
                  const Icon(Icons.arrow_forward_rounded, color: AppColors.primaryDark, size: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// صورة الدورة (أو المدرّس) داخل إطار مستدير ناعم، ووسم الخصم على زاويتها العليا.
class _ImageSide extends StatelessWidget {
  const _ImageSide({required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    final imageUrl = course.resolvedImageUrl ?? course.instructor?.resolvedImageUrl;
    final percent = course.discountPercent;
    final fallback = _ImageFallback(label: course.categoryName);

    return RepaintBoundary(
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                    boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.18), blurRadius: 16)],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: imageUrl == null
                        ? fallback
                        : AppNetworkImage(url: imageUrl, ignorePointer: true, errorWidget: fallback),
                  ),
                ),
              ),
              if (percent != null) PositionedDirectional(top: -6, start: -6, child: _DiscountTag(percent: percent)),
            ],
          ),
        ),
      ),
    );
  }
}

/// بلا صورة: مربع متدرّج من ألوان الهوية مع شارة دورة صغيرة واسم التصنيف.
class _ImageFallback extends StatelessWidget {
  const _ImageFallback({this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final text = label?.trim() ?? '';
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGradients.primary),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 24),
            ),
            if (text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.tajawal(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// وسم الخصم العائم: كهرماني بنص داكن، بطيّة صغيرة تحت حافته الخارجية كأنه ملتف حول الإطار.
class _DiscountTag extends StatelessWidget {
  const _DiscountTag({required this.percent});

  final int percent;

  static const _fill = [Color(0xFFFFE08A), Color(0xFFFFC14D)];
  static const _fold = Color(0xFFD99A2B);
  static const _text = Color(0xFF5A3300);

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: _fill),
            borderRadius: const BorderRadiusDirectional.only(
              topStart: Radius.circular(6),
              topEnd: Radius.circular(10),
              bottomEnd: Radius.circular(10),
            ).resolve(direction),
            boxShadow: const [BoxShadow(color: AppColors.shadowPrimaryStrong, blurRadius: 8, offset: Offset(0, 3))],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Text(
              'banner_discount'.trParams({'percent': '$percent'}),
              maxLines: 1,
              style: AppFonts.tajawal(color: _text, fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
        ),
        CustomPaint(size: const Size(6, 6), painter: _FoldPainter(_fold, direction)),
      ],
    );
  }
}

/// مثلث الطيّة تحت الطرف الخارجي (start) للوسم.
class _FoldPainter extends CustomPainter {
  _FoldPainter(this.color, this.direction);

  final Color color;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0);
    if (direction == TextDirection.rtl) {
      path.lineTo(size.width, size.height);
    } else {
      path.lineTo(0, size.height);
    }
    canvas.drawPath(path..close(), Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _FoldPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.direction != direction;
}
