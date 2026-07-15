import 'package:flutter/material.dart';

import '../../data/seller_repository.dart';
import '../../models/fulfillment.dart';
import '../../models/store_ops.dart' show won;
import '../../theme/app_colors.dart';
import '../../widgets/product_thumb.dart';

/// 상품(물품) 관리 — 본사 CRUD/승인·반려, 공급처 등록/수정.
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key, required this.repository});
  final SellerRepository repository;

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late Future<({List<ManagedProduct> products, List<String> categories, List<SupplierOption> suppliers, String role})> _future;
  String _q = '';
  String _approval = 'all';
  String _role = 'hq';
  List<String> _categories = const [];
  List<SupplierOption> _suppliers = const [];

  @override
  void initState() {
    super.initState();
    _future = widget.repository.products();
  }

  void _reload() {
    setState(() { _future = widget.repository.products(q: _q, approval: _approval); });
  }

  Future<void> _openForm({ManagedProduct? product}) async {
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => ProductFormScreen(
        repository: widget.repository,
        role: _role,
        categories: _categories,
        suppliers: _suppliers,
        product: product,
      ),
    ));
    if (saved == true) _reload();
  }

  Future<void> _approve(ManagedProduct p) async {
    final ctrl = TextEditingController(text: p.storePrice > 0 ? '${p.storePrice}' : '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('승인 — 매장 판매가 책정'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: '매장 판매가(출고가)', suffixText: '원'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('승인')),
        ],
      ),
    );
    if (ok != true) return;
    final price = int.tryParse(ctrl.text.trim()) ?? -1;
    if (price < 0) return;
    try {
      final msg = await widget.repository.approveProduct(p.id, price);
      _snack(msg);
      _reload();
    } catch (e) {
      _snack(e.toString());
    }
  }

  Future<void> _reject(ManagedProduct p) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('반려'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: '반려 사유 (선택)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB02A2A)),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('반려')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      _snack(await widget.repository.rejectProduct(p.id, ctrl.text.trim()));
      _reload();
    } catch (e) {
      _snack(e.toString());
    }
  }

  Future<void> _delete(ManagedProduct p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제'),
        content: Text('${p.name} 물품을 삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB02A2A)),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      _snack(await widget.repository.deleteProduct(p.id));
      _reload();
    } catch (e) {
      _snack(e.toString());
    }
  }

  void _snack(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(m), behavior: SnackBarBehavior.floating, backgroundColor: AppColors.mango800));
    }
  }

  @override
  Widget build(BuildContext context) {
    const approvals = {'all': '전체', 'approved': '승인', 'pending': '대기', 'rejected': '반려'};
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('상품 관리')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('물품 등록', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              onChanged: (v) => _q = v,
              onSubmitted: (_) => _reload(),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: '품목명·코드 검색',
                prefixIcon: const Icon(Icons.search, color: AppColors.inkSoft),
                filled: true,
                fillColor: AppColors.surface,
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.line)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          SizedBox(
            height: 58,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final e in approvals.entries)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: () {
                        _approval = e.key;
                        _reload();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: _approval == e.key ? AppColors.accent : AppColors.surface,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: _approval == e.key ? AppColors.accent : AppColors.line),
                        ),
                        child: Text(e.value,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _approval == e.key ? Colors.white : AppColors.inkSoft)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<({List<ManagedProduct> products, List<String> categories, List<SupplierOption> suppliers, String role})>(
              future: _future,
              builder: (context, snap) {
                if (snap.hasData) {
                  _role = snap.data!.role;
                  if (_categories.isEmpty) _categories = snap.data!.categories;
                  if (_suppliers.isEmpty) _suppliers = snap.data!.suppliers;
                }
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                }
                final products = snap.data?.products ?? const [];
                if (products.isEmpty) {
                  return const Center(child: Text('물품이 없습니다', style: TextStyle(color: AppColors.inkSoft)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                  itemCount: products.length,
                  itemBuilder: (context, i) => _ProductTile(
                    product: products[i],
                    role: _role,
                    onEdit: () => _openForm(product: products[i]),
                    onApprove: () => _approve(products[i]),
                    onReject: () => _reject(products[i]),
                    onDelete: () => _delete(products[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.role,
    required this.onEdit,
    required this.onApprove,
    required this.onReject,
    required this.onDelete,
  });
  final ManagedProduct product;
  final String role;
  final VoidCallback onEdit;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final p = product;
    final isHq = role == 'hq';
    final pending = p.approvalStatus == 'pending';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pending ? AppColors.mango300 : AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            ProductThumb(url: p.imageUrl, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(child: Text(p.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
                    if (p.spec != null && p.spec!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(p.spec!, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                    ],
                  ]),
                  const SizedBox(height: 3),
                  Text('${p.code} · ${p.category} · ${p.supplierName ?? ''}',
                      style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                ],
              ),
            ),
            _ApprovalBadge(status: p.approvalStatus),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Text('출고가 ${won(p.storePrice)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accent)),
            if (p.supplyType == 'supplier') ...[
              const SizedBox(width: 12),
              Text('공급가 ${won(p.supplyPrice)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
            ],
            const Spacer(),
            // 액션
            if (isHq && pending) ...[
              _MiniBtn(label: '승인', color: const Color(0xFF1E8E4E), onTap: onApprove),
              const SizedBox(width: 6),
              _MiniBtn(label: '반려', color: const Color(0xFFB02A2A), onTap: onReject),
            ] else ...[
              _MiniBtn(label: '수정', color: AppColors.mango700, onTap: onEdit),
              const SizedBox(width: 6),
              _MiniBtn(label: '삭제', color: AppColors.inkSoft, onTap: onDelete),
            ],
          ]),
          if (p.approvalStatus == 'rejected' && p.approvalNote != null && p.approvalNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('반려: ${p.approvalNote!}', style: const TextStyle(fontSize: 12, color: Color(0xFFB02A2A))),
          ],
        ],
      ),
    );
  }
}

