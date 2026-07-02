import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 품목 썸네일 (기본 56x56, 라운드). 이미지 없거나 로드 실패 시 플레이스홀더.
class ProductThumb extends StatelessWidget {
  const ProductThumb({super.key, required this.url, this.size = 56, this.radius = 12});

  final String? url;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        color: AppColors.mango50,
        child: (url == null || url!.isEmpty)
            ? _placeholder()
            : Image.network(
                url!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : _placeholder(),
                errorBuilder: (context, _, _) => _placeholder(),
              ),
      ),
    );
  }

  Widget _placeholder() => Center(
        child: Icon(Icons.inventory_2_outlined,
            color: AppColors.mango300, size: size * 0.42),
      );
}
