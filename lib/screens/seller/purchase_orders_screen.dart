import 'package:flutter/material.dart';

import '../../data/seller_repository.dart';
import '../../models/purchase_order.dart';
import '../../models/fulfillment.dart' show StatusOption;
import '../../models/store_ops.dart' show won;
import '../../theme/app_colors.dart';
import 'create_purchase_order_screen.dart';

/// 구매발주 — 본사(생성·입고·취소) / 공급사(확인). 목록.
class PurchaseOrdersScreen extends StatefulWidget {
  const PurchaseOrdersScreen(
      {super.key, required this.repository, required this.isHq, this.onChanged});
  final SellerRepository repository;
  final bool isHq;
  final VoidCallback? onChanged;

  @override
  State<PurchaseOrdersScreen> createState() => _PurchaseOrdersScreenState();
}

class _PurchaseOrdersScreenState extends State<PurchaseOrdersScreen> {
  String _status = 'all';
  List<StatusOption> _statuses = const [];
  Future<({List<PurchaseOrder> rows, String role, List<StatusOption> statuses, bool hasMore})>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() =>
      setState(() { _future = widget.repository.purchaseOrders(status: _status); });

  Future<void> _openDetail(PurchaseOrder po) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PurchaseOrderDetailScreen(
        repository: widget.repository,
        id: po.id,
        isHq: widget.isHq,
        onChanged: () {
          widget.onChanged?.call();
          _load();
        },
      ),
    ));
    _load();
  }

  Future<void> _create() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CreatePurchaseOrderScreen(
          repository: widget.repository, onChanged: widget.onChanged),
    ));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('구매발주')),
      floatingActionButton: widget.isHq
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.accent,
              onPressed: _create,
              icon: const Icon(Icons.add),
              label: const Text('구매발주 생성'),
            )
          : null,
      body: Column(
        children: [
          if (_statuses.isNotEmpty)
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  for (final s in [const StatusOption(key: 'all', label: '전체'), ..._statuses])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _chip(s.label, _status == s.key, () {
                        setState(() => _status = s.key);
                        _load();
                      }),
                    ),
                ],
              ),
            ),
          Expanded(
            child: FutureBuilder<({List<PurchaseOrder> rows, String role, List<StatusOption> statuses, bool hasMore})>(
              future: _future,
              builder: (context, snap) {
                if (!snap.hasData) {
                  if (snap.hasError) {
                    return Center(
                        child: Text(snap.error.toString().replaceFirst('OrderException: ', ''),
                            style: const TextStyle(color: AppColors.inkSoft)));
                  }
                  return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                }
                if (_statuses.isEmpty && snap.data!.statuses.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _statuses = snap.data!.statuses);
                  });
                }
                final rows = snap.data!.rows;
                return RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: () async => _load(),
                  child: rows.isEmpty
                      ? ListView(children: const [
                          SizedBox(height: 120),
                          Icon(Icons.shopping_cart_outlined, size: 48, color: AppColors.inkSoft),
                          SizedBox(height: 12),
                          Center(child: Text('구매발주가 없습니다', style: TextStyle(color: AppColors.inkSoft))),
                        ])
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                          itemCount: rows.length,
                          itemBuilder: (context, i) => _tile(rows[i]),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: active ? AppColors.accent : AppColors.surface,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: active ? AppColors.accent : AppColors.line),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : AppColors.inkSoft)),
        ),
      );

  Widget _tile(PurchaseOrder po) => GestureDetector(
        onTap: () => _openDetail(po),
        child: Container(
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
                Expanded(
                  child: Text(po.poNo,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                ),
                PoStatusChip(status: po.status, label: po.statusLabel),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: Text('${po.supplierName ?? ''} · ${po.itemCount}품목',
                      style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                ),
                Text(won(po.totalAmount),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.accent)),
              ]),
            ],
          ),
        ),
      );
}

