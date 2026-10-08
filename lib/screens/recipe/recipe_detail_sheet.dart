import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

import '../../models/recipe.dart';
import '../../theme/app_colors.dart';

/// 레시피 상세 — 바닥 시트 팝업(화면 이동 없음). 매장·본사 공용.
/// content 는 표준 HTML 이며 [HtmlWidget] 으로 렌더한다.
Future<void> showRecipeDetailSheet(BuildContext context, RecipeItem r) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: EdgeInsets.zero,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              decoration: BoxDecoration(
                  color: AppColors.line, borderRadius: BorderRadius.circular(100)),
            ),
          ),
          if ((r.imageUrl ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.network(
                    r.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: AppColors.cream,
                      child: const Icon(Icons.menu_book_outlined,
                          size: 40, color: AppColors.inkSoft),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((r.productName ?? '').isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: AppColors.mango100,
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(r.productName!,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.mango800)),
                  ),
                if ((r.productName ?? '').isNotEmpty) const SizedBox(height: 8),
                Text(r.title,
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w800, height: 1.35)),
                if ((r.author ?? '').isNotEmpty || (r.createdAt ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                      [
                        if ((r.author ?? '').isNotEmpty) r.author! else '본사',
                        if ((r.createdAt ?? '').isNotEmpty) r.createdAt!,
                      ].join(' · '),
                      style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                ],
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.line),
                const SizedBox(height: 14),
                if ((r.content ?? '').trim().isEmpty)
                  const Text('내용이 없습니다.',
                      style: TextStyle(fontSize: 15, color: AppColors.inkSoft))
                else
                  HtmlWidget(
                    r.content!,
                    textStyle: const TextStyle(
                        fontSize: 15, color: AppColors.ink, height: 1.6),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// 레시피 카드(목록용) — 이미지 썸네일 + 물품 배지 + 제목. 탭하면 상세 시트.
class RecipeCard extends StatelessWidget {
  const RecipeCard({super.key, required this.recipe, required this.onTap, this.trailing});
  final RecipeItem recipe;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final r = recipe;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                  child: SizedBox(
                    width: 92,
                    height: 92,
                    child: (r.imageUrl ?? '').isNotEmpty
                        ? Image.network(
                            r.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _thumbPlaceholder(),
                          )
                        : _thumbPlaceholder(),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if ((r.productName ?? '').isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                                color: AppColors.mango100,
                                borderRadius: BorderRadius.circular(6)),
                            child: Text(r.productName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.mango800)),
                          ),
                          const SizedBox(height: 5),
                        ],
                        Text(r.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
                        if ((r.createdAt ?? '').isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                              [
                                if ((r.author ?? '').isNotEmpty) r.author! else '본사',
                                r.createdAt!,
                              ].join(' · '),
                              style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
                        ],
                      ],
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _thumbPlaceholder() => Container(
        color: AppColors.cream,
        child: const Icon(Icons.menu_book_outlined, color: AppColors.inkSoft, size: 30),
      );
}
