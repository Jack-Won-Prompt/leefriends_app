import 'package:flutter/material.dart';

import '../../data/seller_repository.dart';
import '../../models/edocs.dart';
import '../../models/paged.dart';
import '../../models/store_ops.dart' show won;
import '../../theme/app_colors.dart';
import '../../widgets/product_thumb.dart';
import '../../widgets/paged_list_view.dart';

/// 본사 — 공급사 발주 현황 (공급사별 판매주문 모아보기 + 필터 + 합계).
class SupplierOrdersScreen extends StatefulWidget {
  const SupplierOrdersScreen({super.key, required this.repository});
  final SellerRepository repository;

  @override
  State<SupplierOrdersScreen> createState() => _SupplierOrdersScreenState();
}

class _SupplierOrdersScreenState extends State<SupplierOrdersScreen> {
  String _supplier = 'all';
  String _status = 'all';
  List<EDocFilterOption> _suppliers = const [];
  List<EDocFilterOption> _statuses = const [];
  int _totalSupply = 0;

  void _select({String? supplier, String? status}) {
    setState(() {
      if (supplier != null) _supplier = supplier;
      if (status != null) _status = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('공급사 발주 현황')),
      body: Column(
        children: [
          _filters(),
          _totalBanner(),
          Expanded(
            child: PagedListView<SupplierSalesOrder>(
              key: ValueKey('$_supplier-$_status'),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              emptyText: '해당 조건의 공급사 발주가 없습니다',
              fetch: (page) async {
                final r = await widget.repository
                    .supplierOrders(supplier: _supplier, status: _status, page: page);
                if (page == 1) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() {
                      if (r.suppliers.isNotEmpty) _suppliers = r.suppliers;
                      if (r.statuses.isNotEmpty) _statuses = r.statuses;
                      _totalSupply = r.totalSupply;
                    });
                  });
                }
                return Paged(items: r.orders, hasMore: r.hasMore);
              },
              itemBuilder: (context, o) => _orderCard(o),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filters() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        children: [
          // 공급처 드롭다운
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _supplier,
                isExpanded: true,
                dropdownColor: AppColors.surface,
                iconEnabledColor: AppColors.inkSoft,
                style: const TextStyle(
                    color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w600),
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('전체 공급처')),
                  ..._suppliers.map((s) => DropdownMenuItem(value: s.key, child: Text(s.label))),
                ],
                onChanged: (v) {
                  if (v != null) _select(supplier: v);
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 상태 칩
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _statusChip('all', '전체'),
                for (final s in _statuses) _statusChip(s.key, s.label),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String key, String label) {
    final on = _status == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: on,
        showCheckmark: false,
        labelStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: on ? Colors.white : AppColors.inkSoft),
        selectedColor: AppColors.accent,
        backgroundColor: AppColors.cream,
        side: BorderSide(color: on ? AppColors.accent : AppColors.line),
        onSelected: (_) => _select(status: key),
      ),
    );
  }

  Widget _totalBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mango900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        const Text('공급액 합계',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(won(_totalSupply),
            style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
      ]),
    );
  }

  Widget _orderCard(SupplierSalesOrder o) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => SupplierOrderDetailScreen(repository: widget.repository, id: o.id),
      )),
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
                child: Text(o.supplierName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              ),
              SoStatusChip(status: o.status, label: o.statusLabel),
            ]),
            const SizedBox(height: 6),
            Text('${o.salesOrderNo} · ${o.storeName ?? ''}',
                style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
            Text('${o.orderNo ?? ''} · ${o.itemCount}품목 · ${o.createdAt ?? ''}',
                style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
            const SizedBox(height: 8),
            Row(children: [
              const Text('공급액',
                  style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
              const Spacer(),
              Text(won(o.supplyAmount),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.accent)),
            ]),
          ],
        ),
      ),
    );
  }
}

/// 판매주문 상태 칩.
class SoStatusChip extends StatelessWidget {
  const SoStatusChip({super.key, required this.status, required this.label});
  final String status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      'created' => (const Color(0xFFFFF3E6), const Color(0xFFC2660C)),
      'confirmed' => (const Color(0xFFEFF3FA), const Color(0xFF1B6CC4)),
      'shipped' => (const Color(0xFFEAF2FF), const Color(0xFF2A6FDB)),
      'received' => (const Color(0xFFE7F6EC), const Color(0xFF1E8E4E)),
      'canceled' => (const Color(0xFFFDECEC), const Color(0xFFB02A2A)),
      _ => (const Color(0xFFF0F0F0), AppColors.inkSoft),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: fg)),
    );
  }
}

/// 공급사 발주 상세 (본사) — 품목별 공급액.
class SupplierOrderDetailScreen extends StatefulWidget {
  const SupplierOrderDetailScreen({super.key, required this.repository, required this.id});
  final SellerRepository repository;
  final int id;

  @override
  State<SupplierOrderDetailScreen> createState() => _SupplierOrderDetailScreenState();
}

class _SupplierOrderDetailScreenState extends State<SupplierOrderDetailScreen> {
  late Future<SupplierSalesOrder> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.supplierOrderDetail(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('공급사 발주 상세')),
      body: FutureBuilder<SupplierSalesOrder>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
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
                      Expanded(
                        child: Text(o.supplierName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
                      SoStatusChip(status: o.status, label: o.statusLabel),
                    ]),
                    const SizedBox(height: 6),
                    Text(o.salesOrderNo,
                        style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                    Text('${o.storeName ?? ''} · ${o.orderNo ?? ''}',
                        style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                    if (o.createdAt != null)
                      Text('접수 ${o.createdAt}',
                          style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                    if (o.confirmedAt != null)
                      Text('확인 ${o.confirmedAt}',
                          style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Text('품목', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
              for (final it in o.items)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(children: [
                    ProductThumb(url: it.imageUrl, size: 44),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(it.productName,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text('${it.unit} · ${it.qty}개',
                              style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                        ],
                      ),
                    ),
                    Text(won(it.supplyLineAmount),
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.accent)),
                  ]),
                ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.mango900,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  const Text('공급액 합계',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text(won(o.supplyAmount),
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
