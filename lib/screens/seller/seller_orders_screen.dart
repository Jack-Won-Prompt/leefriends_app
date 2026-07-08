import 'package:flutter/material.dart';

import '../../data/seller_repository.dart';
import '../../models/fulfillment.dart';
import '../../models/paged.dart';
import '../../models/store_ops.dart' show won;
import '../../theme/app_colors.dart';
import '../../widgets/paged_list_view.dart';
import '../../widgets/product_thumb.dart';
import 'seller_widgets.dart';

class SellerOrdersScreen extends StatefulWidget {
  const SellerOrdersScreen(
      {super.key, required this.repository, this.isHq = false, this.onChanged});
  final SellerRepository repository;
  final bool isHq;
  final VoidCallback? onChanged;

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
                      repository: widget.repository,
                      id: order.id,
                      isHq: widget.isHq,
                      onChanged: widget.onChanged),
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
              if (order.paid) const PaidBadge(),
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
      {super.key,
      required this.repository,
      required this.id,
      this.isHq = false,
      this.onChanged});
  final SellerRepository repository;
  final int id;
  final bool isHq;
  final VoidCallback? onChanged;

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

  /// 본사 — 매장 발주건에 품목 추가. 승인된 상품에서 선택 + 수량.
  Future<void> _addItem(SellerOrder o) async {
    setState(() => _busy = true);
    List<ManagedProduct> products;
    try {
      final r = await widget.repository.products(approval: 'approved');
      products = r.products.where((p) => p.isActive).toList();
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceFirst('OrderException: ', '')),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFB02A2A)));
      }
      return;
    }
    if (mounted) setState(() => _busy = false);
    if (!mounted) return;
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('추가 가능한 승인 상품이 없습니다.'),
          behavior: SnackBarBehavior.floating));
      return;
    }
    final res = await showDialog<({int productId, int qty})>(
      context: context,
      builder: (_) => _AddItemDialog(products: products),
    );
    if (res == null) return;
    setState(() => _busy = true);
    try {
      final msg = await widget.repository.addOrderItem(o.id, res.productId, res.qty);
      widget.onChanged?.call();
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

  Future<void> _confirmOrder(SellerOrder o) async {
    if (o.salesOrderId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('발주확인'),
        content: const Text('이 발주를 확인할까요?\n확인하면 출고 대기로 이동하고, 매장에 입고예정이 생성됩니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('발주확인')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      final msg = await widget.repository.confirmSalesOrder(o.salesOrderId!);
      widget.onChanged?.call();
      setState(() { _future = widget.repository.orderDetail(widget.id); });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(msg.isEmpty ? '발주를 확인했습니다. 출고 대기로 이동합니다.' : msg),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('발주 상세')),
      bottomNavigationBar: FutureBuilder<SellerOrder>(
        future: _future,
        builder: (context, snap) {
          if (snap.data?.canConfirm != true) return const SizedBox.shrink();
          final o = snap.data!;
          return Container(
            color: AppColors.cream,
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, 16 + MediaQuery.of(context).padding.bottom),
            child: FilledButton.icon(
              onPressed: _busy ? null : () => _confirmOrder(o),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
              icon: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline),
              label: const Text('발주확인 → 출고 대기'),
            ),
          );
        },
      ),
      body: FutureBuilder<SellerOrder>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.accent));
          }
          final o = snap.data!;
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
                      Text(o.orderNo,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      FulfillStatusChip(status: o.status, label: o.statusLabel),
                      if (o.paid) const PaidBadge(compact: true),
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
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.mango900,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(children: [
                        if (o.shippingFee > 0) ...[
                          _totalRow('출고가 합계', won(o.storeAmount)),
                          const SizedBox(height: 5),
                          _totalRow(
                              '택배비 (${o.shippingBoxCount}박스 × ${won(o.shippingUnitPrice)})',
                              won(o.shippingFee)),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(color: Colors.white24, height: 1),
                          ),
                        ],
                        _totalRow('발주 합계', won(o.orderTotal), big: true),
                      ]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Row(children: [
                  const Text('품목', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  if (widget.isHq && (o.status == 'pending' || o.status == 'processing'))
                    TextButton.icon(
                      onPressed: _busy ? null : () => _addItem(o),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('품목 추가'),
                    ),
                ]),
              ),
              for (final it in o.items) _itemTile(o, it),
              // 취소된 주문은 택배비·세금계산서·거래명세서 액션 숨김
              if (widget.isHq && !o.isSample && o.status != 'canceled') _hqActions(o),
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
          // 입금요청 SMS (매장 전화번호로)
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _sendPaymentRequest(o),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1E8E4E),
              side: const BorderSide(color: Color(0xFFA7DCB9)),
              minimumSize: const Size.fromHeight(50),
            ),
            icon: const Icon(Icons.sms_outlined, size: 18),
            label: const Text('입금요청 SMS 보내기'),
          ),
          const SizedBox(height: 10),
          // 택배비 등록/수정
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _setShipping(o),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.mango700,
              side: const BorderSide(color: AppColors.mango300),
              minimumSize: const Size.fromHeight(50),
            ),
            icon: const Icon(Icons.local_shipping_outlined, size: 18),
            label: Text(o.shippingFee > 0
                ? '택배비 수정 (${won(o.shippingFee)})'
                : '택배비 등록'),
          ),
          const SizedBox(height: 10),
          // 거래명세서 이메일 (우선 노출)
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
          const SizedBox(height: 10),
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
        ],
      ),
    );
  }

  Future<void> _sendPaymentRequest(SellerOrder o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('입금요청 SMS'),
        content: Text(
            '${o.storeName ?? '매장'}에 입금계좌·발주금액을 담은 입금요청 문자를 전송하고 주문을 접수 상태로 변경합니다.\n매장 전화번호가 등록돼 있어야 합니다. 진행할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('닫기')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('전송')),
        ],
      ),
    );
    if (ok != true) return;
    await _runAction(() => widget.repository.sendPaymentRequestSms(o.id));
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
    final noShipping = o.shippingFee == 0;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('거래명세서 이메일'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (noShipping)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('⚠️ 택배비가 추가되지 않았습니다. 택배비 없이 전송됩니다.',
                    style: TextStyle(
                        fontSize: 13, color: Color(0xFFC2660C), fontWeight: FontWeight.w700)),
              ),
            Text('거래명세서 PDF를 매장(${o.storeEmail})으로 전송합니다. 진행할까요?'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('닫기')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(noShipping ? '택배비 없이 전송' : '전송'),
          ),
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

  Future<void> _setShipping(SellerOrder o) async {
    final result = await showDialog<(int, int)>(
      context: context,
      builder: (_) => _ShippingDialog(box: o.shippingBoxCount, unit: o.shippingUnitPrice),
    );
    if (result == null) return;
    await _runAction(() => widget.repository.updateOrderShipping(o.id, result.$1, result.$2));
  }

  Widget _totalRow(String label, String value, {bool big = false}) => Row(children: [
        Expanded(
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: big ? 14 : 12,
                  fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
        Text(value,
            style: TextStyle(
                color: Colors.white, fontSize: big ? 18 : 13, fontWeight: FontWeight.w800)),
      ]);

  Widget _itemTile(SellerOrder o, FulfillItem it) {
    final isHqItem = it.supplyType == 'hq';
    final tile = Container(
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
            ProductThumb(url: it.imageUrl, size: 46),
            const SizedBox(width: 12),
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
            if (widget.isHq) ...[
              const SizedBox(width: 8),
              const Icon(Icons.edit_outlined, size: 16, color: AppColors.inkSoft),
            ],
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
    if (!widget.isHq) return tile;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _busy ? null : () => _editItem(o, it),
      child: tile,
    );
  }

  /// 본사 — 품목 공급가/출고가/수량 수정 팝업.
  Future<void> _editItem(SellerOrder o, FulfillItem it) async {
    final result = await showDialog<(int, int, int)>(
      context: context,
      builder: (_) => _ItemEditDialog(
        name: it.productName,
        supply: it.supplyUnitPrice,
        store: it.storeUnitPrice,
        qty: it.qty,
      ),
    );
    if (result == null) return;
    await _runAction(
        () => widget.repository.editOrderItem(o.id, it.id, result.$1, result.$2, result.$3));
  }

  Future<void> _setPrice(SellerOrder o, FulfillItem it) async {
    final price = await showDialog<int>(
      context: context,
      builder: (_) => _PriceDialog(product: '${it.productName} · ${it.qty}${it.unit}'),
    );
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

/// 택배비 등록 다이얼로그 — (박스수, 박스당단가) 반환. 컨트롤러 자체 관리.
class _ShippingDialog extends StatefulWidget {
  const _ShippingDialog({required this.box, required this.unit});
  final int box;
  final int unit;
  @override
  State<_ShippingDialog> createState() => _ShippingDialogState();
}

class _ShippingDialogState extends State<_ShippingDialog> {
  late final TextEditingController _box =
      TextEditingController(text: widget.box > 0 ? '${widget.box}' : '');
  late final TextEditingController _unit =
      TextEditingController(text: widget.unit > 0 ? '${widget.unit}' : '');

  @override
  void dispose() {
    _box.dispose();
    _unit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('택배비 등록'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          controller: _box,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: '박스 수', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _unit,
          keyboardType: TextInputType.number,
          decoration:
              const InputDecoration(labelText: '박스당 단가 (원)', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 8),
        const Text('0으로 저장하면 택배비가 제거됩니다.',
            style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
        FilledButton(
          onPressed: () => Navigator.pop(context,
              (int.tryParse(_box.text.trim()) ?? 0, int.tryParse(_unit.text.trim()) ?? 0)),
          child: const Text('저장'),
        ),
      ],
    );
  }
}

/// 품목 수정 다이얼로그 — (공급가, 출고가, 수량) 반환. 컨트롤러 자체 관리.
class _ItemEditDialog extends StatefulWidget {
  const _ItemEditDialog(
      {required this.name, required this.supply, required this.store, required this.qty});
  final String name;
  final int supply;
  final int store;
  final int qty;
  @override
  State<_ItemEditDialog> createState() => _ItemEditDialogState();
}

class _ItemEditDialogState extends State<_ItemEditDialog> {
  late final TextEditingController _supply =
      TextEditingController(text: widget.supply > 0 ? '${widget.supply}' : '');
  late final TextEditingController _store =
      TextEditingController(text: widget.store > 0 ? '${widget.store}' : '');
  late final TextEditingController _qty = TextEditingController(text: '${widget.qty}');

  @override
  void dispose() {
    _supply.dispose();
    _store.dispose();
    _qty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('품목 수정'),
      content: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TextField(
            controller: _supply,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '공급가 (원)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _store,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: '출고가 (매장 단가, 원)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _qty,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '수량', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          const Text('저장 시 발주 합계가 재계산되고 매장에도 반영·알림됩니다.',
              style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
        ],
      ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
        FilledButton(
          onPressed: () {
            final q = int.tryParse(_qty.text.trim()) ?? 0;
            final st = int.tryParse(_store.text.trim()) ?? 0;
            final sp = int.tryParse(_supply.text.trim()) ?? 0;
            if (q < 1 || st < 0) return;
            Navigator.pop(context, (sp, st, q));
          },
          child: const Text('저장'),
        ),
      ],
    );
  }
}

/// 싯가 단가 확정 다이얼로그 — 단가(int) 반환. 컨트롤러 자체 관리.
class _PriceDialog extends StatefulWidget {
  const _PriceDialog({required this.product});
  final String product;
  @override
  State<_PriceDialog> createState() => _PriceDialogState();
}

class _PriceDialogState extends State<_PriceDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('싯가 단가 확정'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.product, style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
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
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
        FilledButton(
          onPressed: () {
            final v = int.tryParse(_ctrl.text.trim());
            if (v == null || v <= 0) return;
            Navigator.pop(context, v);
          },
          child: const Text('확정'),
        ),
      ],
    );
  }
}

