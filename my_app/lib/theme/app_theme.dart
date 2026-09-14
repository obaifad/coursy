import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.light),
      scaffoldBackgroundColor: AppColors.surface,
    );
    final textTheme = GoogleFonts.tajawalTextTheme(base.textTheme).copyWith(
      headlineSmall: GoogleFonts.tajawal(fontWeight: FontWeight.w800, color: const Color(0xFF111827)),
      titleLarge: GoogleFonts.tajawal(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF111827)),
      titleMedium: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF111827)),
      bodyMedium: GoogleFonts.tajawal(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
      bodySmall: GoogleFonts.tajawal(color: AppColors.textSecondary, fontSize: 13),
    );
    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        backgroundColor: AppColors.surface,
        elevation: 0,
        titleTextStyle: GoogleFonts.tajawal(
          fontWeight: FontWeight.w800,
          fontSize: 18,
          color: const Color(0xFF111827),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
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
        labelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 14),
        unselectedLabelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: AppColors.indicatorFill,
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          final selected = s.contains(WidgetState.selected);
          return GoogleFonts.tajawal(
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
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
          textStyle: GoogleFonts.tajawal(fontWeight: FontWeight.w700, fontSize: 15),
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
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card.withValues(alpha: 0.95),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData.dark(useMaterial3: true).copyWith(
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.dark),
    );
  }
}
