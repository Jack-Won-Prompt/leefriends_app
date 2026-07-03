import 'package:flutter/material.dart';

import '../../data/seller_repository.dart';
import '../../models/fulfillment.dart';
import '../../theme/app_colors.dart';
import '../../widgets/product_thumb.dart';
import 'seller_shipments_screen.dart';

/// 출고 대기 — 주문(판매주문) 단위 목록. 각 주문을 바로 출고 처리하거나,
/// 품목 단위로 세분 출고하려면 상단 «출고 생성»으로 이동.
class ShipmentWaitingScreen extends StatefulWidget {
  const ShipmentWaitingScreen(
      {super.key, required this.repository, this.onChanged, this.embedded = false});
  final SellerRepository repository;
  final VoidCallback? onChanged;

  /// 셸 하단 탭에 삽입될 때 true — Scaffold/AppBar 없이 본문만 렌더.
  final bool embedded;

  @override
  State<ShipmentWaitingScreen> createState() => _ShipmentWaitingScreenState();
}

class _OrderRow {
  _OrderRow(this.storeId, this.storeName, this.label, this.items);
  final int storeId;
  final String? storeName;
  final String label; // 판매주문번호(없으면 발주번호)
  final List<CandidateItem> items;
}

class _ShipmentWaitingScreenState extends State<ShipmentWaitingScreen> {
  Future<List<CandidateGroup>>? _future;
  List<_OrderRow> _rows = [];
  int? _store; // null = 전체
  final Set<String> _busy = {};

  /// 대기 주문이 있는 매장 목록 (id → name).
  Map<int, String?> get _stores {
    final m = <int, String?>{};
    for (final r in _rows) {
      m.putIfAbsent(r.storeId, () => r.storeName);
    }
    return m;
  }

  List<_OrderRow> get _visibleRows =>
      _store == null ? _rows : _rows.where((r) => r.storeId == _store).toList();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<List<CandidateGroup>> _fetch() async {
    final groups = await widget.repository.shipmentCandidates();
    final rows = <_OrderRow>[];
    for (final g in groups) {
      final byOrder = <String, List<CandidateItem>>{};
      for (final it in g.items) {
        final key = it.salesOrderNo ?? it.orderNo ?? '#${it.id}';
        byOrder.putIfAbsent(key, () => []).add(it);
      }
      byOrder.forEach((k, items) => rows.add(_OrderRow(g.storeId, g.storeName, k, items)));
    }
    if (mounted) {
      setState(() {
        _rows = rows;
        // 선택 매장이 사라졌으면 전체로
        if (_store != null && !rows.any((r) => r.storeId == _store)) _store = null;
      });
    }
    return groups;
  }

  void _load() => setState(() { _future = _fetch(); });

  void _toast(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(m.replaceFirst('OrderException: ', '')),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? const Color(0xFFB02A2A) : AppColors.mango800));
  }

  Future<void> _ship(_OrderRow r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('출고 처리'),
        content: Text('${r.storeName ?? '매장'} · ${r.label}\n${r.items.length}품목을 출고할까요?\n출고 후 송장 입력·확정하세요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('출고')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy.add(r.label));
    try {
      await widget.repository.createShipment(
        storeId: r.storeId,
        itemIds: r.items.map((e) => e.id).toList(),
      );
      widget.onChanged?.call();
      _toast('출고가 생성되었습니다. 송장 입력 후 확정하세요.');
      _load();
    } catch (e) {
      if (mounted) setState(() => _busy.remove(r.label));
      _toast(e.toString(), error: true);
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
      ]);
    }
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('출고 대기'),
        actions: [
          TextButton.icon(
            onPressed: _openHistory,
            icon: const Icon(Icons.local_shipping_outlined, size: 18),
            label: const Text('출고 현황'),
          ),
        ],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    return FutureBuilder<List<CandidateGroup>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && _rows.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }
          if (snap.hasError && _rows.isEmpty) {
            return Center(
                child: Text(snap.error.toString().replaceFirst('OrderException: ', ''),
                    style: const TextStyle(color: AppColors.inkSoft)));
          }
          final rows = _visibleRows;
          return Column(
            children: [
              if (_rows.isNotEmpty) _storeSelector(),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: () async => _load(),
                  child: rows.isEmpty
                      ? ListView(children: [
                          const SizedBox(height: 120),
                          const Icon(Icons.inventory_2_outlined,
                              size: 48, color: AppColors.inkSoft),
                          const SizedBox(height: 12),
                          Center(
                              child: Text(
                                  _rows.isEmpty
                                      ? '출고 대기 중인 주문이 없습니다'
                                      : '이 매장의 출고 대기 주문이 없습니다',
                                  style: const TextStyle(color: AppColors.inkSoft))),
                        ])
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: rows.length,
                          itemBuilder: (context, i) => _tile(rows[i]),
                        ),
                ),
              ),
            ],
          );
        },
      );
  }

  Widget _storeSelector() {
    final stores = _stores;
    final totalOrders = _rows.length;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          isExpanded: true,
          value: _store,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink),
          onChanged: (v) => setState(() => _store = v),
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Text('전체 · ${stores.length}개 매장 · $totalOrders주문',
                  style: const TextStyle(color: AppColors.ink)),
            ),
            for (final e in stores.entries)
              DropdownMenuItem<int?>(
                value: e.key,
                child: Text(
                    '${e.value ?? '매장 #${e.key}'} · ${_rows.where((r) => r.storeId == e.key).length}주문',
                    style: const TextStyle(color: AppColors.ink)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tile(_OrderRow r) {
    final busy = _busy.contains(r.label);
    final preview = r.items.take(4).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(r.label,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F0FF),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text('${r.items.length}품목',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1B6CC4))),
            ),
          ]),
          const SizedBox(height: 6),
          Text(r.storeName ?? '매장 #${r.storeId}',
              style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
          const SizedBox(height: 10),
          Row(children: [
            for (final it in preview)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ProductThumb(url: it.imageUrl, size: 40),
              ),
            if (r.items.length > preview.length)
              Text('+${r.items.length - preview.length}',
                  style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: busy ? null : () => _ship(r),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
              icon: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.local_shipping_outlined, size: 18),
              label: Text(busy ? '출고 중…' : '이 주문 출고 처리 (${r.items.length}품목)'),
            ),
          ),
        ],
      ),
    );
  }
}
