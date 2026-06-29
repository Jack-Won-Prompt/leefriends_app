import 'package:flutter/material.dart';

import '../../data/seller_repository.dart';
import '../../models/fulfillment.dart';
import '../../theme/app_colors.dart';

/// 공급처 관리 — 본사.
class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key, required this.repository});
  final SellerRepository repository;

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  late Future<List<SupplierItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.suppliers();
  }

  void _reload() => setState(() { _future = widget.repository.suppliers(); });

  void _snack(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(m), behavior: SnackBarBehavior.floating, backgroundColor: AppColors.mango800));
    }
  }

  Future<void> _form({SupplierItem? s}) async {
    final name = TextEditingController(text: s?.name ?? '');
    final email = TextEditingController(text: s?.email ?? '');
    final ceo = TextEditingController(text: s?.ceo ?? '');
    final phone = TextEditingController(text: s?.phone ?? '');
    final biz = TextEditingController(text: s?.bizNo ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s == null ? '공급처 초대' : '공급처 수정'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _f(name, '공급처명'),
            _f(email, '이메일', enabled: s == null),
            _f(ceo, '대표자 (선택)'),
            _f(phone, '연락처 (선택)'),
            _f(biz, '사업자번호 (선택)'),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s == null ? '초대' : '저장')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final data = {
        'name': name.text.trim(),
        'email': email.text.trim(),
        'ceo': ceo.text.trim(),
        'phone': phone.text.trim(),
        'biz_no': biz.text.trim(),
      };
      final msg = s == null
          ? await widget.repository.inviteSupplier(data)
          : await widget.repository.updateSupplier(s.id, data);
      _snack(msg);
      _reload();
    } catch (e) {
      _snack(e.toString());
    }
  }

  Future<void> _reinvite(SupplierItem s) async {
    try {
      _snack(await widget.repository.reinviteSupplier(s.id));
    } catch (e) {
      _snack(e.toString());
    }
  }

  Future<void> _delete(SupplierItem s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제'),
        content: Text('${s.name} 공급처를 삭제할까요?'),
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
      _snack(await widget.repository.deleteSupplier(s.id));
      _reload();
    } catch (e) {
      _snack(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('공급처 관리')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        onPressed: () => _form(),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('초대', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: FutureBuilder<List<SupplierItem>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }
          final list = snap.data ?? const [];
          if (list.isEmpty) {
            return const Center(child: Text('공급처가 없습니다', style: TextStyle(color: AppColors.inkSoft)));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final s = list[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Text(s.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
                      _JoinBadge(joined: s.joined),
                    ]),
                    const SizedBox(height: 4),
                    Text('${s.email ?? '-'} · 품목 ${s.productCount}',
                        style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                    const SizedBox(height: 10),
                    Row(children: [
                      if (!s.joined)
                        _MiniAction(label: '초대 재발송', onTap: () => _reinvite(s)),
                      const Spacer(),
                      _MiniAction(label: '수정', onTap: () => _form(s: s)),
                      const SizedBox(width: 6),
                      _MiniAction(label: '삭제', color: const Color(0xFFB02A2A), onTap: () => _delete(s)),
                    ]),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _f(TextEditingController c, String label, {bool enabled = true}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextField(controller: c, enabled: enabled, decoration: InputDecoration(labelText: label)),
      );
}

class _JoinBadge extends StatelessWidget {
  const _JoinBadge({required this.joined});
  final bool joined;
  @override
  Widget build(BuildContext context) {
    final (bg, fg, t) = joined
        ? (const Color(0xFFE7F6EC), const Color(0xFF1E8E4E), '가입완료')
        : (AppColors.mango100, AppColors.mango800, '초대중');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: fg)),
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({required this.label, required this.onTap, this.color});
  final String label;
  final VoidCallback onTap;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.mango700;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(100)),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c)),
      ),
    );
  }
}
