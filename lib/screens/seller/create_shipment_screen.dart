import 'package:flutter/material.dart';

import '../../data/seller_repository.dart';
import '../../models/fulfillment.dart';
import '../../theme/app_colors.dart';
import '../../widgets/product_thumb.dart';

/// 출고 생성 — 매장을 선택하면 출고 대기건(확정 판매주문 품목)을 보여주고,
/// 체크해서 출고 처리한다.
class CreateShipmentScreen extends StatefulWidget {
  const CreateShipmentScreen({super.key, required this.repository});
  final SellerRepository repository;

  @override
  State<CreateShipmentScreen> createState() => _CreateShipmentScreenState();
}

class _CreateShipmentScreenState extends State<CreateShipmentScreen> {
  Future<List<CandidateGroup>>? _future;
  List<CandidateGroup> _groups = [];
  CandidateGroup? _group;
  final Set<int> _selected = {};
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<List<CandidateGroup>> _fetch() async {
    final groups = await widget.repository.shipmentCandidates();
    if (mounted) {
      setState(() {
        _groups = groups;
        // 선택 중이던 매장이 사라졌으면 초기화, 있으면 갱신
        _group = groups.where((g) => g.storeId == _group?.storeId).firstOrNull;
        if (_group == null && groups.length == 1) _group = groups.first;
        _syncSelection();
      });
    }
    return groups;
  }

  void _load() => setState(() => _future = _fetch());

  void _syncSelection() {
    _selected
      ..clear()
      ..addAll((_group?.items ?? const []).map((e) => e.id));
  }

  void _pickStore(CandidateGroup? g) {
    setState(() {
      _group = g;
      _syncSelection();
    });
  }

  Future<void> _create() async {
    if (_group == null || _selected.isEmpty) return;
    setState(() => _busy = true);
    try {
      await widget.repository.createShipment(
        storeId: _group!.storeId,
        itemIds: _selected.toList(),
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      );
      if (!mounted) return;
      _note.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('출고가 생성되었습니다. 송장 입력 후 확정하세요.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.mango800));
      setState(() => _busy = false);
      _load(); // 출고 대기 목록 갱신
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceFirst('OrderException: ', '')),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFB02A2A)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('출고 생성')),
      body: FutureBuilder<List<CandidateGroup>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && _groups.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }
          if (snap.hasError && _groups.isEmpty) {
            return Center(
                child: Text(snap.error.toString().replaceFirst('OrderException: ', ''),
                    style: const TextStyle(color: AppColors.inkSoft)));
          }
          if (_groups.isEmpty) {
            return RefreshIndicator(
              color: AppColors.accent,
              onRefresh: () async => _load(),
              child: ListView(children: const [
                SizedBox(height: 120),
                Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.inkSoft),
                SizedBox(height: 12),
                Center(child: Text('출고할 확정 판매주문이 없습니다', style: TextStyle(color: AppColors.inkSoft))),
                SizedBox(height: 4),
                Center(
                    child: Text('판매주문을 먼저 «확인»하세요',
                        style: TextStyle(color: AppColors.inkSoft, fontSize: 12))),
              ]),
            );
          }
          return Column(
            children: [
              _storeSelector(),
              Expanded(child: _group == null ? _selectHint() : _itemList()),
            ],
          );
        },
      ),
      bottomNavigationBar: (_group == null || _group!.items.isEmpty)
          ? null
          : Container(
              color: AppColors.cream,
              padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.of(context).padding.bottom),
              child: FilledButton(
                onPressed: (_busy || _selected.isEmpty) ? null : _create,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                    : Text('출고 처리 (${_selected.length}품목)'),
              ),
            ),
    );
  }

  Widget _storeSelector() => Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<CandidateGroup>(
            isExpanded: true,
            value: _group,
            hint: const Text('출고할 매장 선택'),
            items: [
              for (final g in _groups)
                DropdownMenuItem(
                  value: g,
                  child: Text('${g.storeName ?? '매장 #${g.storeId}'} · ${g.items.length}건 대기'),
                ),
            ],
            onChanged: _pickStore,
          ),
        ),
      );

  Widget _selectHint() => const Center(
        child: Text('출고할 매장을 선택하세요', style: TextStyle(color: AppColors.inkSoft)),
      );

  Widget _itemList() {
    final items = _group!.items;
    final allSelected = _selected.length == items.length && items.isNotEmpty;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        Row(children: [
          const Text('출고 대기 품목',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const Spacer(),
          TextButton(
            onPressed: () => setState(() {
              if (allSelected) {
                _selected.clear();
              } else {
                _selected
                  ..clear()
                  ..addAll(items.map((e) => e.id));
              }
            }),
            child: Text(allSelected ? '전체 해제' : '전체 선택'),
          ),
        ]),
        for (final it in items)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _selected.contains(it.id) ? AppColors.mango300 : AppColors.line),
            ),
            child: CheckboxListTile(
              value: _selected.contains(it.id),
              onChanged: (v) => setState(() {
                if (v == true) {
                  _selected.add(it.id);
                } else {
                  _selected.remove(it.id);
                }
              }),
              activeColor: AppColors.accent,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              secondary: ProductThumb(url: it.imageUrl, size: 42),
              title: Text('${it.productName}  ${it.qty}${it.unit}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: Text(it.salesOrderNo ?? it.orderNo ?? '',
                  style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
            ),
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
    );
  }
}
