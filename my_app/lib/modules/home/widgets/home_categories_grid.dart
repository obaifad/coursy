import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/locale/plural.dart';
import '../../../core/models/app_models.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_fonts.dart';
import '../../../widgets/app_widgets.dart';

/// تصنيفات الرئيسية: شبكة 4 أعمدة × صفّين. أكثر 7 تصنيفات دورات، والثامنة بطاقة «+X كل التصنيفات»
/// حين يزيد العدد عن 8 (وإلا تُعرض كلها بلا بطاقة إضافية).
class HomeCategoriesGrid extends StatelessWidget {
  const HomeCategoriesGrid({
    super.key,
    required this.categories,
    required this.onOpenCategory,
    required this.onShowAll,
  });

  final List<CategoryModel> categories;
  final ValueChanged<CategoryModel> onOpenCategory;
  final VoidCallback onShowAll;

  static const int columns = 4;
  static const int _slots = 8;

  @override
  Widget build(BuildContext context) {
    final sorted = [...categories]..sort((a, b) => b.coursesCount.compareTo(a.coursesCount));
    final hasMore = sorted.length > _slots;
    final shown = sorted.take(hasMore ? _slots - 1 : _slots).toList();
    final remaining = sorted.length - shown.length;

    final tiles = <Widget>[
      for (final category in shown)
        _CategoryGridTile(category: category, colors: _pastelFor(category), onTap: () => onOpenCategory(category)),
      if (hasMore) _AllCategoriesTile(remaining: remaining, onTap: onShowAll),
    ];

    return Column(
      children: [
        for (var row = 0; row * columns < tiles.length; row++) ...[
          if (row > 0) const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var col = 0; col < columns; col++) ...[
                if (col > 0) const SizedBox(width: 8),
                Expanded(child: row * columns + col < tiles.length ? tiles[row * columns + col] : const SizedBox()),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

/// خلفية باستيل + أيقونة بدرجة أغمق من نفس اللون. الخلفية مشتقة من لون الأيقونة (14% فوق الأبيض)
/// فيبقى الزوج متناسقاً دائماً.
typedef _Pastel = ({Color background, Color icon});

_Pastel _pastel(Color icon) => (background: Color.lerp(Colors.white, icon, 0.14)!, icon: icon);

const _purple = AppColors.primary;
const _blue = Color(0xFF2F80ED);
const _pink = Color(0xFFEC4899);
const _amber = AppColors.warning;
const _teal = Color(0xFF0D9488);
const _green = AppColors.success;
const _orange = Color(0xFFEF6C57);
const _violet = Color(0xFF8B5CF6);

/// لون ثابت لكل تصنيف من اسمه (عربي أو إنجليزي)، وإلا من معرّفه — نفس اللون في كل مرة.
_Pastel _pastelFor(CategoryModel category) {
  final name = '${category.nameAr} ${category.nameEn}'.toLowerCase();
  bool has(List<String> keys) => keys.any(name.contains);
  if (has(['برمج', 'program', 'code', 'تطوير'])) return _pastel(_purple);
  if (has(['لغ', 'language', 'english', 'إنجليز'])) return _pastel(_blue);
  if (has(['تصم', 'design', 'جرافيك', 'graphic'])) return _pastel(_pink);
  if (has(['أعمال', 'business', 'إدار', 'manage'])) return _pastel(_amber);
  if (has(['ذكاء', 'artificial', ' ai', 'بيانات', 'data'])) return _pastel(_teal);
  if (has(['عمار', 'archit', 'هندس', 'engineer'])) return _pastel(_green);
  if (has(['تسويق', 'market'])) return _pastel(_orange);
  const fallback = [_purple, _blue, _pink, _amber, _teal, _green, _orange, _violet];
  return _pastel(fallback[category.id.abs() % fallback.length]);
}

/// مربع الأيقونة وارتفاع النصين أسفله — مشتركان بين التصنيف وبطاقة «كل التصنيفات» لتتساوى المحاذاة.
const double _boxRadius = 20;

double _boxSize(double width) => (width * 0.8).clamp(52.0, 72.0);

class _CategoryGridTile extends StatelessWidget {
  const _CategoryGridTile({required this.category, required this.colors, required this.onTap});

  final CategoryModel category;
  final _Pastel colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final count = category.coursesCount;
    return _PressableTile(
      semanticsLabel: count > 0 ? '${category.name}، ${pluralTr('category_courses_count', count)}' : category.name,
      onTap: onTap,
      builder: (box) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: box,
            height: box,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: colors.background, borderRadius: BorderRadius.circular(_boxRadius)),
            child: CategoryIcon(
              category: category,
              size: box * 0.78,
              borderRadius: BorderRadius.circular(8),
              iconColor: colors.icon,
              backgroundColor: Colors.transparent,
            ),
          ),
          const SizedBox(height: 8),
          _TileLabel(
            text: category.name,
            style: AppFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          _TileLabel(
            text: count > 0 ? pluralTr('category_courses_count', count) : '',
            style: AppFonts.tajawal(fontWeight: FontWeight.w600, fontSize: 11, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

class _AllCategoriesTile extends StatelessWidget {
  const _AllCategoriesTile({required this.remaining, required this.onTap});

  final int remaining;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PressableTile(
      semanticsLabel: 'all_categories'.tr,
      onTap: onTap,
      builder: (box) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            // فوق التعبئة البيضاء — painter (خلفي) كانت تغطيه.
            foregroundPainter: const _DashedRRectPainter(color: AppColors.primaryLight, radius: _boxRadius),
            child: Container(
              width: box,
              height: box,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(_boxRadius)),
              child: Text(
                '+$remaining',
                textDirection: TextDirection.ltr,
                style: AppFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _TileLabel(
            text: 'all_categories'.tr,
            style: AppFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary),
          ),
          const SizedBox(height: 2),
          _TileLabel(text: '', style: AppFonts.tajawal(fontSize: 11)),
        ],
      ),
    );
  }
}

/// سطر واحد يصغّر نفسه بدل القصّ حين يطول الاسم (مثل «الذكاء الاصطناعي» في عمود ضيق).
class _TileLabel extends StatelessWidget {
  const _TileLabel({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(text.isEmpty ? ' ' : text, maxLines: 1, textAlign: TextAlign.center, style: style),
      ),
    );
  }
}

/// تصغير خفيف عند الضغط، ومقاس المربع من عرض العمود.
class _PressableTile extends StatefulWidget {
  const _PressableTile({required this.semanticsLabel, required this.onTap, required this.builder});

  final String semanticsLabel;
  final VoidCallback onTap;
  final Widget Function(double boxSize) builder;

  @override
  State<_PressableTile> createState() => _PressableTileState();
}

class _PressableTileState extends State<_PressableTile> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticsLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1,
          duration: const Duration(milliseconds: 110),
          child: LayoutBuilder(builder: (context, constraints) => widget.builder(_boxSize(constraints.maxWidth))),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 5.0;
    const gap = 4.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)).deflate(0.75);
    for (final PathMetric metric in (Path()..addRRect(rrect)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
