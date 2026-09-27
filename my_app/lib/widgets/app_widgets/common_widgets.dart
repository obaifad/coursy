part of '../app_widgets.dart';

/// سعر الدورة: مبلغ عريض + عملة أصغر
class CoursePriceText extends StatelessWidget {
  const CoursePriceText({super.key, required this.price, this.amountSize = 13, this.currencySize = 10});

  final String price;
  final double amountSize;
  final double currencySize;

  @override
  Widget build(BuildContext context) {
    final parts = price.trim().split(RegExp(r'\s+'));
    final amount = parts.isNotEmpty ? parts.first : price;
    final currency = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    return Text.rich(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.end,
      TextSpan(
        children: [
          TextSpan(
            text: amount,
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: amountSize, height: 1.1),
          ),
          if (currency.isNotEmpty)
            TextSpan(
              text: ' $currency',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: currencySize),
            ),
        ],
      ),
    );
  }
}

/// صورة شبكة تعمل على الويب بدون مشاكل CORS (تفضّل عنصر HTML img).
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.errorWidget,
    this.ignorePointer = false,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? errorWidget;

  /// true داخل كروت قابلة للنقر حتى لا تحجب الصورة ضغطة الـ InkWell.
  final bool ignorePointer;

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);

    Widget imageForSize(double? w, double? h) {
      final hasExplicitSize = w != null && h != null && w.isFinite && h.isFinite && w > 0 && h > 0;
      final fallback = errorWidget ?? const SizedBox.shrink();
      if (kIsWeb) {
        return Image.network(
          url,
          width: hasExplicitSize ? w : null,
          height: hasExplicitSize ? h : null,
          fit: fit,
          webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
          errorBuilder: (_, __, ___) => fallback,
        );
      }
      // كاش على القرص (لا يُعاد التنزيل عند كل تشغيل) + فك الصورة بحجم العرض فقط لا بحجمها الأصلي.
      return CachedNetworkImage(
        imageUrl: url,
        width: hasExplicitSize ? w : null,
        height: hasExplicitSize ? h : null,
        fit: fit,
        memCacheWidth: hasExplicitSize ? (w * pixelRatio).round() : null,
        fadeInDuration: const Duration(milliseconds: 150),
        errorWidget: (_, __, ___) => fallback,
      );
    }

    Widget content;
    if (width != null && height != null) {
      content = SizedBox(width: width, height: height, child: imageForSize(width, height));
    } else {
      content = LayoutBuilder(
        builder: (context, constraints) {
          final w = width ?? (constraints.maxWidth.isFinite ? constraints.maxWidth : null);
          final h = height ?? (constraints.maxHeight.isFinite ? constraints.maxHeight : null);
          final hasExplicitSize = w != null && h != null && w.isFinite && h.isFinite && w > 0 && h > 0;
          if (hasExplicitSize) {
            return SizedBox(width: w, height: h, child: imageForSize(w, h));
          }
          return imageForSize(null, null);
        },
      );
    }

    if (borderRadius != null) {
      content = ClipRRect(borderRadius: borderRadius!, child: content);
    }
    if (ignorePointer) {
      content = IgnorePointer(child: content);
    }
    return content;
  }
}

/// أيقونة مادة/تخصص مدرّس.
class InstructorSubjectIcon extends StatelessWidget {
  const InstructorSubjectIcon({
    super.key,
    required this.subject,
    this.size = 24,
    this.borderRadius,
    this.iconColor,
    this.backgroundColor,
  });

  final InstructorSubjectModel subject;
  final double size;
  final BorderRadius? borderRadius;
  final Color? iconColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(size / 2);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primary.withValues(alpha: 0.1),
        borderRadius: radius,
      ),
      alignment: Alignment.center,
      child: Icon(subject.iconData, size: size * 0.52, color: iconColor ?? AppColors.primary),
    );
  }
}

/// أيقونة تصنيف من slug الـ API (code, palette, languages...).
class CategoryIcon extends StatelessWidget {
  const CategoryIcon({
    super.key,
    required this.category,
    this.size = 24,
    this.borderRadius,
    this.iconColor,
    this.backgroundColor,
  });

  final CategoryModel category;
  final double size;
  final BorderRadius? borderRadius;
  final Color? iconColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(size / 2);
    final imageUrl = category.iconImageUrl;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primary.withValues(alpha: 0.1),
        borderRadius: radius,
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: imageUrl != null
          ? Padding(
              padding: EdgeInsets.all(size * 0.14),
              child: AppNetworkImage(url: imageUrl, width: size * 0.72, height: size * 0.72, fit: BoxFit.contain),
            )
          : Icon(category.iconData, size: size * 0.52, color: iconColor ?? AppColors.primary),
    );
  }
}

/// عنوان قسم + محتوى (قديم — ي favor AppSectionHeader للعناوين الجديدة)
class AppSection extends StatelessWidget {
  const AppSection({super.key, required this.title, required this.child, this.action});

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),
            if (action != null) action!,
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

/// شارة معلومات صغيرة (نوع الدراسة، الساعات).
class CourseMetaChip extends StatelessWidget {
  const CourseMetaChip({super.key, required this.icon, required this.label, this.compact = false});

  final IconData icon;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 3 : 4),
      decoration: BoxDecoration(color: AppColors.neutralFill, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: compact ? 12 : 14, color: AppColors.textSecondary),
          SizedBox(width: compact ? 5 : 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.tajawal(
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({super.key, required this.message, required this.cta, this.onCta});

  final String message;
  final String cta;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.primary,
                boxShadow: const [BoxShadow(color: AppColors.shadowPurple, blurRadius: 24, offset: Offset(0, 12))],
              ),
              child: const Icon(Icons.inbox_rounded, size: 56, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: onCta ?? () {}, child: Text(cta)),
            ),
          ],
        ),
      ),
    );
  }
}
