import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/menu_item.dart';
import '../theme/app_colors.dart';

/// 메뉴 이미지. 원격 URL 이 있으면 형식(svg/래스터)에 맞춰 네트워크 로드,
/// 없거나 실패하면 번들 에셋(SVG)으로 폴백합니다.
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
      // .svg 는 벡터, 그 외(jpg/png/webp…)는 래스터로 렌더
      if (url.toLowerCase().split('?').first.endsWith('.svg')) {
        return SvgPicture.network(
          url,
          fit: fit,
          placeholderBuilder: (_) => placeholder,
        );
      }
      return Image.network(
        url,
        fit: fit,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : placeholder,
        errorBuilder: (_, _, _) => _asset(placeholder),
      );
    }
    return _asset(placeholder);
  }

  Widget _asset(Widget placeholder) => SvgPicture.asset(
        item.assetImage,
        fit: fit,
        placeholderBuilder: (_) => placeholder,
      );
}
