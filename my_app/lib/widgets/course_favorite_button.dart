import '../core/navigation/route_motion_builder.dart';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../core/services/favorites_service.dart';
import '../core/storage/token_storage.dart';
import '../theme/app_colors.dart';

/// زر المفضلة الموحّد للدورات: دائرة زجاجية صغيرة على زاوية الصورة، وقلب ينبض عند الإضافة.
///
/// يعكس الحالة الجديدة فوراً ثم يتبع ردّ الخادم، ويتجاهل الضغطات حتى ينتهي الطلب. مساحة اللمس 44×44
/// مهما صغرت الدائرة. بلا [FavoritesService] مسجّل (اختبارات البطاقة وحدها) لا يُرسم شيء.
class CourseFavoriteButton extends StatefulWidget {
  const CourseFavoriteButton({
    super.key,
    required this.courseId,
    this.diameter = 34,
    this.blurBackground = false,
    this.dark = false,
    this.onPressed,
  });

  final int courseId;

  /// قطر الدائرة المرئية.
  final double diameter;

  /// تمويه ما خلف الدائرة (زجاج حقيقي). مكلف داخل الشبكات أثناء التمرير — لصفحة الدورة فقط.
  final bool blurBackground;

  /// دائرة زجاجية داكنة بحافة فاتحة وقلب أبيض (فوق الأغلفة الداكنة كبطاقة Aurora)؛ عند الإضافة تصبح
  /// بيضاء بقلب أحمر.
  final bool dark;

  /// بديل للتبديل الافتراضي (شاشة المفضلة: إزالة مع تلاشٍ وتراجع).
  final Future<void> Function()? onPressed;

  /// مساحة اللمس (أقل حد في إرشادات Android) مهما صغرت الدائرة.
  static const tapTarget = 48.0;

  @override
  State<CourseFavoriteButton> createState() => _CourseFavoriteButtonState();
}

class _CourseFavoriteButtonState extends State<CourseFavoriteButton> with SingleTickerProviderStateMixin {
  // يُنشأ في initState لا عند أول استعمال: بطاقة لم يُرسم قلبها بعد كانت تنشئه لأول مرة داخل dispose،
  // فيبحث الـ Ticker عن TickerMode في شجرة معطّلة (assertion «Looking up a deactivated widget's ancestor»).
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.92).chain(CurveTween(curve: Curves.easeInOut)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
    ]).animate(_pulse);
  }

  /// الحالة المعروضة أثناء الطلب (null = حالة الخادم).
  bool? _optimistic;
  bool _busy = false;

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _toggle(FavoritesService service) async {
    if (_busy) return;
    final current = service.isCourseFavorite(widget.courseId);
    final loggedIn = Get.isRegistered<TokenStorage>() && Get.find<TokenStorage>().isLoggedIn;
    // الضيف يرى نافذة تسجيل الدخول أولاً — لا نقلب القلب قبلها.
    setState(() {
      _busy = true;
      if (loggedIn) _optimistic = !current;
    });
    if (loggedIn) {
      if (current) {
        HapticFeedback.selectionClick();
      } else {
        HapticFeedback.lightImpact();
        if (!MediaQuery.disableAnimationsOf(context)) _pulse.forward(from: 0);
      }
    }
    try {
      await (widget.onPressed?.call() ?? service.toggleCourse(widget.courseId));
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _optimistic = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<FavoritesService>()) return const SizedBox.shrink();
    final service = Get.find<FavoritesService>();
    return Obx(() {
      final isFavorite = _optimistic ?? service.isCourseFavorite(widget.courseId);
      final label = isFavorite ? 'favorite_remove'.tr : 'favorite_add'.tr;
      final iconSize = widget.diameter * 0.53;
      // عقدة مستقلة (container) لها نقرها: excludeSemantics يُسقط نقر GestureDetector، وبلا container يُدمج
      // اسم الزر في عنصر البطاقة فلا يُفعَّل من TalkBack إلا فتح الدورة.
      return Semantics(
        container: true,
        button: true,
        toggled: isFavorite,
        label: label,
        onTap: () => _toggle(service),
        excludeSemantics: true,
        child: Tooltip(
          message: label,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _toggle(service),
            child: SizedBox.square(
              dimension: CourseFavoriteButton.tapTarget,
              child: Center(
                child: ScaleTransition(
                  scale: _scale,
                  child: _GlassCircle(
                    diameter: widget.diameter,
                    blur: widget.blurBackground,
                    dark: widget.dark,
                    active: isFavorite,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                      child: Icon(
                        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        key: ValueKey(isFavorite),
                        size: iconSize,
                        color: isFavorite ? AppColors.danger : (widget.dark ? Colors.white : AppColors.textPrimary),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

/// دائرة بيضاء نصف شفافة بحافة لامعة وظل خفيف — تبقى مقروءة فوق الصور الفاتحة والداكنة.
class _GlassCircle extends StatelessWidget {
  const _GlassCircle({
    required this.diameter,
    required this.blur,
    required this.child,
    this.dark = false,
    this.active = false,
  });

  final double diameter;
  final bool blur;
  final Widget child;
  final bool dark;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final fill = dark
        ? AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? Colors.white : const Color(0xFF0F0C28).withValues(alpha: 0.45),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Center(child: child),
          )
        : DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: [
                  Colors.white.withValues(alpha: blur ? 0.78 : 0.92),
                  Colors.white.withValues(alpha: blur ? 0.58 : 0.8),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1),
            ),
            child: Center(child: child),
          );
    return DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: SizedBox.square(
        dimension: diameter,
        // التمويه الحقيقي يُوقَف أثناء حركة الانتقال (فوق غلاف يتلاشى مع الصفحة كان يُرسم في كل إطار).
        child: blur
            ? RouteMotionBuilder(
                builder: (context, inMotion) => inMotion
                    ? fill
                    : ClipOval(
                        child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: fill),
                      ),
              )
            : fill,
      ),
    );
  }
}
