import 'package:flutter/material.dart';

import '../../models/fulfillment.dart';
import '../../theme/app_colors.dart';

/// 판매자 도메인 공통 상태 칩 (판매주문/출고/발주 상태 색상).
class FulfillStatusChip extends StatelessWidget {
  const FulfillStatusChip({super.key, required this.status, required this.label});
  final String status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Text(label,
          style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }

  (Color, Color) _colors(String s) {
    switch (s) {
      case 'created':
      case 'pending':
        return (AppColors.mango100, AppColors.mango800);
      case 'confirmed':
      case 'processing':
        return (const Color(0xFFE3F0FF), const Color(0xFF1B6CC4));
      case 'shipped':
      case 'shipping':
        return (const Color(0xFFE7F6EC), const Color(0xFF1E8E4E));
      case 'received':
      case 'completed':
        return (const Color(0xFFE9E9EC), const Color(0xFF44474F));
      case 'canceled':
        return (const Color(0xFFFDECEC), const Color(0xFFB02A2A));
      default:
        return (AppColors.line, AppColors.inkSoft);
    }
  }
}

/// 상태 필터 칩 가로 스크롤.
class StatusFilterBar extends StatelessWidget {
  const StatusFilterBar({
    super.key,
    required this.statuses,
    required this.selected,
    required this.onSelect,
  });

  final List<StatusOption> statuses;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final all = <StatusOption>[
      const StatusOption(key: 'all', label: '전체'),
      ...statuses,
    ];
    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: all.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final s = all[i];
          final active = s.key == selected;
          return Align(
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () => onSelect(s.key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: active ? AppColors.accent : AppColors.surface,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: active ? AppColors.accent : AppColors.line),
                ),
                child: Text(s.label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: active ? Colors.white : AppColors.inkSoft)),
              ),
            ),
          );
        },
      ),
    );
  }
}
