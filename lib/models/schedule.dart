import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 일정(캘린더) 항목.
class ScheduleItem {
  ScheduleItem({
    required this.id,
    required this.date,
    required this.title,
    this.content,
    this.color = 'mango',
  });

  final int id;
  final DateTime date; // 날짜(시간 무시)
  final String title;
  final String? content;
  final String color;

  String get dateKey =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  factory ScheduleItem.fromJson(Map<String, dynamic> j) {
    final d = DateTime.tryParse(j['date']?.toString() ?? '') ?? DateTime.now();
    return ScheduleItem(
      id: (j['id'] as num).toInt(),
      date: DateTime(d.year, d.month, d.day),
      title: j['title']?.toString() ?? '',
      content: (j['content']?.toString().isEmpty ?? true) ? null : j['content'].toString(),
      color: j['color']?.toString() ?? 'mango',
    );
  }
}

/// 일정 색상 팔레트 (서버 Schedule::COLORS 와 일치).
class ScheduleColors {
  static const keys = ['mango', 'sky', 'emerald', 'rose', 'violet', 'neutral'];

  static Color of(String key) {
    switch (key) {
      case 'sky':
        return const Color(0xFF1B6CC4);
      case 'emerald':
        return const Color(0xFF1E8E4E);
      case 'rose':
        return const Color(0xFFB02A2A);
      case 'violet':
        return const Color(0xFF6D4AB6);
      case 'neutral':
        return const Color(0xFF6B6F76);
      case 'mango':
      default:
        return AppColors.accent;
    }
  }

  static String label(String key) {
    switch (key) {
      case 'sky':
        return '블루';
      case 'emerald':
        return '그린';
      case 'rose':
        return '레드';
      case 'violet':
        return '보라';
      case 'neutral':
        return '회색';
      case 'mango':
      default:
        return '망고';
    }
  }
}
