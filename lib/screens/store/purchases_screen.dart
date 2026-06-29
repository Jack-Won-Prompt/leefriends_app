import 'package:flutter/material.dart';

import '../../data/order_repository.dart';
import '../../data/store_ops_repository.dart';
import '../../models/paged.dart';
import '../../models/store_ops.dart';
import '../../theme/app_colors.dart';
import '../../widgets/paged_list_view.dart';
import '../order/order_detail_screen.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({
    super.key,
    required this.repository,
    required this.orderRepository,
    this.initialPeriod = 'all',
  });

  final StoreOpsRepository repository;
  final OrderRepository orderRepository;
  final String initialPeriod;

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  late String _period = widget.initialPeriod;
  int _totalAmount = 0;
  int _totalOrders = 0;

  void _setPeriod(String p) => setState(() => _period = p);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('매입 내역')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                _PeriodTab(label: '전체', active: _period == 'all', onTap: () => _setPeriod('all')),
                const SizedBox(width: 8),
                _PeriodTab(label: '이번 달', active: _period == 'month', onTap: () => _setPeriod('month')),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('총 매입액',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(won(_totalAmount),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('발주 건수',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text('$_totalOrders건',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: PagedListView<PurchaseOrder>(
              key: ValueKey(_period),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              emptyText: '매입 내역이 없습니다',
              fetch: (page) async {
                final r = await widget.repository.purchases(period: _period, page: page);
                if (page == 1) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() {
                      _totalAmount = r.totalAmount;
                      _totalOrders = r.totalOrders;
                    });
                  });
                }
                return Paged(items: r.orders, hasMore: r.hasMore);
              },
              itemBuilder: (context, o) => GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => OrderDetailScreen(
                    repository: widget.orderRepository,
                    orderId: o.id,
                  ),
                )),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o.orderNo,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text('${o.createdAt ?? ''} · ${o.itemCount}개 · ${o.statusLabel}',
                                style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                          ],
                        ),
                      ),
                      Text(won(o.storeAmount),
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.accent)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodTab extends StatelessWidget {
  const _PeriodTab(
      {required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
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
  }
}