/// 발주 품목 추가 다이얼로그 — 승인 상품 검색·선택 + 수량. (productId, qty) 반환.
class _AddItemDialog extends StatefulWidget {
  const _AddItemDialog({required this.products});
  final List<ManagedProduct> products;

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  String _query = '';
  ManagedProduct? _selected;
  final _qty = TextEditingController(text: '1');

  @override
  void dispose() {
    _qty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.products
        : widget.products
            .where((p) =>
                p.name.toLowerCase().contains(_query.toLowerCase()) ||
                p.code.toLowerCase().contains(_query.toLowerCase()))
            .toList();
    return AlertDialog(
      title: const Text('품목 추가'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                  hintText: '품목명·코드 검색',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder()),
              onChanged: (v) => setState(() {
                _query = v;
                _selected = null;
              }),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 240,
              child: filtered.isEmpty
                  ? const Center(
                      child: Text('검색 결과 없음', style: TextStyle(color: AppColors.inkSoft)))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final p = filtered[i];
                        final sel = _selected?.id == p.id;
                        return ListTile(
                          dense: true,
                          selected: sel,
                          selectedTileColor: AppColors.mango100,
                          title: Text(p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              '${p.supplyType == 'hq' ? '본사' : (p.supplierName ?? '공급사')} · ${won(p.storePrice)}/${p.unit}',
                              style: const TextStyle(fontSize: 12)),
                          trailing: sel ? const Icon(Icons.check_circle, color: AppColors.accent) : null,
                          onTap: () => setState(() => _selected = p),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              const Text('수량', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _qty,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                ),
              ),
            ]),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
        FilledButton(
          onPressed: () {
            final q = int.tryParse(_qty.text.trim()) ?? 0;
            if (_selected == null || q < 1) return;
            Navigator.pop(context, (productId: _selected!.id, qty: q));
          },
          child: const Text('추가'),
        ),
      ],
    );
  }
}
