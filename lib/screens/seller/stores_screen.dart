import 'package:flutter/material.dart';

import '../../data/seller_repository.dart';
import '../../models/fulfillment.dart';
import '../../theme/app_colors.dart';

/// 매장 관리 — 본사.
class StoresManageScreen extends StatefulWidget {
  const StoresManageScreen({super.key, required this.repository});
  final SellerRepository repository;

  @override
  State<StoresManageScreen> createState() => _StoresManageScreenState();
}

class _StoresManageScreenState extends State<StoresManageScreen> {
  late Future<List<StoreItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.stores();
  }

  void _reload() => setState(() { _future = widget.repository.stores(); });

  void _snack(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(m), behavior: SnackBarBehavior.floating, backgroundColor: AppColors.mango800));
    }
  }

  Future<void> _form({StoreItem? s}) async {
    final name = TextEditingController(text: s?.name ?? '');
    final email = TextEditingController(text: s?.email ?? '');
    final region = TextEditingController(text: s?.region ?? '');
    final phone = TextEditingController(text: s?.phone ?? '');
    final address = TextEditingController(text: s?.address ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s == null ? '매장 초대' : '매장 수정'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _f(name, '매장명'),
            _f(email, s == null ? '이메일' : '이메일 (세금계산서·거래명세서 수신)'),
            _f(region, '지역 (선택)'),
            _f(phone, '연락처 (선택)'),
            _f(address, '주소 (선택)'),
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
        'region': region.text.trim(),
        'phone': phone.text.trim(),
        'address': address.text.trim(),
      };
      final msg = s == null
          ? await widget.repository.inviteStore(data)
          : await widget.repository.updateStore(s.id, data);
      _snack(msg);
      _reload();
    } catch (e) {
      _snack(e.toString());
    }
  }

  Future<void> _reinvite(StoreItem s) async {
    try {
      _snack(await widget.repository.reinviteStore(s.id));
    } catch (e) {
      _snack(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('매장 관리')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        onPressed: () => _form(),
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('초대', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: FutureBuilder<List<StoreItem>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }
          final list = snap.data ?? const [];
          if (list.isEmpty) {
            return const Center(child: Text('매장이 없습니다', style: TextStyle(color: AppColors.inkSoft)));
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
                      if (s.region != null && s.region!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.mango100, borderRadius: BorderRadius.circular(6)),
                          child: Text(s.region!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.mango800)),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(child: Text(s.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
                      _Badge(joined: s.joined),
                    ]),
                    const SizedBox(height: 4),
                    Text('${s.email ?? '-'}${s.phone != null && s.phone!.isNotEmpty ? ' · ${s.phone}' : ''}',
                        style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                    const SizedBox(height: 10),
                    Row(children: [
                      if (!s.joined) _Action(label: '초대 재발송', onTap: () => _reinvite(s)),
                      const Spacer(),
                      _Action(label: '수정', onTap: () => _form(s: s)),
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

class _Badge extends StatelessWidget {
  const _Badge({required this.joined});
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

class _Action extends StatelessWidget {
  const _Action({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: AppColors.mango700.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(100)),
        child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.mango700)),
      ),
    );
  }
}
