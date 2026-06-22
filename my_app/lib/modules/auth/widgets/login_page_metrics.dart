import 'package:flutter/material.dart';

import '../../../core/responsive/responsive.dart';

/// مقاسات متجاوبة لشاشات الدخول والتسجيل.
class LoginPageMetrics {
  const LoginPageMetrics({
    required this.logoHeight,
    required this.illustrationSize,
    required this.horizontalPadding,
    required this.pageVerticalPadding,
    required this.headerTopPadding,
    required this.headerBottomPadding,
    required this.welcomeTitleSize,
    required this.welcomeSubtitleSize,
    required this.formVerticalPadding,
    required this.sectionGap,
    required this.fieldGap,
    required this.maxContentWidth,
    required this.splitPanelPadding,
    required this.compactHeader,
    required this.useSplitLayout,
  });

  final double logoHeight;
  final double illustrationSize;
  final double horizontalPadding;
  final double pageVerticalPadding;
  final double headerTopPadding;
  final double headerBottomPadding;
  final double welcomeTitleSize;
  final double welcomeSubtitleSize;
  final double formVerticalPadding;
  final double sectionGap;
  final double fieldGap;
  final double maxContentWidth;
  final double splitPanelPadding;
  final bool compactHeader;
  /// تخطيط نصفين (فورم + لوحة ترحيب) على التابلت وسطح المكتب.
  final bool useSplitLayout;

  static LoginPageMetrics of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final height = size.height;
    final isTablet = width >= AppBreakpoints.mobile;

    if (isTablet) {
      final isDesktop = width >= AppBreakpoints.desktop;
      return LoginPageMetrics(
        logoHeight: isDesktop ? 52 : 48,
        illustrationSize: isDesktop ? 200 : 168,
        horizontalPadding: isDesktop ? 40 : 32,
        pageVerticalPadding: isDesktop ? 32 : 24,
        headerTopPadding: 0,
        headerBottomPadding: 0,
        welcomeTitleSize: isDesktop ? 34 : 30,
        welcomeSubtitleSize: isDesktop ? 17 : 15,
        formVerticalPadding: isDesktop ? 36 : 28,
        sectionGap: isDesktop ? 20 : 16,
        fieldGap: 14,
        maxContentWidth: width * 0.5,
        splitPanelPadding: isDesktop ? 48 : 36,
        compactHeader: true,
        useSplitLayout: true,
      );
    }

    final heightScale = (height / 780).clamp(0.82, 1.06);
    final widthScale = (width / 390).clamp(0.88, 1.10);
    final scale = (heightScale * 0.55 + widthScale * 0.45);

    return LoginPageMetrics(
      logoHeight: (66 * scale).clamp(54.0, 78.0),
      illustrationSize: (114 * scale).clamp(98.0, 130.0),
      horizontalPadding: (width * 0.055).clamp(16.0, 28.0),
      pageVerticalPadding: 0,
      headerTopPadding: (14 * scale).clamp(10.0, 18.0),
      headerBottomPadding: (30 * scale).clamp(24.0, 38.0),
      welcomeTitleSize: (22 * scale).clamp(19.0, 24.0),
      welcomeSubtitleSize: (14 * scale).clamp(12.5, 15.0),
      formVerticalPadding: (16 * scale).clamp(12.0, 20.0),
      sectionGap: (20 * scale).clamp(16.0, 24.0),
      fieldGap: 14,
      maxContentWidth: width - (width * 0.11).clamp(32.0, 56.0),
      splitPanelPadding: 0,
      compactHeader: false,
      useSplitLayout: false,
    );
  }
}
