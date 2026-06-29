import 'package:flutter/material.dart';

import '../../data/order_repository.dart';
import '../../models/store_ops.dart';
import '../../theme/app_colors.dart';

/// 발주 거래명세서 — 공급자별 품목 + 합계.
class OrderStatementScreen extends StatefulWidget {
  const OrderStatementScreen({super.key, required this.repository, required this.orderId});
  final OrderRepository repository;
  final int orderId;

  @override
  State<OrderStatementScreen> createState() => _OrderStatementScreenState();
}

class _OrderStatementScreenState extends State<OrderStatementScreen> {
  late Future<OrderStatement> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.orderStatement(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('거래명세서')),
      body: FutureBuilder<OrderStatement>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }
          if (!snap.hasData) {
            return Center(
                child: Text('불러오지 못했습니다\n${snap.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.inkSoft)));
          }
          final s = snap.data!;
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
                    const Text('거래명세서',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text('${s.orderNo} · ${s.createdAt ?? ''}',
                        style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                    const SizedBox(height: 8),
                    Text(s.storeName ?? '',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    if (s.storeAddress != null && s.storeAddress!.isNotEmpty)
                      Text(s.storeAddress!,
                          style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              for (final g in s.groups) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                  child: Row(children: [
                    Text(g.seller,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Text('소계 ${won(g.subtotal)}',
                        style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                  ]),
                ),
                for (final it in g.items)
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
                            Text(it.name,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text('${it.qty}${it.unit} × ${won(it.unitPrice)}',
                                style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                          ],
                        ),
                      ),
                      Text(won(it.amount),
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.accent)),
                    ]),
                  ),
                const SizedBox(height: 8),
              ],
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.mango900,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  const Text('합계',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text(won(s.total),
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
