import 'package:flutter/material.dart';

import './app_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.light),
      scaffoldBackgroundColor: AppColors.surface,
    );
    final textTheme = AppFonts.tajawalTextTheme(base.textTheme).copyWith(
      headlineSmall: AppFonts.tajawal(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
      titleLarge: AppFonts.tajawal(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
      titleMedium: AppFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
      bodyMedium: AppFonts.tajawal(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
      bodySmall: AppFonts.tajawal(color: AppColors.textSecondary, fontSize: 13),
    );
    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        backgroundColor: AppColors.surface,
        elevation: 0,
        titleTextStyle: AppFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textPrimary),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      // نصف القطر واللون هنا يطابقان SoftCard (design_system.dart) لضمان
      // أن أي استخدام مستقبلي لـ Card() لا يبدو مختلفًا عن باقي كروت التطبيق.
      cardTheme: CardThemeData(
        elevation: 1,
        color: AppColors.card,
        shadowColor: AppColors.shadowSoft,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: AppFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 14),
        unselectedLabelStyle: AppFonts.tajawal(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: AppColors.indicatorFill,
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          final selected = s.contains(WidgetState.selected);
          return AppFonts.tajawal(
            fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
            fontSize: 12,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((s) {
          final selected = s.contains(WidgetState.selected);
          return IconThemeData(color: selected ? AppColors.primary : AppColors.textSecondary, size: 24);
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: AppFonts.tajawal(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.borderSoft),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          minimumSize: const Size.fromHeight(50),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: AppFonts.tajawal(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: AppFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textPrimary),
        contentTextStyle: AppFonts.tajawal(fontSize: 14, height: 1.5, color: AppColors.textSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppFonts.tajawal(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card.withValues(alpha: 0.95),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      ),
    );
  }
}
