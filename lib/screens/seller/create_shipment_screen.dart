import 'package:flutter/material.dart';

import '../../data/seller_repository.dart';
import '../../models/fulfillment.dart';
import '../../theme/app_colors.dart';

/// 확인된 판매주문 품목으로 출고 생성 — 매장 단위로 품목 선택.
class CreateShipmentScreen extends StatefulWidget {
  const CreateShipmentScreen({super.key, required this.repository});
  final SellerRepository repository;

  @override
  State<CreateShipmentScreen> createState() => _CreateShipmentScreenState();
}

class _CreateShipmentScreenState extends State<CreateShipmentScreen> {
  late Future<List<CandidateGroup>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.shipmentCandidates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('출고 생성')),
      body: FutureBuilder<List<CandidateGroup>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.accent));
          }
          if (snap.hasError) {
            return Center(
                child: Text('${snap.error}',
                    style: const TextStyle(color: AppColors.inkSoft)));
          }
          final groups = snap.data ?? const [];
          if (groups.isEmpty) {
            return ListView(children: const [
              SizedBox(height: 120),
              Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.inkSoft),
              SizedBox(height: 12),
              Center(
                  child: Text('출고할 확정 판매주문이 없습니다',
                      style: TextStyle(color: AppColors.inkSoft))),
              SizedBox(height: 4),
              Center(
                  child: Text('판매주문을 먼저 «확인»하세요',
                      style: TextStyle(color: AppColors.inkSoft, fontSize: 12))),
            ]);
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Text('매장을 선택해 출고를 생성합니다',
                    style: TextStyle(fontSize: 13, color: AppColors.inkSoft)),
              ),
              for (final g in groups)
                _GroupCard(
                  group: g,
                  onCreate: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => _StoreShipmentBuilder(
                        repository: widget.repository, group: g),
                  )),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group, required this.onCreate});
  final CandidateGroup group;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            const Icon(Icons.storefront_outlined, size: 18, color: AppColors.mango700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(group.storeName ?? '매장 #${group.storeId}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
            Text('${group.items.length}품목',
                style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
          ]),
          const SizedBox(height: 10),
          for (final it in group.items.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• ${it.productName} ${it.qty}${it.unit}',
                  style: const TextStyle(fontSize: 13, color: AppColors.ink)),
            ),
          if (group.items.length > 3)
            Text('  외 ${group.items.length - 3}건',
                style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onCreate,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
            child: const Text('이 매장 출고 만들기'),
          ),
        ],
      ),
    );
  }
}

/// 한 매장의 품목을 선택해 출고 생성.
class _StoreShipmentBuilder extends StatefulWidget {
  const _StoreShipmentBuilder({required this.repository, required this.group});
  final SellerRepository repository;
  final CandidateGroup group;

  @override
  State<_StoreShipmentBuilder> createState() => _StoreShipmentBuilderState();
}

class _StoreShipmentBuilderState extends State<_StoreShipmentBuilder> {
  late final Set<int> _selected = widget.group.items.map((e) => e.id).toSet();
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_selected.isEmpty) return;
    setState(() => _busy = true);
    try {
      await widget.repository.createShipment(
        storeId: widget.group.storeId,
        itemIds: _selected.toList(),
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context)
        ..pop()
        ..pop(); // 빌더 + 후보 목록 닫기 → 출고 목록으로
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('출고가 생성되었습니다. 송장 입력 후 확정하세요.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.mango800));
    } catch (e) {
      setState(() => _busy = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFB02A2A)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(widget.group.storeName ?? '출고 생성')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text('출고할 품목 선택',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          ),
          for (final it in widget.group.items)
            CheckboxListTile(
              value: _selected.contains(it.id),
              onChanged: (v) => setState(() {
                if (v == true) {
                  _selected.add(it.id);
                } else {
                  _selected.remove(it.id);
                }
              }),
              activeColor: AppColors.accent,
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              title: Text('${it.productName}  ${it.qty}${it.unit}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: Text(it.salesOrderNo ?? it.orderNo ?? '',
                  style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            decoration: InputDecoration(
              hintText: '메모 (선택)',
              filled: true,
              fillColor: AppColors.surface,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: AppColors.cream,
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, 16 + MediaQuery.of(context).padding.bottom),
        child: FilledButton(
          onPressed: (_busy || _selected.isEmpty) ? null : _create,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
          child: _busy
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
              : Text('출고 생성 (${_selected.length}품목)'),
        ),
      ),
    );
  }
}
