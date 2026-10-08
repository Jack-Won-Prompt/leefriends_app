import 'package:flutter/material.dart';

import '../../models/paged.dart';
import '../../models/recipe.dart';
import '../../theme/app_colors.dart';
import '../../widgets/paged_list_view.dart';
import '../recipe/recipe_detail_sheet.dart';

/// 매장·공급처 — 본사 레시피 목록(읽기 전용). 탭하면 상세는 팝업(바닥 시트)으로 열린다.
class RecipesScreen extends StatelessWidget {
  const RecipesScreen({super.key, required this.fetch, this.embedded = false});

  final Future<Paged<RecipeItem>> Function(int page) fetch;

  /// 셸 하단 탭에 삽입될 때 true — Scaffold/AppBar 없이 목록만 렌더.
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final body = PagedListView<RecipeItem>(
      emptyText: '등록된 레시피가 없습니다',
      emptyIcon: Icons.menu_book_outlined,
      fetch: fetch,
      itemBuilder: (context, r) => RecipeCard(
        recipe: r,
        onTap: () => showRecipeDetailSheet(context, r),
      ),
    );

    if (embedded) return Container(color: AppColors.cream, child: body);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('레시피')),
      body: body,
    );
  }
}
