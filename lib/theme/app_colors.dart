import 'package:flutter/material.dart';

/// LEEFRIENDS 브랜드 색상 — 서버(웹)의 mango 팔레트를 그대로 옮겨왔습니다.
/// resources/views/layouts/app.blade.php 의 tailwind mango scale 과 동일.
class AppColors {
  AppColors._();

  static const mango50 = Color(0xFFFFF9ED);
  static const mango100 = Color(0xFFFFF1D2);
  static const mango200 = Color(0xFFFFE0A3);
  static const mango300 = Color(0xFFFFCB6B);
  static const mango400 = Color(0xFFFFB23D);
  static const mango500 = Color(0xFFFF9F1C); // primary
  static const mango600 = Color(0xFFF2784B); // accent orange
  static const mango700 = Color(0xFFD45A1F);
  static const mango800 = Color(0xFFA8430F);
  static const mango900 = Color(0xFF7A3210);

  static const primary = mango500;
  static const accent = mango600;

  static const ink = Color(0xFF2A1B12); // 본문 텍스트 (따뜻한 다크 브라운)
  static const inkSoft = Color(0xFF7A6A5E); // 보조 텍스트
  static const cream = mango50; // 화면 배경
  static const surface = Colors.white;
  static const line = Color(0xFFF0E6D6); // 옅은 구분선

  /// 히어로/포인트용 그라데이션
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [mango400, mango600],
  );

  static const warmGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [mango50, Colors.white],
  );
}
