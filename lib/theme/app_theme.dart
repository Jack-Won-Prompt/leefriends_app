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
    // 1) 폰트(Pretendard)와 기본 글자색(ink)을 모든 스타일에 적용.
    //    주의: apply(bodyColor/displayColor)는 body*·display* 에만 색을 넣는다.
    final applied = base.apply(
      fontFamily: _font,
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    );
    // 2) 가중치/행간만 덮어쓴다 — 반드시 applied 스타일에서 copyWith 해서
    //    fontFamily·color 가 유실되지 않도록 한다(흰색/깨짐 방지).
    //    title*/headline*/label* 은 apply 로 색이 안 들어가므로 ink 를 명시.
    return applied.copyWith(
      displaySmall: applied.displaySmall?.copyWith(fontWeight: FontWeight.w800, height: 1.15),
      headlineMedium: applied.headlineMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.2, color: AppColors.ink),
      headlineSmall: applied.headlineSmall?.copyWith(fontWeight: FontWeight.w700, height: 1.25, color: AppColors.ink),
      titleLarge: applied.titleLarge?.copyWith(fontWeight: FontWeight.w700, height: 1.3, color: AppColors.ink),
      titleMedium: applied.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.ink),
      bodyLarge: applied.bodyLarge?.copyWith(height: 1.5, color: AppColors.ink),
      bodyMedium: applied.bodyMedium?.copyWith(height: 1.5, color: AppColors.inkSoft),
      labelLarge: applied.labelLarge?.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink),
    );
  }
}
