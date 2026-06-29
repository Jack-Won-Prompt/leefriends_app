import 'package:flutter/material.dart';

import '../../data/store_ops_repository.dart';
import '../../models/store_ops.dart';
import '../../theme/app_colors.dart';

class ShipmentDetailScreen extends StatefulWidget {
  const ShipmentDetailScreen({
    super.key,
    required this.repository,
    required this.shipmentId,
    this.onReceived,
  });

  final StoreOpsRepository repository;
  final int shipmentId;
  final VoidCallback? onReceived;

  @override
  State<ShipmentDetailScreen> createState() => _ShipmentDetailScreenState();
}

class _ShipmentDetailScreenState extends State<ShipmentDetailScreen> {
  late Future<ShipmentModel> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.shipmentDetail(widget.shipmentId);
  }

  Future<void> _receive() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('입고 확인'),
        content: const Text('이 출고를 입고 처리할까요?\n수량이 매장 재고에 반영됩니다.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('닫기')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('입고 처리')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy = true);
    try {
      final updated = await widget.repository.receive(widget.shipmentId);
      setState(() { _future = Future.value(updated); });
      widget.onReceived?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('입고가 완료되어 재고에 반영되었습니다.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.mango800,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFB02A2A),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('배송 상세')),
      body: FutureBuilder<ShipmentModel>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.accent));
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
                    Row(children: [
                      Text(s.shipmentNo,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      _StatusPill(label: s.statusLabel, status: s.status),
                    ]),
                    const SizedBox(height: 12),
                    _row('공급', s.seller ?? '-'),
                    if (s.carrier != null) _row('택배', s.carrier!),
                    if (s.trackingNo != null) _row('송장번호', s.trackingNo!),
                    if (s.confirmedAt != null) _row('출고일', s.confirmedAt!),
                    if (s.receivedAt != null) _row('입고일', s.receivedAt!),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Text('배송 품목',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
              for (final it in s.items)
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
                        child: Text(it.productName,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700))),
                    Text('${it.qty}${it.unit}',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accent)),
                  ]),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: FutureBuilder<ShipmentModel>(
        future: _future,
        builder: (context, snap) {
          final s = snap.data;
          if (s == null || s.status != 'confirmed') {
            return const SizedBox.shrink();
          }
          return Container(
            color: AppColors.cream,
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, 16 + MediaQuery.of(context).padding.bottom),
            child: FilledButton.icon(
              onPressed: _busy ? null : _receive,
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54)),
              icon: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.2, color: Colors.white))
                  : const Icon(Icons.inventory_2_outlined),
              label: const Text('입고 처리 (재고 반영)'),
            ),
          );
        },
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          SizedBox(
              width: 64,
              child: Text(k,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.inkSoft))),
          Expanded(
              child: Text(v,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink))),
        ]),
      );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.status});
  final String label;
  final String status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = status == 'received'
        ? (const Color(0xFFE7F6EC), const Color(0xFF1E8E4E))
        : (AppColors.mango100, AppColors.mango800);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Text(label,
          style: TextStyle(
              color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}
