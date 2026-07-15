import 'package:flutter/material.dart';

import '../../data/order_repository.dart';
import '../../models/store_ops.dart';
import '../../models/supply_product.dart';
import '../../theme/app_colors.dart';

/// 발주 거래명세서 — 공급자별 품목 + 합계.
class OrderStatementScreen extends StatefulWidget {
  const OrderStatementScreen({
    super.key,
    required this.repository,
    required this.orderId,
    this.editable = false,
  });
  final OrderRepository repository;
  final int orderId;

  /// 출고 전이라 품목 추가가 가능한지 여부(매장 발주 상세에서 전달).
  final bool editable;

  @override
  State<OrderStatementScreen> createState() => _OrderStatementScreenState();
}

class _OrderStatementScreenState extends State<OrderStatementScreen> {
  late Future<OrderStatement> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.orderStatement(widget.orderId);
  }

  void _reload() {
    setState(() => _future = widget.repository.orderStatement(widget.orderId));
  }

  void _snack(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m.replaceFirst('OrderException: ', '')),
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? const Color(0xFFB02A2A) : AppColors.mango800,
    ));
  }

  /// 승인 품목에서 선택 + 수량 → 발주에 추가.
  Future<void> _addProduct() async {
    setState(() => _busy = true);
    List<SupplyProduct> products;
    try {
      final groups = await widget.repository.supplyProducts();
      products = [for (final g in groups) ...g.products];
    } catch (e) {
      setState(() => _busy = false);
      _snack(e.toString(), error: true);
      return;
    }
    if (mounted) setState(() => _busy = false);
    if (!mounted) return;
    if (products.isEmpty) {
      _snack('추가 가능한 품목이 없습니다.');
      return;
    }
    final res = await showDialog<({int productId, int qty})>(
      context: context,
      builder: (_) => _AddProductDialog(products: products),
    );
    if (res == null) return;
    setState(() => _busy = true);
    try {
      final msg = await widget.repository.addOrderItem(widget.orderId, res.productId, res.qty);
      _snack(msg);
      _reload();
    } catch (e) {
      _snack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('거래명세서')),
      floatingActionButton: widget.editable
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.accent,
              onPressed: _busy ? null : _addProduct,
              icon: _busy
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                  : const Icon(Icons.add),
              label: const Text('상품 추가', style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
      body: FutureBuilder<OrderStatement>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }
          if (!snap.hasData) {
            return Center(
                child: Text('불러오지 못했습니다\n${snap.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.inkSoft)));
          }
          final s = snap.data!;
          return ListView(
            padding: EdgeInsets.fromLTRB(
                16, 16, 16, (widget.editable ? 96 : 32) + MediaQuery.of(context).padding.bottom),
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
                    const Text('거래명세서',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text('${s.orderNo} · ${s.createdAt ?? ''}',
                        style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                    const SizedBox(height: 8),
                    Text(s.storeName ?? '',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    if (s.storeAddress != null && s.storeAddress!.isNotEmpty)
                      Text(s.storeAddress!,
                          style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              for (final g in s.groups) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                  child: Row(children: [
                    Text(g.seller,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Text('소계 ${won(g.subtotal)}',
                        style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                  ]),
                ),
                for (final it in g.items)
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
                            Text(it.name,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text('${it.qty}${it.unit} × ${won(it.unitPrice)}',
                                style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                          ],
                        ),
                      ),
                      Text(won(it.amount),
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.accent)),
                    ]),
                  ),
                const SizedBox(height: 8),
              ],
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.mango900,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  const Text('합계',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text(won(s.total),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 발주 품목 추가 다이얼로그 — 상품 검색·선택 + 수량. (productId, qty) 반환.
class _AddProductDialog extends StatefulWidget {
  const _AddProductDialog({required this.products});
  final List<SupplyProduct> products;

  @override
  State<_AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<_AddProductDialog> {
  String _query = '';
  SupplyProduct? _selected;
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? widget.products
        : widget.products
            .where((p) => p.name.toLowerCase().contains(q) || p.code.toLowerCase().contains(q))
            .toList();
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('상품 추가'),
      content: SizedBox(
        width: double.maxFinite,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: '상품명·코드 검색',
                  prefixIcon: const Icon(Icons.search, color: AppColors.inkSoft),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: filtered.isEmpty
                    ? const Center(child: Text('검색 결과가 없습니다', style: TextStyle(color: AppColors.inkSoft)))
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final p = filtered[i];
                          final sel = _selected?.id == p.id;
                          return ListTile(
                            dense: true,
                            selected: sel,
                            selectedTileColor: AppColors.mango50,
                            title: Text(p.name,
                                style: TextStyle(
                                    color: AppColors.ink,
                                    fontWeight: sel ? FontWeight.w800 : FontWeight.w600)),
                            subtitle: Text(
                                '${p.code} · ${p.category}${p.isMarketPrice ? ' · 싯가' : ' · ${won(p.storePrice)}'}',
                                style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                            trailing: sel ? const Icon(Icons.check_circle, color: AppColors.accent) : null,
                            onTap: () => setState(() => _selected = p),
                          );
                        },
                      ),
              ),
              if (_selected != null) ...[
                const Divider(height: 16),
                Row(children: [
                  Expanded(
                    child: Text(_selected!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                  ),
                  IconButton(
                    onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('$_qty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  IconButton(
                    onPressed: () => setState(() => _qty++),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ]),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
        FilledButton(
          onPressed: _selected == null
              ? null
              : () => Navigator.pop(context, (productId: _selected!.id, qty: _qty)),
          child: const Text('추가'),
        ),
      ],
    );
  }
}
