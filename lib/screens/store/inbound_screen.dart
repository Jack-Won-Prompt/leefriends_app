import 'package:flutter/material.dart';

import '../../data/store_ops_repository.dart';
import '../../models/store_ops.dart';
import '../../theme/app_colors.dart';
import 'shipment_detail_screen.dart';

class InboundScreen extends StatefulWidget {
  const InboundScreen({super.key, required this.repository});

  final StoreOpsRepository repository;

  @override
  State<InboundScreen> createState() => _InboundScreenState();
}

class _InboundScreenState extends State<InboundScreen> {
  late Future<({List<InboundExpected> expected, List<ShipmentModel> inTransit})>
      _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.inbound();
  }

  Future<void> _reload() async {
    setState(() { _future = widget.repository.inbound(); });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('입고 예정')),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: _reload,
        child: FutureBuilder<
            ({List<InboundExpected> expected, List<ShipmentModel> inTransit})>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.accent));
            }
            if (snap.hasError) {
              return ListView(children: [
                const SizedBox(height: 140),
                Center(
                    child: Text('${snap.error}',
                        style: const TextStyle(color: AppColors.inkSoft))),
              ]);
            }
            final data = snap.data!;
            if (data.expected.isEmpty && data.inTransit.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 140),
                Icon(Icons.local_shipping_outlined,
                    size: 48, color: AppColors.inkSoft),
                SizedBox(height: 12),
                Center(
                    child: Text('입고 예정 내역이 없습니다',
                        style: TextStyle(color: AppColors.inkSoft))),
              ]);
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                if (data.inTransit.isNotEmpty) ...[
                  const _SectionLabel('🚚 배송중', '입고 처리할 수 있어요'),
                  for (final s in data.inTransit)
                    _ShipmentCard(
                      shipment: s,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ShipmentDetailScreen(
                            repository: widget.repository,
                            shipmentId: s.id,
                            onReceived: _reload,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
                if (data.expected.isNotEmpty) ...[
                  const _SectionLabel('📦 입고 예정', '공급처가 확인한 발주'),
                  for (final e in data.expected) _ExpectedCard(item: e),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title, this.sub);
  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(sub,
                style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
          ),
        ],
      ),
    );
  }
}

class _ShipmentCard extends StatelessWidget {
  const _ShipmentCard({required this.shipment, required this.onTap});
  final ShipmentModel shipment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.mango300, width: 1.3),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shipment.shipmentNo,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                      '${shipment.seller ?? ''} · ${shipment.itemCount}품목 ${shipment.totalQty}개'
                      '${shipment.carrier != null ? ' · ${shipment.carrier}' : ''}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.inkSoft)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.inkSoft),
          ],
        ),
      ),
    );
  }
}

class _ExpectedCard extends StatelessWidget {
  const _ExpectedCard({required this.item});
  final InboundExpected item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
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
                Text(item.salesOrderNo,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                    '${item.seller ?? ''} · ${item.itemCount}품목'
                    '${item.orderNo != null ? ' · ${item.orderNo}' : ''}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.inkSoft)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: AppColors.mango100,
                borderRadius: BorderRadius.circular(100)),
            child: const Text('확인됨',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mango800)),
          ),
        ],
      ),
    );
  }
}
