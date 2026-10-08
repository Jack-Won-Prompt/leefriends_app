import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/seller_repository.dart';
import '../../models/recipe.dart';
import '../../theme/app_colors.dart';
import '../recipe/recipe_detail_sheet.dart';

/// 레시피 관리 — 본사 (등록/삭제). 등록은 물품 선택 + 제목 + 내용 + 이미지.
/// 화면 이동 없이 등록/상세 모두 팝업으로 처리.
class RecipesManageScreen extends StatefulWidget {
  const RecipesManageScreen({super.key, required this.repository, this.embedded = false});
  final SellerRepository repository;

  /// 셸 하단 탭에 삽입될 때 true — Scaffold/AppBar 없이 목록 + 작성 버튼만.
  final bool embedded;

  @override
  State<RecipesManageScreen> createState() => _RecipesManageScreenState();
}

class _RecipesManageScreenState extends State<RecipesManageScreen> {
  late Future<({List<RecipeItem> recipes, List<({int id, String name})> products})> _future;
  List<({int id, String name})> _products = const [];

  @override
  void initState() {
    super.initState();
    _future = widget.repository.recipesManage();
  }

  void _reload() => setState(() { _future = widget.repository.recipesManage(); });

  void _snack(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(m), behavior: SnackBarBehavior.floating, backgroundColor: AppColors.mango800));
    }
  }

  Future<void> _compose() async {
    final title = TextEditingController();
    final content = TextEditingController();
    int? productId;
    XFile? image;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('레시피 작성'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<int?>(
                initialValue: productId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: '물품 (선택)', isDense: true),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('물품 없음 (일반 레시피)')),
                  for (final p in _products)
                    DropdownMenuItem<int?>(value: p.id, child: Text(p.name)),
                ],
                onChanged: (v) => setLocal(() => productId = v),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: title,
                maxLength: 150,
                decoration: const InputDecoration(labelText: '제목'),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: content,
                maxLines: 6,
                minLines: 4,
                decoration: const InputDecoration(
                  labelText: '내용',
                  alignLabelWithHint: true,
                  hintText: '재료 · 조리 순서 등을 입력하세요',
                ),
              ),
              const SizedBox(height: 12),
              // 이미지 선택 + 미리보기
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final x = await _pickImage();
                    if (x != null) setLocal(() => image = x);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.mango300),
                  ),
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: Text(image == null ? '이미지 선택' : '이미지 변경'),
                ),
              ),
              if (image != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(File(image!.path),
                      height: 120, width: double.infinity, fit: BoxFit.cover),
                ),
              ],
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('등록')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    if (title.text.trim().isEmpty) {
      _snack('제목을 입력해 주세요.');
      return;
    }
    try {
      final msg = await widget.repository.createRecipe(
        supplyProductId: productId,
        title: title.text.trim(),
        content: content.text,
        imagePath: image?.path,
      );
      _snack(msg);
      _reload();
    } catch (e) {
      _snack(e.toString().replaceFirst('OrderException: ', ''));
    }
  }

  Future<XFile?> _pickImage() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('카메라로 촬영'),
            onTap: () => Navigator.pop(ctx, 'camera'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('갤러리에서 선택'),
            onTap: () => Navigator.pop(ctx, 'gallery'),
          ),
        ]),
      ),
    );
    if (choice == null) return null;
    return ImagePicker().pickImage(
      source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1600,
    );
  }

  Future<void> _delete(RecipeItem r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제'),
        content: const Text('이 레시피를 삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB02A2A)),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      _snack(await widget.repository.deleteRecipe(r.id));
      _reload();
    } catch (e) {
      _snack(e.toString().replaceFirst('OrderException: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = FutureBuilder<({List<RecipeItem> recipes, List<({int id, String name})> products})>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasData && _products.isEmpty && snap.data!.products.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _products = snap.data!.products);
          });
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accent));
        }
        if (snap.hasError) {
          return Center(
            child: Text(snap.error.toString().replaceFirst('OrderException: ', ''),
                textAlign: TextAlign.center, style: const TextStyle(color: AppColors.inkSoft)),
          );
        }
        final list = snap.data?.recipes ?? const [];
        if (list.isEmpty) {
          return const Center(
              child: Text('등록된 레시피가 없습니다', style: TextStyle(color: AppColors.inkSoft)));
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final r = list[i];
            return RecipeCard(
              recipe: r,
              onTap: () => showRecipeDetailSheet(context, r),
              trailing: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: IconButton(
                  onPressed: () => _delete(r),
                  icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.inkSoft),
                ),
              ),
            );
          },
        );
      },
    );

    final composeBtn = FloatingActionButton.extended(
      backgroundColor: AppColors.accent,
      onPressed: _compose,
      icon: const Icon(Icons.edit_outlined),
      label: const Text('레시피 작성', style: TextStyle(fontWeight: FontWeight.w700)),
    );

    if (widget.embedded) {
      return Stack(children: [
        Positioned.fill(child: body),
        Positioned(right: 16, bottom: 16 + MediaQuery.of(context).padding.bottom, child: composeBtn),
      ]);
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('레시피 관리')),
      floatingActionButton: composeBtn,
      body: body,
    );
  }
}
