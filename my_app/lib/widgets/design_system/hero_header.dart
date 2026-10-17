part of '../design_system.dart';

/// الهيدر الموحّد لكل صفحات القوائم (الدورات، التصنيف، المعاهد، دوراتي، المفضلة، مدرّسو التخصص):
/// تدرّج بنفسجي بقاع مدوّر، زر رجوع اختياري، كبسولة عدّاد، عنوان، وسطر فرعي.
/// صف الكبسولة محجوز دائماً (حتى قبل وصول العدد) فيبقى ارتفاع الهيدر واحداً في كل الصفحات.
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

    // بعرض الشاشة دائماً، حتى داخل Column محاذاته للبداية (crossAxisAlignment.start).
    return SizedBox(
      width: double.infinity,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.lg)),
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
                          tooltip: 'back'.tr,
                          onPressed: onBack,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                        SizedBox(height: compact ? 4 : 8),
                      ],
                      // بلا عدد بعد: كبسولة شفافة بنفس الحجم. في جهة النهاية، مقابل بداية العنوان.
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Opacity(
                          opacity: badge == null ? 0 : 1,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(AppRadius.full),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Text(
                              badge ?? ' ',
                              style: AppFonts.tajawal(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: AppTextSize.xs,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.tajawal(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: compact ? AppTextSize.xxl : AppTextSize.display,
                          height: 1.2,
                        ),
                      ),
                      if (subtitle != null && !compact) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.tajawal(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: AppTextSize.sm,
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
      ),
    );
  }
}