class _ApprovalBadge extends StatelessWidget {
  const _ApprovalBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      'pending' => ('승인대기', AppColors.mango100, AppColors.mango800),
      'rejected' => ('반려', const Color(0xFFFDECEC), const Color(0xFFB02A2A)),
      _ => ('승인', const Color(0xFFE7F6EC), const Color(0xFF1E8E4E)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: fg)),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  const _MiniBtn({required this.label, required this.color, required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
      ),
    );
  }
}

/// 상품 등록/수정 폼.
class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({
    super.key,
    required this.repository,
    required this.role,
    required this.categories,
    required this.suppliers,
    this.product,
  });
  final SellerRepository repository;
  final String role;
  final List<String> categories;
  final List<SupplierOption> suppliers;
  final ManagedProduct? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _spec;
  late final TextEditingController _unit;
  late final TextEditingController _storePrice;
  late final TextEditingController _supplyPrice;
  String? _category;
  String _supplyType = 'hq';
  int? _supplierId;
  bool _active = true;
  bool _marketPrice = false;
  String _taxType = 'inc'; // inc | exc | exempt
  bool _busy = false;

  static const _taxLabels = {
    'inc': '과세(포함)',
    'exc': '과세(별도)',
    'exempt': '면세',
  };

  bool get _isHq => widget.role == 'hq';
  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _spec = TextEditingController(text: p?.spec ?? '');
    _unit = TextEditingController(text: p?.unit ?? '');
    _storePrice = TextEditingController(text: p != null && p.storePrice > 0 ? '${p.storePrice}' : '');
    _supplyPrice = TextEditingController(text: p != null && p.supplyPrice > 0 ? '${p.supplyPrice}' : '');
    _category = p?.category ?? (widget.categories.isNotEmpty ? widget.categories.first : null);
    _supplyType = p?.supplyType ?? 'hq';
    _supplierId = p?.supplierId;
    _active = p?.isActive ?? true;
    _marketPrice = p?.isMarketPrice ?? false;
    _taxType = p?.taxType ?? 'inc';
  }

  @override
  void dispose() {
    _name.dispose();
    _spec.dispose();
    _unit.dispose();
    _storePrice.dispose();
    _supplyPrice.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_category == null) {
      _snack('카테고리를 선택해 주세요.');
      return;
    }
    setState(() => _busy = true);
    final data = <String, dynamic>{
      'name': _name.text.trim(),
      'category': _category,
      'spec': _spec.text.trim().isEmpty ? null : _spec.text.trim(),
      'unit': _unit.text.trim(),
      'supply_price': int.tryParse(_supplyPrice.text.trim()) ?? 0,
    };
    if (_isHq) {
      data['store_price'] = int.tryParse(_storePrice.text.trim()) ?? 0;
      data['supply_type'] = _supplyType;
      data['supplier_id'] = _supplyType == 'supplier' ? _supplierId : null;
      data['is_active'] = _active;
      data['is_market_price'] = _marketPrice;
      data['tax_type'] = _taxType;
    }
    try {
      final msg = await widget.repository.saveProduct(data, id: widget.product?.id);
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg), behavior: SnackBarBehavior.floating, backgroundColor: AppColors.mango800));
    } catch (e) {
      setState(() => _busy = false);
      _snack(e.toString());
    }
  }

  void _snack(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(m), behavior: SnackBarBehavior.floating, backgroundColor: const Color(0xFFB02A2A)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(_isEdit ? '물품 수정' : '물품 등록')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _field(_name, '품목명', required: true),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: _dec('카테고리'),
              style: const TextStyle(color: AppColors.ink, fontSize: 15),
              dropdownColor: AppColors.surface,
              iconEnabledColor: AppColors.inkSoft,
              items: [
                for (final c in widget.categories)
                  DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: AppColors.ink)))
              ],
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 12),
            _field(_spec, '규격 (예: 10개입)'),
            const SizedBox(height: 12),
            _field(_unit, '단위 (예: BOX, EA)', required: true),
            const SizedBox(height: 12),
            if (_isHq) ...[
              _field(_storePrice, '매장 출고가', required: true, number: true),
              const SizedBox(height: 12),
              const Text('세금 구분',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
              const SizedBox(height: 6),
              Row(children: [
                for (final e in _taxLabels.entries) ...[
                  Expanded(child: _taxChip(e.key, e.value)),
                  if (e.key != _taxLabels.keys.last) const SizedBox(width: 8),
                ],
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _typeChip('hq', '본사 직공급')),
                const SizedBox(width: 8),
                Expanded(child: _typeChip('supplier', '공급처 직배송')),
              ]),
              if (_supplyType == 'supplier') ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _supplierId,
                  decoration: _dec('공급처'),
                  style: const TextStyle(color: AppColors.ink, fontSize: 15),
                  dropdownColor: AppColors.surface,
                  iconEnabledColor: AppColors.inkSoft,
                  items: [
                    for (final s in widget.suppliers)
                      DropdownMenuItem(value: s.id, child: Text(s.name, style: const TextStyle(color: AppColors.ink)))
                  ],
                  onChanged: (v) => setState(() => _supplierId = v),
                ),
                const SizedBox(height: 12),
                _field(_supplyPrice, '공급가', number: true),
              ],
              const SizedBox(height: 4),
              SwitchListTile(
                value: _active,
                onChanged: (v) => setState(() => _active = v),
                activeThumbColor: AppColors.accent,
                contentPadding: EdgeInsets.zero,
                title: const Text('매장 노출(활성)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              SwitchListTile(
                value: _marketPrice,
                onChanged: (v) => setState(() => _marketPrice = v),
                activeThumbColor: AppColors.accent,
                contentPadding: EdgeInsets.zero,
                title: const Text('싯가 품목 (시세 변동)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text(
                    '망고처럼 시세가 매일 바뀌는 품목. 매장엔 “싯가”로 표시되고, 발주가 들어오면 받은 발주에서 단가를 확정합니다.',
                    style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
              ),
            ] else ...[
              // 공급처: 공급가만
              _field(_supplyPrice, '공급가', required: true, number: true),
              const SizedBox(height: 8),
              const Text('등록 시 승인대기 상태가 되며, 본사 승인 후 매장에 노출됩니다.',
                  style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: AppColors.cream,
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.of(context).padding.bottom),
        child: FilledButton(
          onPressed: _busy ? null : _save,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
          child: _busy
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
              : Text(_isEdit ? '수정 저장' : '등록'),
        ),
      ),
    );
  }

  Widget _taxChip(String value, String label) {
    final active = _taxType == value;
    return GestureDetector(
      onTap: () => setState(() => _taxType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? AppColors.accent : AppColors.line),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w700, color: active ? Colors.white : AppColors.inkSoft)),
      ),
    );
  }

  Widget _typeChip(String value, String label) {
    final active = _supplyType == value;
    return GestureDetector(
      onTap: () => setState(() => _supplyType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? AppColors.accent : AppColors.line),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: active ? Colors.white : AppColors.inkSoft)),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {bool required = false, bool number = false}) {
    return TextFormField(
      controller: c,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      decoration: _dec(label),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? '$label 입력' : null : null,
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.surface,
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );
}
