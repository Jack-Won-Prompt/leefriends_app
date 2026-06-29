import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/menu_item.dart';
import '../theme/app_colors.dart';

/// 메뉴 이미지(SVG). API URL 이 있으면 네트워크, 없으면 번들 에셋을 사용하고
/// 로드 실패 시 에셋으로 폴백합니다.
class MenuImage extends StatelessWidget {
  const MenuImage({super.key, required this.item, this.fit = BoxFit.cover});

  final MenuItem item;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: AppColors.mango100,
      alignment: Alignment.center,
      child: const Icon(Icons.icecream_outlined,
          color: AppColors.mango400, size: 40),
    );

    final url = item.imageUrl;
    if (url != null && url.isNotEmpty) {
      return SvgPicture.network(
        url,
        fit: fit,
        placeholderBuilder: (_) => placeholder,
      );
    }
    return SvgPicture.asset(
      item.assetImage,
      fit: fit,
      placeholderBuilder: (_) => placeholder,
    );
  }
}
