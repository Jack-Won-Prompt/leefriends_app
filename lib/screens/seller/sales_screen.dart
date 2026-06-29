import 'package:flutter/material.dart';

import '../../data/seller_repository.dart';
import '../../models/fulfillment.dart';
import '../../models/store_ops.dart' show won;
import '../../theme/app_colors.dart';

/// 본사/공급처 매출 현황.
class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key, required this.repository});
  final SellerRepository repository;

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  late Future<SalesReport> _future;
  String _period = 'all';

  @override
  void initState() {
    super.initState();
    _future = widget.repository.sales(period: _period);
  }

  void _setPeriod(String p) {
    setState(() {
      _period = p;
      _future = widget.repository.sales(period: p);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('매출 현황')),
      body: FutureBuilder<SalesReport>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }
          if (!snap.hasData) {
            return Center(
                child: Text('${snap.error}',
                    style: const TextStyle(color: AppColors.inkSoft)));
          }
          final r = snap.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              Row(children: [
                _PeriodTab(label: '전체', active: _period == 'all', onTap: () => _setPeriod('all')),
                const SizedBox(width: 8),
                _PeriodTab(label: '이번 달', active: _period == 'month', onTap: () => _setPeriod('month')),
              ]),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.primaryLabel,
                        style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(won(r.primary),
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 14),
                    Row(children: [
                      _MiniStat(label: r.secondaryLabel, value: won(r.secondary)),
                      const SizedBox(width: 24),
                      _MiniStat(label: r.countLabel, value: '${r.count}건'),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 10),
                child: Text('매장별', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              if (r.byStore.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(child: Text('데이터가 없습니다', style: TextStyle(color: AppColors.inkSoft))),
                )
              else
                for (final s in r.byStore)
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
                            Text(s.storeName,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text('${s.region} · ${s.qty}${r.qtyLabel}',
                                style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                          ],
                        ),
                      ),
                      Text(won(s.amount),
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.accent)),
                    ]),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _PeriodTab extends StatelessWidget {
  const _PeriodTab({required this.label, required this.active, required this.onTap});
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