/// 구매발주 상태칩.
class PoStatusChip extends StatelessWidget {
  const PoStatusChip({super.key, required this.status, required this.label});
  final String status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      'ordered' => (AppColors.mango100, AppColors.mango800),
      'confirmed' => (const Color(0xFFE3F0FF), const Color(0xFF1B6CC4)),
      'received' => (const Color(0xFFE7F6EC), const Color(0xFF1E8E4E)),
      'canceled' => (const Color(0xFFFDECEC), const Color(0xFFB02A2A)),
      _ => (AppColors.line, AppColors.inkSoft),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Text(label,
          style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

/// 구매발주 상세 — 본사(입고/취소) / 공급사(확인).
class PurchaseOrderDetailScreen extends StatefulWidget {
  const PurchaseOrderDetailScreen(
      {super.key,
      required this.repository,
      required this.id,
      required this.isHq,
      this.onChanged});
  final SellerRepository repository;
  final int id;
  final bool isHq;
  final VoidCallback? onChanged;

  @override
  State<PurchaseOrderDetailScreen> createState() => _PurchaseOrderDetailScreenState();
}

class _PurchaseOrderDetailScreenState extends State<PurchaseOrderDetailScreen> {
  late Future<PurchaseOrder> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.purchaseOrderDetail(widget.id);
  }

  void _toast(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(m.replaceFirst('OrderException: ', '')),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? const Color(0xFFB02A2A) : AppColors.mango800));
  }

  Future<void> _act(String title, Future<String> Function() action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text('$title 하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(title)),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      _toast(await action());
      widget.onChanged?.call();
      setState(() { _future = widget.repository.purchaseOrderDetail(widget.id); });
    } catch (e) {
      _toast(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('구매발주 상세')),
      body: FutureBuilder<PurchaseOrder>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }
          final po = snap.data!;
          return ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 32 + MediaQuery.of(context).padding.bottom),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(po.poNo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      PoStatusChip(status: po.status, label: po.statusLabel),
                    ]),
                    const SizedBox(height: 8),
                    Text('${po.supplierName ?? ''} · ${po.itemCount}품목',
                        style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                    const SizedBox(height: 4),
                    Text('합계 ${won(po.totalAmount)}',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.accent)),
                    if (po.createdAt != null) ...[
                      const SizedBox(height: 6),
                      Text('발주 ${po.createdAt}'
                          '${po.confirmedAt != null ? ' · 확인 ${po.confirmedAt}' : ''}'
                          '${po.receivedAt != null ? ' · 입고 ${po.receivedAt}' : ''}',
                          style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                    ],
                    if (po.note != null && po.note!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: AppColors.cream, borderRadius: BorderRadius.circular(10)),
                        child: Text('📝 ${po.note!}', style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Text('발주 품목', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
              for (final it in po.items)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(it.productName,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('${won(it.unitPrice)} × ${it.qty}${it.unit}',
                              style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                        ],
                      ),
                    ),
                    Text(won(it.lineAmount),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  ]),
                ),
              const SizedBox(height: 8),
              ..._actions(po),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _actions(PurchaseOrder po) {
    // 공급사: ordered → 확인
    if (!widget.isHq) {
      if (po.status == 'ordered') {
        return [
          FilledButton.icon(
            onPressed: _busy ? null : () => _act('확인', () => widget.repository.confirmPurchaseOrder(po.id)),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('구매발주 확인'),
          ),
        ];
      }
      return const [];
    }
    // 본사: 입고 / 취소
    final widgets = <Widget>[];
    if (po.status != 'received' && po.status != 'canceled') {
      widgets.add(FilledButton.icon(
        onPressed: _busy ? null : () => _act('입고 처리', () => widget.repository.receivePurchaseOrder(po.id)),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        icon: const Icon(Icons.inventory_2_outlined),
        label: const Text('입고 처리 (본사 재고 반영)'),
      ));
      widgets.add(const SizedBox(height: 10));
      widgets.add(OutlinedButton.icon(
        onPressed: _busy ? null : () => _act('취소', () => widget.repository.cancelPurchaseOrder(po.id)),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFB02A2A),
          side: const BorderSide(color: Color(0xFFE9B0B0)),
          minimumSize: const Size.fromHeight(50),
        ),
        icon: const Icon(Icons.cancel_outlined),
        label: const Text('구매발주 취소'),
      ));
    }
    return widgets;
  }
}
