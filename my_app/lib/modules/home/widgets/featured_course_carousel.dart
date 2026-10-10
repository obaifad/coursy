import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/app_models.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_fonts.dart';
import '../../../widgets/app_widgets.dart';
import '../../../widgets/design_system.dart';

/// ألوان البانر — بنفسجي داكن مستقل عن بنفسجي واجهة التطبيق الفاتح ليبرز فوق الخلفية.
abstract final class _BannerPalette {
  static const gradientStart = Color(0xFF4A154B);
  static const gradientEnd = Color(0xFF2B0A3D);
  static const glow = Color(0xFF8E7CFF);
  static const metaText = Color(0xFFD9CCF5);
  static const dotActive = Color(0xFFB9A8FF);
  static const ctaStart = Color(0xFFFFB84D);
  static const ctaEnd = Color(0xFFFF7A1A);
}

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

  /// يُستدعى عند الضغط على البطاقة أو أحد زريها. الافتراضي: صفحة تفاصيل الدورة.
  final ValueChanged<CourseModel>? onOpenCourse;
  final Duration interval;

  static const _transition = Duration(milliseconds: 700);
  static const _viewportFraction = 0.88;
  static const _cardHeight = 222.0;
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
                  color: i == current ? _BannerPalette.dotActive : AppColors.primary.withValues(alpha: 0.2),
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
    final radius = BorderRadius.circular(20);
    return Semantics(
      button: true,
      label: course.title,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: _BannerPalette.gradientEnd.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Material(
            color: Colors.transparent,
            child: Ink(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_BannerPalette.gradientStart, _BannerPalette.gradientEnd],
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                ),
              ),
              child: InkWell(
                onTap: onOpen,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const Positioned.fill(child: BrandBannerPattern()),
                    // وهج خلف الصورة.
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const AlignmentDirectional(-0.75, -0.1),
                            radius: 0.85,
                            colors: [_BannerPalette.glow.withValues(alpha: 0.42), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 10, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 58,
                            child: _TextSide(course: course, onOpen: onOpen),
                          ),
                          const SizedBox(width: 8),
                          Expanded(flex: 42, child: _VisualSide(course: course)),
                        ],
                      ),
                    ),
                  ],
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
    final instructor = course.instructor?.name.trim() ?? '';
    final institute = course.institute.trim();
    final duration = course.duration;
    final badge = course.isFeatured ? 'featured_course'.tr : (course.categoryName?.trim() ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _GlassBadge(label: badge.isEmpty ? 'featured_course'.tr : badge),
        const SizedBox(height: 8),
        Text(
          course.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.tajawal(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17, height: 1.25),
        ),
        const SizedBox(height: 6),
        if (instructor.isNotEmpty) _MetaRow(icon: Icons.person_outline_rounded, text: instructor),
        if (institute.isNotEmpty) _MetaRow(icon: Icons.apartment_rounded, text: institute),
        if (duration != '—') _MetaRow(icon: Icons.schedule_rounded, text: duration),
        const Spacer(),
        Row(
          children: [
            Flexible(
              child: _PrimaryButton(label: 'book_now'.tr, onTap: onOpen),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: _SecondaryButton(label: 'course_details'.tr, onTap: onOpen),
            ),
          ],
        ),
      ],
    );
  }
}

/// كبسولة زجاجية شبه شفافة (تعبئة وحد أبيضان خفيفان) — بلا BackdropFilter لأن الخلفية تدرّج ناعم
/// فلا فرق مرئي للضبابية، وهي مكلفة داخل PageView.
class _GlassBadge extends StatelessWidget {
  const _GlassBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt_rounded, color: _BannerPalette.ctaStart, size: 14),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.tajawal(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
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
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 13, color: _BannerPalette.metaText),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.tajawal(color: _BannerPalette.metaText, fontWeight: FontWeight.w500, fontSize: 11.5),
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
        gradient: const LinearGradient(colors: [_BannerPalette.ctaStart, _BannerPalette.ctaEnd]),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: _BannerPalette.ctaEnd.withValues(alpha: 0.45), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            // الأغمق فوق البرتقالي: الأبيض عليه تباينه ضعيف.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: AppFonts.tajawal(color: _BannerPalette.gradientEnd, fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.2),
          ),
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: AppFonts.tajawal(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// الجانب البصري: إطار دائري متوهج بصورة الدورة (أو المدرّس إن لم تتوفر)، أيقونات عائمة، وشريط الخصم.
class _VisualSide extends StatelessWidget {
  const _VisualSide({required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    final imageUrl = course.resolvedImageUrl ?? course.instructor?.resolvedImageUrl;
    final percent = course.discountPercent;

    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final d =
              (constraints.maxWidth < constraints.maxHeight ? constraints.maxWidth : constraints.maxHeight) * 0.88;
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: d,
                height: d,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB9A8FF), Color(0xFFE056C9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(color: _BannerPalette.glow.withValues(alpha: 0.55), blurRadius: 22, spreadRadius: 1),
                  ],
                ),
                child: ClipOval(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(color: _BannerPalette.gradientEnd),
                    child: imageUrl == null
                        ? const _ImageFallback()
                        : AppNetworkImage(
                            url: imageUrl,
                            width: d - 8,
                            height: d - 8,
                            ignorePointer: true,
                            errorWidget: const _ImageFallback(),
                          ),
                  ),
                ),
              ),
              const PositionedDirectional(top: 0, end: 0, child: _FloatingIcon(icon: Icons.code_rounded)),
              const PositionedDirectional(
                top: 22,
                start: -4,
                child: _FloatingIcon(icon: Icons.laptop_mac_rounded, size: 24),
              ),
              const PositionedDirectional(
                bottom: 22,
                end: -2,
                child: _FloatingIcon(icon: Icons.school_rounded, size: 24),
              ),
              if (percent != null)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _DiscountRibbon(percent: percent),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Icon(Icons.school_rounded, color: Colors.white70, size: 44));
  }
}

class _FloatingIcon extends StatelessWidget {
  const _FloatingIcon({required this.icon, this.size = 28});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.55),
    );
  }
}

class _DiscountRibbon extends StatelessWidget {
  const _DiscountRibbon({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.08,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_BannerPalette.ctaStart, _BannerPalette.ctaEnd]),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            'banner_discount'.trParams({'percent': '$percent'}),
            maxLines: 1,
            style: AppFonts.tajawal(color: _BannerPalette.gradientEnd, fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
