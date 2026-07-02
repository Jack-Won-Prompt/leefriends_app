import 'package:flutter/material.dart';

import '../../data/cart_controller.dart';
import '../../data/order_repository.dart';
import '../../models/order.dart';
import '../../theme/app_colors.dart';
import '../../widgets/product_thumb.dart';
import 'cart_screen.dart';
import 'order_statement_screen.dart';
import '../seller/seller_widgets.dart' show PaidBadge;
import 'status_chip.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({
    super.key,
    required this.repository,
    required this.orderId,
    this.initial,
    this.justCreated = false,
    this.justUpdated = false,
  });

  final OrderRepository repository;
  final int orderId;
  final OrderModel? initial;
  final bool justCreated;
  final bool justUpdated;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  OrderModel? _order;
  bool _loading = false;
  bool _busy = false; // 취소 진행 중
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null && widget.initial!.items.isNotEmpty) {
      _order = widget.initial;
    } else {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final o = await widget.repository.orderDetail(widget.orderId);
      setState(() {
        _order = o;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit() async {
    final order = _order!;
    final cart = CartController()..seedFromOrder(order.items);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CartScreen(
          repository: widget.repository,
          cart: cart,
          editOrderId: order.id,
          initialNote: order.note,
        ),
      ),
    );
    cart.dispose();
    if (mounted) _fetch(); // 수정 후 최신 상태 반영
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('발주 취소'),
        content: const Text('이 발주를 취소할까요?\n본사·공급처에 취소 알림이 전송됩니다.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('닫기')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB02A2A)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('발주 취소'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy = true);
    try {
      final updated = await widget.repository.cancelOrder(widget.orderId);
      setState(() => _order = updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('발주가 취소되었습니다.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.mango800,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFB02A2A),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('발주 상세'),
        actions: [
          if (order != null && !order.isSample)
            IconButton(
              tooltip: '거래명세서',
              icon: const Icon(Icons.receipt_long_outlined),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => OrderStatementScreen(
                    repository: widget.repository, orderId: widget.orderId),
              )),
            ),
        ],
      ),
      body: order == null
          ? Center(
              child: _loading
                  ? const CircularProgressIndicator(color: AppColors.accent)
                  : Text('불러오지 못했습니다\n${_error ?? ''}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.inkSoft)),
            )
          : _body(order),
      bottomNavigationBar: (order != null && order.maybeEditable)
          ? _actionBar(order)
          : null,
    );
  }

  Widget _body(OrderModel order) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (widget.justCreated || widget.justUpdated)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.mango50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.mango300),
            ),
            child: Row(
              children: [
                const Text('✅ ', style: TextStyle(fontSize: 18)),
                Expanded(
                  child: Text(
                    widget.justUpdated
                        ? '발주가 수정되었습니다.\n본사·공급처에 변경 알림이 전송되었습니다.'
                        : '발주가 정상 접수되었습니다.\n본사·공급처로 전달되었습니다.',
                    style: const TextStyle(
                        color: AppColors.mango900,
                        fontWeight: FontWeight.w600,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
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
              Row(
                children: [
                  Text(order.orderNo,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  StatusChip(status: order.status, label: order.statusLabel),
                  if (order.paid) const PaidBadge(compact: true),
                ],
              ),
              if (order.createdAt != null) ...[
                const SizedBox(height: 6),
                Text(order.createdAt!,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.inkSoft)),
              ],
              if (order.note != null && order.note!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('📝 ${order.note!}',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.ink)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text('발주 품목',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        ),
        for (final it in order.items) _ItemRow(item: it),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.mango900,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Text('합계 (출고가)',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(order.amountLabel,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionBar(OrderModel order) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _cancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFB02A2A),
                side: const BorderSide(color: Color(0xFFE0A3A3)),
                minimumSize: const Size.fromHeight(52),
              ),
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2))
                  : const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('발주 취소'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: _busy ? null : _edit,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('발주 수정'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});
  final OrderItemView item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          ProductThumb(url: item.imageUrl, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  '${item.unit} · ${item.qty}개',
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
          Text(item.lineLabel,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent)),
        ],
      ),
    );
  }
}
