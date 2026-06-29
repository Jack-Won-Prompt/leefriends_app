import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// best / new / hot 배지 칩.
class BadgeChip extends StatelessWidget {
  const BadgeChip({super.key, required this.badge});

  final String badge;

  @override
  Widget build(BuildContext context) {
    final spec = _spec(badge);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: spec.bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        spec.label,
        style: TextStyle(
          color: spec.fg,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  _BadgeSpec _spec(String b) {
    switch (b.toLowerCase()) {
      case 'best':
        return const _BadgeSpec('BEST', AppColors.accent, Colors.white);
      case 'new':
        return const _BadgeSpec('NEW', AppColors.mango500, Colors.white);
      case 'hot':
        return const _BadgeSpec('HOT', AppColors.mango700, Colors.white);
      default:
        return _BadgeSpec(b.toUpperCase(), AppColors.mango100, AppColors.mango800);
    }
  }
}

class _BadgeSpec {
  final String label;
  final Color bg;
  final Color fg;
  const _BadgeSpec(this.label, this.bg, this.fg);
}
