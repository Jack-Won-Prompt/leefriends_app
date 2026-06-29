import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 앱 전역 테마 — Material 3 + Pretendard + mango 팔레트.
class AppTheme {
  AppTheme._();

  static const _font = 'Pretendard';

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      brightness: Brightness.light,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: _font,
      scaffoldBackgroundColor: AppColors.cream,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.ink,
        titleTextStyle: TextStyle(
          fontFamily: _font,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.mango100,
        labelStyle: const TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w600,
          color: AppColors.mango800,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.inkSoft,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontFamily: _font,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    return base
        .apply(
          fontFamily: _font,
          bodyColor: AppColors.ink,
          displayColor: AppColors.ink,
        )
        .copyWith(
          displaySmall: const TextStyle(fontWeight: FontWeight.w800, height: 1.15),
          headlineMedium:
              const TextStyle(fontWeight: FontWeight.w800, height: 1.2),
          headlineSmall:
              const TextStyle(fontWeight: FontWeight.w700, height: 1.25),
          titleLarge:
              const TextStyle(fontWeight: FontWeight.w700, height: 1.3),
          titleMedium:
              const TextStyle(fontWeight: FontWeight.w600),
          bodyLarge: const TextStyle(height: 1.5, color: AppColors.ink),
          bodyMedium: const TextStyle(height: 1.5, color: AppColors.inkSoft),
          labelLarge: const TextStyle(fontWeight: FontWeight.w700),
        );
  }
}
