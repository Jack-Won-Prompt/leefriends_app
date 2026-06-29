import 'package:flutter/material.dart';

import '../../data/order_repository.dart';
import '../../models/order.dart';
import '../../models/paged.dart';
import '../../theme/app_colors.dart';
import '../../widgets/paged_list_view.dart';
import 'order_detail_screen.dart';
import 'status_chip.dart';

/// 발주 내역 목록. [activeOnly] 가 true 면 진행중(pending/processing/shipping) 발주만 표시.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key, required this.repository, this.activeOnly = false});

  final OrderRepository repository;
  final bool activeOnly;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

const _activeStatuses = {'pending', 'processing', 'shipping'};

class _OrdersScreenState extends State<OrdersScreen> {
  String _type = 'all';

  void _select(String t) => setState(() => _type = t);

  @override
  Widget build(BuildContext context) {
    const filters = {'all': '전체', 'normal': '일반', 'sample': '샘플'};
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(widget.activeOnly ? '진행중 발주' : '발주 내역')),
      body: Column(
        children: [
          SizedBox(
            height: 58,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final e in filters.entries)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: () => _select(e.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color: _type == e.key ? AppColors.accent : AppColors.surface,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                              color: _type == e.key ? AppColors.accent : AppColors.line),
                        ),
                        child: Text(e.value,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _type == e.key ? Colors.white : AppColors.inkSoft)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: PagedListView<OrderModel>(
              key: ValueKey('$_type-${widget.activeOnly}'),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              emptyIcon: Icons.receipt_long_outlined,
              emptyText: widget.activeOnly ? '진행중인 발주가 없습니다' : '발주 내역이 없습니다',
              fetch: (page) async {
                final r = await widget.repository.orders(type: _type, page: page);
                final items = widget.activeOnly
                    ? r.items.where((o) => _activeStatuses.contains(o.status)).toList()
                    : r.items;
                return Paged(items: items, hasMore: r.hasMore);
              },
              itemBuilder: (context, order) =>
                  _OrderTile(order: order, repository: widget.repository),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, required this.repository});
  final OrderModel order;
  final OrderRepository repository;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(
            repository: repository,
            orderId: order.id,
            initial: order,
          ),
        ),
      ),
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
            Row(
              children: [
                Text(order.orderNo,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
                if (order.isSample) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                        color: AppColors.mango100,
                        borderRadius: BorderRadius.circular(6)),
                    child: const Text('샘플',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.mango800)),
                  ),
                ],
                const Spacer(),
                StatusChip(status: order.status, label: order.statusLabel),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${order.createdAt ?? ''} · ${order.itemCount}개 품목',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.inkSoft),
                ),
                const Spacer(),
                Text(order.amountLabel,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
