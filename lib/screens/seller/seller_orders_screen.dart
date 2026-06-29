import 'package:flutter/material.dart';

import '../../data/seller_repository.dart';
import '../../models/fulfillment.dart';
import '../../models/paged.dart';
import '../../models/store_ops.dart' show won;
import '../../theme/app_colors.dart';
import '../../widgets/paged_list_view.dart';
import 'seller_widgets.dart';

class SellerOrdersScreen extends StatefulWidget {
  const SellerOrdersScreen({super.key, required this.repository, this.isHq = false});
  final SellerRepository repository;
  final bool isHq;

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen> {
  String _status = 'all';
  List<StatusOption> _statuses = const [];

  void _select(String s) => setState(() => _status = s);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('받은 발주')),
      body: Column(
        children: [
          StatusFilterBar(statuses: _statuses, selected: _status, onSelect: _select),
          Expanded(
            child: PagedListView<SellerOrder>(
              key: ValueKey(_status),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              emptyText: '받은 발주가 없습니다',
              fetch: (page) async {
                final r = await widget.repository.orders(status: _status, page: page);
                if (page == 1 && _statuses.isEmpty && r.statuses.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _statuses = r.statuses);
                  });
                }
                return Paged(items: r.orders, hasMore: r.hasMore);
              },
              itemBuilder: (context, order) => _Tile(
                order: order,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => SellerOrderDetailScreen(
                      repository: widget.repository, id: order.id, isHq: widget.isHq),
                )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.order, required this.onTap});
  final SellerOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
                child: Text(order.orderNo,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              ),
              FulfillStatusChip(status: order.status, label: order.statusLabel),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: Text('${order.storeName ?? ''} · ${order.itemCount}품목 · ${order.createdAt ?? ''}',
                    style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
              ),
              Text(won(order.storeAmount),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.accent)),
            ]),
          ],
        ),
      ),
    );
  }
}

class SellerOrderDetailScreen extends StatefulWidget {
  const SellerOrderDetailScreen(
      {super.key, required this.repository, required this.id, this.isHq = false});
  final SellerRepository repository;
  final int id;
  final bool isHq;

  @override
  State<SellerOrderDetailScreen> createState() => _SellerOrderDetailScreenState();
}

