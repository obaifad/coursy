import 'package:flutter/material.dart';

import './app_fonts.dart';
import 'app_colors.dart';
import 'app_system_ui.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.light),
      scaffoldBackgroundColor: AppColors.surface,
    );
    // كل أنماط الثيم على سلّم الأحجام السبعة (الافتراضي في Material 3 يستخدم 11 و16 و22 و24 و57…)،
    // فأي Text أو ListTile بلا حجم صريح يبقى ضمن السلّم.
    final ramp = AppFonts.tajawalTextTheme(base.textTheme);
    TextStyle? sized(TextStyle? style, double size) => style?.copyWith(fontSize: size);
    final textTheme = ramp.copyWith(
      displayLarge: sized(ramp.displayLarge, AppTextSize.display),
      displayMedium: sized(ramp.displayMedium, AppTextSize.display),
      displaySmall: sized(ramp.displaySmall, AppTextSize.display),
      headlineLarge: sized(ramp.headlineLarge, AppTextSize.display),
      headlineMedium: sized(ramp.headlineMedium, AppTextSize.display),
      headlineSmall: AppFonts.tajawal(
        fontSize: AppTextSize.xxl,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
      titleLarge: AppFonts.tajawal(
        fontSize: AppTextSize.xxl,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
      titleMedium: AppFonts.tajawal(
        fontSize: AppTextSize.xl,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
      titleSmall: sized(ramp.titleSmall, AppTextSize.md),
      bodyLarge: sized(ramp.bodyLarge, AppTextSize.lg),
      bodyMedium: AppFonts.tajawal(
        fontSize: AppTextSize.md,
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
      bodySmall: AppFonts.tajawal(color: AppColors.textSecondary, fontSize: AppTextSize.sm),
      labelLarge: sized(ramp.labelLarge, AppTextSize.md),
      labelMedium: sized(ramp.labelMedium, AppTextSize.xs),
      labelSmall: sized(ramp.labelSmall, AppTextSize.xs),
    );
    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        backgroundColor: AppColors.surface,
        elevation: 0,
        // ظل خفيف حين يمرّ المحتوى تحت الشريط (لون الظل الافتراضي في Material 3 شفاف فلا يتغيّر شيء).
        scrolledUnderElevation: 2,
        shadowColor: AppColors.primary.withValues(alpha: 0.18),
        titleTextStyle: AppFonts.tajawal(
          fontWeight: FontWeight.w800,
          fontSize: AppTextSize.xl,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        // أيقونات داكنة لكل AppBar — الشفاف منها (تعديل الملف الشخصي) كان يُحسب داكناً فتظهر الأيقونات بيضاء.
        systemOverlayStyle: AppSystemUi.darkIcons,
      ),
      // نصف القطر واللون هنا يطابقان SoftCard (design_system.dart) لضمان
      // أن أي استخدام مستقبلي لـ Card() لا يبدو مختلفًا عن باقي كروت التطبيق.
      cardTheme: CardThemeData(
        elevation: 1,
        color: AppColors.card,
        shadowColor: AppColors.shadowSoft,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primaryInk,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: AppFonts.tajawal(fontWeight: FontWeight.w700, fontSize: AppTextSize.md),
        unselectedLabelStyle: AppFonts.tajawal(fontWeight: FontWeight.w500, fontSize: AppTextSize.md),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: AppColors.indicatorFill,
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          final selected = s.contains(WidgetState.selected);
          return AppFonts.tajawal(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: AppTextSize.xs,
            color: selected ? AppColors.primaryInk : AppColors.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((s) {
          final selected = s.contains(WidgetState.selected);
          return IconThemeData(color: selected ? AppColors.primary : AppColors.textSecondary, size: 24);
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryStrong,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
          textStyle: AppFonts.tajawal(fontWeight: FontWeight.w700, fontSize: AppTextSize.lg),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryInk,
          side: const BorderSide(color: AppColors.borderSoft),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
          minimumSize: const Size.fromHeight(50),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryInk,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
          textStyle: AppFonts.tajawal(fontWeight: FontWeight.w700, fontSize: AppTextSize.md),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        titleTextStyle: AppFonts.tajawal(
          fontWeight: FontWeight.w800,
          fontSize: AppTextSize.xl,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: AppFonts.tajawal(fontSize: AppTextSize.md, height: 1.5, color: AppColors.textSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppFonts.tajawal(fontWeight: FontWeight.w500, fontSize: AppTextSize.md, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg))),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card.withValues(alpha: 0.95),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none),
      ),
    );
  }
}
