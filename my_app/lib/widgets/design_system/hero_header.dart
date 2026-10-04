part of '../design_system.dart';

/// هيدر صفحة بنفسجي متدرّج بقاع مدوّر — نفس أسلوب "كل الدورات" و"فئة الدورات":
/// زر رجوع اختياري، كبسولة (عدّاد)، عنوان كبير، وسطر فرعي.
class AppHeroHeader extends StatelessWidget {
  const AppHeroHeader({super.key, required this.title, this.subtitle, this.badge, this.onBack});

  final String title;
  final String? subtitle;

  /// نص الكبسولة الصغيرة فوق العنوان (مثل «3 دورات»).
  final String? badge;

  /// إن وُجد يظهر زر رجوع دائري أعلى الهيدر.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final hPad = AppLayout.horizontalPage(context);
    final compact = MediaQuery.sizeOf(context).height < 700;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.heroBanner),
        child: Stack(
          children: [
            const Positioned.fill(child: BrandBannerPattern()),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withValues(alpha: 0.05), Colors.black.withValues(alpha: 0.38)],
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(hPad, onBack != null ? 4 : 14, hPad, compact ? 16 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onBack != null) ...[
                      IconButton(
                        onPressed: onBack,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                      SizedBox(height: compact ? 4 : 8),
                    ],
                    if (badge != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          badge!,
                          style: AppFonts.tajawal(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      title,
                      style: AppFonts.tajawal(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: compact ? 22 : 24,
                        height: 1.2,
                      ),
                    ),
                    if (subtitle != null && !compact) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: AppFonts.tajawal(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