class _SellerOrderDetailScreenState extends State<SellerOrderDetailScreen> {
  late Future<SellerOrder> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.orderDetail(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('발주 상세')),
      body: FutureBuilder<SellerOrder>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.accent));
          }
          final o = snap.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
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
                      Text(o.orderNo,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      FulfillStatusChip(status: o.status, label: o.statusLabel),
                    ]),
                    const SizedBox(height: 6),
                    Text('${o.storeName ?? ''} · ${o.itemCount}품목 · ${o.createdAt ?? ''}',
                        style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                    if (o.note != null && o.note!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: AppColors.cream,
                            borderRadius: BorderRadius.circular(10)),
                        child: Text('📝 ${o.note!}',
                            style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.mango900,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        const Text('발주 합계',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text(won(o.storeAmount),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                      ]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Text('품목', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
              for (final it in o.items) _itemTile(o, it),
              if (widget.isHq && !o.isSample) _hqActions(o),
            ],
          );
        },
      ),
    );
  }

  /// 본사 전용 — 세금계산서 발행 + 거래명세서 이메일.
  Widget _hqActions(SellerOrder o) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 세금계산서 발행
          if (o.taxInvoiced)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE7F6EC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(children: [
                Icon(Icons.check_circle, color: Color(0xFF1E8E4E), size: 18),
                SizedBox(width: 8),
                Text('세금계산서 발행 완료',
                    style: TextStyle(
                        color: Color(0xFF1E8E4E), fontWeight: FontWeight.w800, fontSize: 13)),
              ]),
            )
          else
            FilledButton.icon(
              onPressed: _busy || o.hasPendingPrice ? null : () => _issueTaxInvoice(o),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              icon: const Icon(Icons.receipt_long, size: 18),
              label: Text(o.hasPendingPrice ? '싯가 단가 확정 후 발행 가능' : '세금계산서 발행 (본사 → 매장)'),
            ),
          const SizedBox(height: 10),
          // 거래명세서 이메일
          OutlinedButton.icon(
            onPressed: _busy || o.storeEmail == null ? null : () => _emailStatement(o),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.mango300),
              minimumSize: const Size.fromHeight(50),
            ),
            icon: const Icon(Icons.mail_outline, size: 18),
            label: Text(o.storeEmail == null
                ? '매장 이메일 없음'
                : (o.statementEmailed ? '거래명세서 재전송' : '거래명세서 이메일 보내기')),
          ),
          if (o.statementEmailed)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('✓ 매장 전송됨${o.statementEmailCount > 1 ? ' (${o.statementEmailCount}회)' : ''}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF1E8E4E))),
            ),
        ],
      ),
    );
  }

  Future<void> _issueTaxInvoice(SellerOrder o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('세금계산서 발행'),
        content: Text('${o.storeName ?? '매장'} 앞으로 세금계산서를 팝빌로 즉시 발행합니다.\n발행 후에는 취소만 가능합니다. 진행할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('닫기')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('발행')),
        ],
      ),
    );
    if (ok != true) return;
    await _runAction(() => widget.repository.issueOrderTaxInvoice(o.id));
  }

  Future<void> _emailStatement(SellerOrder o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('거래명세서 이메일'),
        content: Text('거래명세서 PDF를 매장(${o.storeEmail})으로 전송합니다. 진행할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('닫기')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('전송')),
        ],
      ),
    );
    if (ok != true) return;
    await _runAction(() => widget.repository.emailOrderStatement(o.id));
  }

  Future<void> _runAction(Future<String> Function() action) async {
    setState(() => _busy = true);
    try {
      final msg = await action();
      setState(() { _future = widget.repository.orderDetail(widget.id); });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(msg),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.mango800));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceFirst('OrderException: ', '')),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFB02A2A)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _itemTile(SellerOrder o, FulfillItem it) {
    final isHqItem = it.supplyType == 'hq';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(it.productName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('${it.qty}${it.unit} · ${it.supplierName ?? ''}',
                      style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                ],
              ),
            ),
            if (it.pricePending)
              const Text('싯가 미확정',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFC2660C)))
            else
              Text(won(it.storeLineAmount),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.accent)),
          ]),
          // 싯가 품목 — 본사 단가 확정
          if (it.pricePending) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                const Expanded(
                  child: Text('🥭 싯가 품목 — 단가를 확정해 주세요',
                      style: TextStyle(fontSize: 12, color: Color(0xFFC2660C), fontWeight: FontWeight.w700)),
                ),
                FilledButton(
                  onPressed: _busy ? null : () => _setPrice(o, it),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    minimumSize: const Size(72, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('단가 확정'),
                ),
              ]),
            ),
          ],
          // 본사 직공급 품목 — 배송상태 직접 처리
          if (isHqItem && !it.pricePending) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('배송상태',
                    style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                const SizedBox(width: 10),
                for (final s in const [
                  ('pending', '대기'),
                  ('shipping', '배송중'),
                  ('delivered', '완료'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _StatusToggle(
                      label: s.$2,
                      active: it.fulfillmentStatus == s.$1,
                      onTap: _busy ? null : () => _setItemStatus(o, it, s.$1),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _setPrice(SellerOrder o, FulfillItem it) async {
    final ctrl = TextEditingController();
    final price = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('싯가 단가 확정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${it.productName} · ${it.qty}${it.unit}',
                style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '매장 공급 단가 (원)',
                hintText: '예: 5000',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text.trim());
              if (v == null || v <= 0) return;
              Navigator.pop(ctx, v);
            },
            child: const Text('확정'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (price == null) return;

    setState(() => _busy = true);
    try {
      final msg = await widget.repository.setItemPrice(o.id, it.id, price);
      setState(() { _future = widget.repository.orderDetail(o.id); });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(msg),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.mango800));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFB02A2A)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setItemStatus(SellerOrder o, FulfillItem it, String status) async {
    if (it.fulfillmentStatus == status) return;
    setState(() => _busy = true);
    try {
      await widget.repository.updateOrderItem(o.id, it.id, status);
      setState(() { _future = widget.repository.orderDetail(o.id); });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFB02A2A)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _StatusToggle extends StatelessWidget {
  const _StatusToggle({required this.label, required this.active, this.onTap});
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.accent : AppColors.cream,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: active ? AppColors.accent : AppColors.line),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : AppColors.inkSoft)),
      ),
    );
  }
}
