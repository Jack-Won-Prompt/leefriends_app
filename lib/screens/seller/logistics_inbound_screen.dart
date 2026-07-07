import 'package:flutter/material.dart';

import '../../data/seller_repository.dart';
import '../../models/hq_inventory.dart';
import '../../models/store_ops.dart' show won;
import '../../theme/app_colors.dart';

/// 본사 물류 입고 — 공급처 거래명세서 입고 처리 + 수동 입고. 본사 전용.
class LogisticsInboundScreen extends StatefulWidget {
  const LogisticsInboundScreen({super.key, required this.repository, this.onChanged});
  final SellerRepository repository;
  final VoidCallback? onChanged;

  @override
  State<LogisticsInboundScreen> createState() => _LogisticsInboundScreenState();
}

class _LogisticsInboundScreenState extends State<LogisticsInboundScreen> {
  String _status = 'all';
  Future<({List<LogisticsInboundStatement> rows, List<SupplyProductLite> products, bool hasMore})>? _future;
  List<SupplyProductLite> _products = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() =>
      setState(() { _future = widget.repository.logisticsInbound(status: _status); });

  void _toast(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(m.replaceFirst('OrderException: ', '')),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? const Color(0xFFB02A2A) : AppColors.mango800));
  }

  Future<void> _receive(LogisticsInboundStatement s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('입고 처리'),
        content: Text('${s.statementNo} (${s.itemCount}품목)\n본사 재고에 입고 반영할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('입고')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      _toast(await widget.repository.receiveLogisticsStatement(s.id));
      widget.onChanged?.call();
      _load();
    } catch (e) {
      _toast(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _manual() async {
    if (_products.isEmpty) {
      _toast('등록된 공급 품목이 없습니다.', error: true);
      return;
    }
    final res = await showDialog<({int id, int qty, String note})>(
      context: context,
      builder: (_) => _ManualInboundDialog(products: _products),
    );
    if (res == null) return;
    setState(() => _busy = true);
    try {
      _toast(await widget.repository
          .manualInbound(res.id, res.qty, note: res.note.isEmpty ? null : res.note));
      widget.onChanged?.call();
      _load();
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
      appBar: AppBar(title: const Text('본사 물류 입고')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        onPressed: _busy ? null : _manual,
        icon: const Icon(Icons.add),
        label: const Text('수동 입고'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                for (final f in const [('all', '전체'), ('pending', '입고대기'), ('done', '완료')])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _chip(f.$2, _status == f.$1, () {
                      setState(() => _status = f.$1);
                      _load();
                    }),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<({List<LogisticsInboundStatement> rows, List<SupplyProductLite> products, bool hasMore})>(
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
                _products = snap.data!.products;
                final rows = snap.data!.rows;
                return RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: () async => _load(),
                  child: rows.isEmpty
                      ? ListView(children: const [
                          SizedBox(height: 120),
                          Icon(Icons.local_shipping_outlined, size: 48, color: AppColors.inkSoft),
                          SizedBox(height: 12),
                          Center(child: Text('입고 명세서가 없습니다', style: TextStyle(color: AppColors.inkSoft))),
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

  Widget _tile(LogisticsInboundStatement s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(s.statementNo,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            ),
            if (s.received)
              _badge('입고완료', const Color(0xFF44474F), const Color(0xFFE9E9EC))
            else
              _badge('입고대기', const Color(0xFF1B6CC4), const Color(0xFFE3F0FF)),
          ]),
          const SizedBox(height: 6),
          Text('${s.supplierName ?? '공급처'} · ${s.itemCount}품목 · ${won(s.total)}',
              style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
          if (s.items.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              s.items.take(4).map((e) => '${e.name} ${e.qty}${e.unit}').join(' · ') +
                  (s.items.length > 4 ? ' 외 ${s.items.length - 4}' : ''),
              style: const TextStyle(fontSize: 12, color: AppColors.ink),
            ),
          ],
          if (!s.received) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : () => _receive(s),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                icon: const Icon(Icons.inventory_2_outlined, size: 18),
                label: const Text('입고 처리 (재고 반영)'),
              ),
            ),
          ] else if (s.receivedAt != null) ...[
            const SizedBox(height: 6),
            Text('✓ ${s.receivedAt} 입고',
                style: const TextStyle(fontSize: 12, color: Color(0xFF1E8E4E))),
          ],
        ],
      ),
    );
  }

  Widget _badge(String t, Color fg, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
        child: Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
      );
}

class _ManualInboundDialog extends StatefulWidget {
  const _ManualInboundDialog({required this.products});
  final List<SupplyProductLite> products;

  @override
  State<_ManualInboundDialog> createState() => _ManualInboundDialogState();
}

class _ManualInboundDialogState extends State<_ManualInboundDialog> {
  late SupplyProductLite _product = widget.products.first;
  final _qty = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _qty.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('수동 입고'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<SupplyProductLite>(
            initialValue: _product,
            isExpanded: true,
            decoration: const InputDecoration(labelText: '품목', border: OutlineInputBorder()),
            items: [
              for (final p in widget.products)
                DropdownMenuItem(value: p, child: Text(p.name, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) => setState(() => _product = v ?? _product),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _qty,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
                labelText: '입고 수량 (${_product.unit})', border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _note,
            decoration: const InputDecoration(labelText: '메모 (선택)', border: OutlineInputBorder()),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
        FilledButton(
          onPressed: () {
            final q = int.tryParse(_qty.text.trim()) ?? 0;
            if (q < 1) return;
            Navigator.pop(context, (id: _product.id, qty: q, note: _note.text.trim()));
          },
          child: const Text('입고'),
        ),
      ],
    );
  }
}
