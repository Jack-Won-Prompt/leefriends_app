import 'package:flutter/material.dart';

import '../../data/cart_controller.dart';
import '../../data/order_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/product_thumb.dart';
import '../../models/order.dart';
import '../../models/order_payment.dart';
import 'order_detail_screen.dart';
import 'payment_webview_screen.dart';

/// 장바구니 확인 + 발주 접수/수정.
class CartScreen extends StatefulWidget {
  const CartScreen({
    super.key,
    required this.repository,
    required this.cart,
    this.editOrderId,
    this.initialNote,
  });

  final OrderRepository repository;
  final CartController cart;

  /// null 이면 신규 발주, 값이 있으면 해당 발주 수정 모드.
  final int? editOrderId;
  final String? initialNote;

  bool get isEdit => editOrderId != null;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late final TextEditingController _note =
      TextEditingController(text: widget.initialNote ?? '');
  bool _submitting = false;
  bool _sample = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final note = _note.text.trim().isEmpty ? null : _note.text.trim();

      if (widget.isEdit) {
        final order = await widget.repository.updateOrder(
          id: widget.editOrderId!,
          items: widget.cart.toItems(),
          note: note,
        );
        _goToOrder(order.id, order: order, updated: true);
        return;
      }

      final result = await widget.repository.createOrder(
        items: widget.cart.toItems(),
        note: note,
        orderType: _sample ? 'sample' : 'normal',
      );

      // 결제 매장 — 결제를 마쳐야 발주가 접수된다
      if (result.payment case final pay?) {
        await _payThenFinish(pay);
        return;
      }
      _goToOrder(result.order!.id, order: result.order);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      // 주문 불가(미정산) 등 발주 실패는 팝업으로 안내
      final msg = e.toString().replaceFirst('OrderException: ', '');
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Text('🚫', style: TextStyle(fontSize: 28)),
          title: const Text('발주 등록 불가', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          content: Text(msg, style: const TextStyle(fontSize: 14, height: 1.5)),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('확인')),
          ],
        ),
      );
    }
  }

  /// 장바구니를 비우고 발주 상세로 교체 진입.
  void _goToOrder(int orderId, {OrderModel? order, bool updated = false}) {
    widget.cart.clear();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(
          repository: widget.repository,
          orderId: orderId,
          initial: order,
          justCreated: !updated,
          justUpdated: updated,
        ),
      ),
    );
  }

  /// 결제창(웹뷰) → 닫힌 뒤 서버에 결과를 다시 확인 → 접수됐으면 발주 상세로.
  Future<void> _payThenFinish(PaymentCheckout pay) async {
    await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(
        builder: (_) => PaymentWebViewScreen(
          url: pay.checkoutUrl,
          donePath: pay.donePath,
          amount: pay.amount,
        ),
      ),
    );
    if (!mounted) return;

    CheckoutStatus status;
    try {
      status = await widget.repository.checkoutStatus(pay.checkoutId);
    } catch (_) {
      status = const CheckoutStatus(
          status: 'unknown',
          message: '결제 결과를 확인하지 못했습니다. 발주 내역에서 확인해 주세요.');
    }
    if (!mounted) return;

    if (status.isAccepted && status.orderId != null) {
      // 가상계좌 등 — 입금 안내를 먼저 보여준다
      if (!status.isPaid && (status.message ?? '').isNotEmpty) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: const Text('🏦', style: TextStyle(fontSize: 28)),
            title: const Text('결제 접수',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            content: Text(status.message!, style: const TextStyle(fontSize: 14, height: 1.5)),
            actions: [
              FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('확인')),
            ],
          ),
        );
        if (!mounted) return;
      }
      _goToOrder(status.orderId!);
      return;
    }

    setState(() => _submitting = false);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Text('💳', style: TextStyle(fontSize: 28)),
        title: const Text('결제가 완료되지 않았습니다',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        content: Text(
            status.message ?? '결제를 완료해야 발주가 접수됩니다. 다시 시도해 주세요.',
            style: const TextStyle(fontSize: 14, height: 1.5)),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('확인')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(widget.isEdit ? '발주 수정' : '장바구니')),
      body: ListenableBuilder(
        listenable: widget.cart,
        builder: (context, _) {
          if (widget.cart.isEmpty) {
            return const Center(
              child: Text('장바구니가 비어 있습니다',
                  style: TextStyle(color: AppColors.inkSoft)),
            );
          }
          final lines = widget.cart.lines;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    for (final line in lines)
                      _CartLineTile(line: line, cart: widget.cart),
                    const SizedBox(height: 8),
                    if (!widget.isEdit)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: _sample ? AppColors.mango300 : AppColors.line),
                        ),
                        child: SwitchListTile(
                          value: _sample,
                          onChanged: (v) => setState(() => _sample = v),
                          activeThumbColor: AppColors.accent,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('샘플 발주',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          subtitle: const Text('가격 미청구 · 본사·공급처가 확인',
                              style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                        ),
                      ),
                    TextField(
                      controller: _note,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: '요청 사항 (선택)',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.line),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _Summary(
                cart: widget.cart,
                submitting: _submitting,
                onSubmit: _submit,
                submitLabel: widget.isEdit ? '수정 저장' : '발주 접수하기',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CartLineTile extends StatelessWidget {
  const _CartLineTile({required this.line, required this.cart});
  final CartLine line;
  final CartController cart;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(line.product.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => cart.remove(line.product.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE57373),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            ProductThumb(url: line.product.imageUrl, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(line.product.name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    line.product.isMarketPrice
                        ? '${line.unit.name} · 싯가 (본사 확정)'
                        : '${line.unit.name} · ${_won(line.unit.storePrice)}원',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
            _MiniStepper(
              qty: line.qty,
              onMinus: () => cart.setQty(line.product.id, line.qty - 1),
              onPlus: () => cart.setQty(line.product.id, line.qty + 1),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 76,
              child: Text(
                line.product.isMarketPrice ? '싯가' : '${_won(line.lineAmount)}원',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStepper extends StatelessWidget {
  const _MiniStepper({
    required this.qty,
    required this.onMinus,
    required this.onPlus,
  });
  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.mango50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.mango300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onMinus,
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.remove, size: 16, color: AppColors.mango800),
            ),
          ),
          SizedBox(
            width: 26,
            child: Text('$qty',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          InkWell(
            onTap: onPlus,
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.add, size: 16, color: AppColors.mango800),
            ),
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.cart,
    required this.submitting,
    required this.onSubmit,
    required this.submitLabel,
  });
  final CartController cart;
  final bool submitting;
  final VoidCallback onSubmit;
  final String submitLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('총 ${cart.count}종 · ${cart.totalQty}개',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.inkSoft)),
              const Spacer(),
              Text(
                '${_won(cart.totalAmount)}원',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: submitting ? null : onSubmit,
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54)),
            child: submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: Colors.white),
                  )
                : Text(submitLabel),
          ),
        ],
      ),
    );
  }
}

String _won(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}
