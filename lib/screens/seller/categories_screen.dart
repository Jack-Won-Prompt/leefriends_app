import 'package:flutter/material.dart';

import '../../data/seller_repository.dart';
import '../../models/fulfillment.dart';
import '../../theme/app_colors.dart';

/// 품목 카테고리 관리 — 본사.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key, required this.repository});
  final SellerRepository repository;

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late Future<List<ProductCategoryItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.categories();
  }

  void _reload() => setState(() { _future = widget.repository.categories(); });

  Future<void> _edit({ProductCategoryItem? cat}) async {
    final name = TextEditingController(text: cat?.name ?? '');
    final code = TextEditingController(text: cat?.code ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(cat == null ? '카테고리 추가' : '카테고리 수정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: '이름')),
            const SizedBox(height: 10),
            TextField(
              controller: code,
              decoration: const InputDecoration(labelText: '코드 (영문/숫자, 예: MAC)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('저장')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final data = <String, dynamic>{'name': name.text.trim()};
      if (code.text.trim().isNotEmpty) data['code'] = code.text.trim();
      final msg = await widget.repository.saveCategory(data, id: cat?.id);
      _snack(msg);
      _reload();
    } catch (e) {
      _snack(e.toString());
    }
  }

  Future<void> _delete(ProductCategoryItem cat) async {
    if (cat.productCount > 0) {
      _snack('품목 ${cat.productCount}개가 있어 삭제할 수 없습니다.');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제'),
        content: Text('${cat.name} 카테고리를 삭제할까요?'),
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
      _snack(await widget.repository.deleteCategory(cat.id));
      _reload();
    } catch (e) {
      _snack(e.toString());
    }
  }

  void _snack(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(m), behavior: SnackBarBehavior.floating, backgroundColor: AppColors.mango800));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('카테고리 관리')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        onPressed: () => _edit(),
        icon: const Icon(Icons.add),
        label: const Text('추가', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: FutureBuilder<List<ProductCategoryItem>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }
          final cats = snap.data ?? const [];
          if (cats.isEmpty) {
            return const Center(child: Text('카테고리가 없습니다', style: TextStyle(color: AppColors.inkSoft)));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: cats.length,
            itemBuilder: (context, i) {
              final c = cats[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: AppColors.mango100, borderRadius: BorderRadius.circular(6)),
                    child: Text(c.code,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.mango800)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(c.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                  Text('품목 ${c.productCount}',
                      style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                  IconButton(
                      onPressed: () => _edit(cat: c),
                      icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.mango700)),
                  IconButton(
                      onPressed: () => _delete(c),
                      icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.inkSoft)),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}
