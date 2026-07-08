import 'package:flutter/material.dart';

import '../../data/seller_repository.dart';
import '../../models/purchase_order.dart';
import '../../models/store_ops.dart' show won;
import '../../theme/app_colors.dart';

/// 구매발주 생성 — 공급사 선택 → 그 공급사 품목 담기(수량) → 발주. 본사 전용.
class CreatePurchaseOrderScreen extends StatefulWidget {
  const CreatePurchaseOrderScreen({super.key, required this.repository, this.onChanged});
  final SellerRepository repository;
  final VoidCallback? onChanged;

  @override
  State<CreatePurchaseOrderScreen> createState() => _CreatePurchaseOrderScreenState();
}

class _CreatePurchaseOrderScreenState extends State<CreatePurchaseOrderScreen> {
  Future<({List<PoSupplier> suppliers, List<PoProduct> products})>? _future;
  List<PoSupplier> _suppliers = [];
  List<PoProduct> _products = [];
  PoSupplier? _supplier;
  final Map<int, int> _cart = {}; // productId → qty
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<({List<PoSupplier> suppliers, List<PoProduct> products})> _fetch() async {
    final data = await widget.repository.purchaseOrderCreateData();
    if (mounted) {
      setState(() {
        _suppliers = data.suppliers;
        _products = data.products;
      });
    }
    return data;
  }

  List<PoProduct> get _supplierProducts =>
      _supplier == null ? [] : _products.where((p) => p.supplierId == _supplier!.id).toList();

  int get _total {
    var t = 0;
    for (final e in _cart.entries) {
      final p = _products.where((x) => x.id == e.key).firstOrNull;
      if (p != null) t += p.supplyPrice * e.value;
    }
    return t;
  }

  void _toast(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(m.replaceFirst('OrderException: ', '')),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? const Color(0xFFB02A2A) : AppColors.mango800));
  }

  Future<void> _submit() async {
    if (_supplier == null || _cart.isEmpty) return;
    setState(() => _busy = true);
    try {
      await widget.repository.createPurchaseOrder(
        supplierId: _supplier!.id,
        items: [for (final e in _cart.entries) (productId: e.key, qty: e.value)],
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      );
      widget.onChanged?.call();
      if (mounted) {
        _toast('구매발주를 등록하고 공급처에 전송했습니다.');
        Navigator.pop(context);
      }
    } catch (e) {
      _toast(e.toString(), error: true);
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('구매발주 생성')),
      bottomNavigationBar: _cart.isEmpty
          ? null
          : Container(
              color: AppColors.cream,
              padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.of(context).padding.bottom),
              child: FilledButton(
                onPressed: _busy ? null : _submit,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                child: _busy
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                    : Text('구매발주 (${_cart.length}품목 · ${won(_total)})'),
              ),
            ),
      body: FutureBuilder(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && _suppliers.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }
          if (snap.hasError && _suppliers.isEmpty) {
            return Center(
                child: Text(snap.error.toString().replaceFirst('OrderException: ', ''),
                    style: const TextStyle(color: AppColors.inkSoft)));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            children: [
              _supplierSelector(),
              const SizedBox(height: 12),
              if (_supplier == null)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                      child: Text('공급사를 선택하면 품목이 표시됩니다',
                          style: TextStyle(color: AppColors.inkSoft))),
                )
              else if (_supplierProducts.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                      child: Text('이 공급사의 발주 가능 품목이 없습니다',
                          style: TextStyle(color: AppColors.inkSoft))),
                )
              else ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 4, 4, 8),
                  child: Text('발주 품목', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                ),
                for (final p in _supplierProducts) _productTile(p),
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
            ],
          );
        },
      ),
    );
  }

  Widget _supplierSelector() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<PoSupplier>(
            isExpanded: true,
            value: _supplier,
            hint: const Text('공급사 선택'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink),
            items: [
              for (final s in _suppliers)
                DropdownMenuItem(value: s, child: Text(s.name, style: const TextStyle(color: AppColors.ink))),
            ],
            onChanged: (v) => setState(() {
              _supplier = v;
              _cart.clear();
            }),
          ),
        ),
      );

  Widget _productTile(PoProduct p) {
    final qty = _cart[p.id] ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: qty > 0 ? AppColors.mango300 : AppColors.line),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text('${won(p.supplyPrice)} / ${p.unit}',
                  style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
            ],
          ),
        ),
        _stepper(p, qty),
      ]),
    );
  }

  Widget _stepper(PoProduct p, int qty) => Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove_circle_outline, color: AppColors.inkSoft),
            onPressed: qty == 0
                ? null
                : () => setState(() {
                      if (qty <= 1) {
                        _cart.remove(p.id);
                      } else {
                        _cart[p.id] = qty - 1;
                      }
                    }),
          ),
          SizedBox(
            width: 28,
            child: Text('$qty',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add_circle, color: AppColors.accent),
            onPressed: () => setState(() => _cart[p.id] = qty + 1),
          ),
        ],
      );
}
