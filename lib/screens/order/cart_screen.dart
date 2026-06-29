import 'package:flutter/material.dart';

import '../../data/cart_controller.dart';
import '../../data/order_repository.dart';
import '../../theme/app_colors.dart';
import 'order_detail_screen.dart';

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
      final order = widget.isEdit
          ? await widget.repository.updateOrder(
              id: widget.editOrderId!,
              items: widget.cart.toItems(),
              note: note,
            )
          : await widget.repository.createOrder(
              items: widget.cart.toItems(),
              note: note,
              orderType: _sample ? 'sample' : 'normal',
            );
      widget.cart.clear();
      if (!mounted) return;
      // 발주 상세로 교체 진입
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(
            repository: widget.repository,
            orderId: order.id,
            initial: order,
            justCreated: !widget.isEdit,
            justUpdated: widget.isEdit,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFB02A2A),
        ),
      );
    }
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
