import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// 발주 상태 칩 (접수/처리중/배송중/완료/취소).
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, required this.label});

  final String status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  (Color, Color) _colors(String status) {
    switch (status) {
      case 'pending':
        return (AppColors.mango100, AppColors.mango800);
      case 'processing':
        return (const Color(0xFFE3F0FF), const Color(0xFF1B6CC4));
      case 'shipping':
        return (const Color(0xFFE7F6EC), const Color(0xFF1E8E4E));
      case 'completed':
        return (const Color(0xFFE9E9EC), const Color(0xFF44474F));
      case 'canceled':
        return (const Color(0xFFFDECEC), const Color(0xFFB02A2A));
      default:
        return (AppColors.line, AppColors.inkSoft);
    }
  }
}
