import 'package:flutter/material.dart';

import '../../data/seller_repository.dart';
import '../../models/fulfillment.dart';
import '../../theme/app_colors.dart';
import '../../widgets/product_thumb.dart';
import 'seller_shipments_screen.dart';

/// 출고 생성 — 진입 시 전체 매장의 출고 대기건(확정 판매주문 품목)을 보여주고,
/// 체크해서 출고 처리한다. 매장을 골라 특정 매장만 볼 수도 있다.
/// 전체 상태에서 여러 매장 품목을 선택하면 매장별로 출고가 각각 생성된다.
class CreateShipmentScreen extends StatefulWidget {
  const CreateShipmentScreen(
      {super.key, required this.repository, this.onChanged, this.embedded = false});
  final SellerRepository repository;
  final VoidCallback? onChanged;

  /// 셸 하단 탭에 삽입될 때 true — Scaffold/AppBar 없이 본문만 렌더.
  final bool embedded;

  @override
  State<CreateShipmentScreen> createState() => _CreateShipmentScreenState();
}

class _CreateShipmentScreenState extends State<CreateShipmentScreen> {
  Future<List<CandidateGroup>>? _future;
  List<CandidateGroup> _groups = [];
  CandidateGroup? _group; // null = 전체
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
        // 특정 매장을 보던 중이면 유지(사라졌으면 전체로), 기본은 전체.
        _group = _group == null
            ? null
            : groups.where((g) => g.storeId == _group!.storeId).firstOrNull;
        _syncSelection();
      });
    }
    return groups;
  }

  void _load() => setState(() { _future = _fetch(); });

  void _syncSelection() {
    // 기본 미선택 — 사용자가 직접 체크한 품목만 출고.
    _selected.clear();
  }

  void _pickStore(CandidateGroup? g) {
    setState(() {
      _group = g;
      _syncSelection();
    });
  }

  /// 현재 보이는 매장 그룹 (전체면 모든 그룹).
  List<CandidateGroup> get _visibleGroups => _group == null ? _groups : [_group!];

  /// 현재 보이는 품목 전체.
  List<CandidateItem> get _visibleItems =>
      _visibleGroups.expand((g) => g.items).toList();

  /// 그룹(매장) 내 서로 다른 판매주문 수.
  int _orderCount(CandidateGroup g) =>
      g.items.map((e) => e.salesOrderNo ?? e.orderNo ?? '#${e.id}').toSet().length;

  Future<void> _create() async {
    if (_selected.isEmpty) return;
    setState(() => _busy = true);
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();
    try {
      var count = 0;
      // 매장별로 선택된 품목을 묶어 각각 출고 생성.
      for (final g in _visibleGroups) {
        final ids =
            g.items.where((it) => _selected.contains(it.id)).map((e) => e.id).toList();
        if (ids.isEmpty) continue;
        await widget.repository.createShipment(storeId: g.storeId, itemIds: ids, note: note);
        count++;
      }
      if (!mounted) return;
      _note.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$count건 출고가 생성되었습니다. 송장 입력 후 확정하세요.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.mango800));
      setState(() => _busy = false);
      widget.onChanged?.call(); // 대시보드 카운트 갱신
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

  void _openHistory() => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => SellerShipmentsScreen(
            repository: widget.repository, onChanged: widget.onChanged),
      ));

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Column(children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 8, top: 4),
            child: TextButton.icon(
              onPressed: _openHistory,
              icon: const Icon(Icons.local_shipping_outlined, size: 18),
              label: const Text('출고 현황'),
            ),
          ),
        ),
        Expanded(child: _body()),
        if (_groups.isNotEmpty) _bottomBar(),
      ]);
    }
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('출고'),
        actions: [
          TextButton.icon(
            onPressed: _openHistory,
            icon: const Icon(Icons.local_shipping_outlined, size: 18),
            label: const Text('출고 현황'),
          ),
        ],
      ),
      body: _body(),
      bottomNavigationBar: _groups.isEmpty ? null : _bottomBar(),
    );
  }

  Widget _body() {
    return FutureBuilder<List<CandidateGroup>>(
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
              Expanded(child: _itemList()),
            ],
          );
        },
      );
  }

  Widget _bottomBar() => Container(
        color: AppColors.cream,
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, widget.embedded ? 12 : 16 + MediaQuery.of(context).padding.bottom),
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
      );

  Widget _storeSelector() {
    final totalOrders = _groups
        .expand((g) => g.items)
        .map((e) => e.salesOrderNo ?? e.orderNo ?? '#${e.id}')
        .toSet()
        .length;
    return Container(
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
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink),
          items: [
            DropdownMenuItem<CandidateGroup>(
              value: null,
              child: Text('전체 · ${_groups.length}개 매장 · $totalOrders주문',
                  style: const TextStyle(color: AppColors.ink)),
            ),
            for (final g in _groups)
              DropdownMenuItem(
                value: g,
                child: Text('${g.storeName ?? '매장 #${g.storeId}'} · ${_orderCount(g)}주문',
                    style: const TextStyle(color: AppColors.ink)),
              ),
          ],
          onChanged: _pickStore,
        ),
      ),
    );
  }

  Widget _itemList() {
    final items = _visibleItems;
    final allSelected = items.isNotEmpty && _selected.length == items.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        Row(children: [
          const Text('출고 대기 품목', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
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
        for (final g in _visibleGroups) ...[
          if (_group == null) _storeHeader(g),
          for (final it in g.items) _itemTile(it),
        ],
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

  Widget _storeHeader(CandidateGroup g) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4, left: 2),
        child: Text('${g.storeName ?? '매장 #${g.storeId}'} · ${_orderCount(g)}주문 · ${g.items.length}품목',
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.mango700)),
      );

  Widget _itemTile(CandidateItem it) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        child: Material(
          color: AppColors.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
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
      );
}
