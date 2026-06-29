import 'package:flutter/material.dart';

import '../../data/seller_repository.dart';
import '../../models/fulfillment.dart';
import '../../theme/app_colors.dart';

/// 매장 주문 변경(수정/취소) 확인·반영 — 본사/공급처.
class OrderChangesScreen extends StatefulWidget {
  const OrderChangesScreen({super.key, required this.repository, this.onChanged});
  final SellerRepository repository;
  final VoidCallback? onChanged;

  @override
  State<OrderChangesScreen> createState() => _OrderChangesScreenState();
}

class _OrderChangesScreenState extends State<OrderChangesScreen> {
  late Future<({List<OrderChangeItem> changes, int pending})> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.orderChanges();
  }

  Future<void> _reload() async {
    setState(() { _future = widget.repository.orderChanges(); });
    await _future;
    widget.onChanged?.call();
  }

  Future<void> _ack(int id) async {
    setState(() => _busy = true);
    try {
      await widget.repository.ackChange(id);
      await _reload();
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _ackAll() async {
    setState(() => _busy = true);
    try {
      await widget.repository.ackAllChanges();
      await _reload();
      _snack('모든 변경을 반영했습니다.');
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(m),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.mango800));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('주문 변경'),
        actions: [
          TextButton(
            onPressed: _busy ? null : _ackAll,
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
            child: const Text('모두 반영', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: _reload,
        child: FutureBuilder<({List<OrderChangeItem> changes, int pending})>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.accent));
            }
            final list = snap.data?.changes ?? const [];
            if (list.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 140),
                Icon(Icons.fact_check_outlined, size: 48, color: AppColors.inkSoft),
                SizedBox(height: 12),
                Center(child: Text('변경 내역이 없습니다', style: TextStyle(color: AppColors.inkSoft))),
              ]);
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: list.length,
              itemBuilder: (context, i) => _Tile(
                change: list[i],
                busy: _busy,
                onAck: () => _ack(list[i].id),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.change, required this.busy, required this.onAck});
  final OrderChangeItem change;
  final bool busy;
  final VoidCallback onAck;

  @override
  Widget build(BuildContext context) {
    final isCancel = change.changeType == 'canceled';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: change.acknowledged ? AppColors.line : AppColors.mango300,
            width: change.acknowledged ? 1 : 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isCancel ? const Color(0xFFFDECEC) : AppColors.mango100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(change.typeLabel,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isCancel ? const Color(0xFFB02A2A) : AppColors.mango800)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(change.orderNo,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            ),
            if (change.acknowledged)
              const Text('반영됨', style: TextStyle(fontSize: 12, color: AppColors.inkSoft))
            else
              FilledButton(
                onPressed: busy ? null : onAck,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  minimumSize: Size.zero,
                ),
                child: const Text('반영'),
              ),
          ]),
          const SizedBox(height: 8),
          Text('${change.storeName ?? ''} · ${change.createdAt ?? ''}',
              style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
          if (change.summary != null && change.summary!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppColors.cream, borderRadius: BorderRadius.circular(10)),
              child: Text(change.summary!,
                  style: const TextStyle(fontSize: 13, color: AppColors.ink, height: 1.4)),
            ),
          ],
        ],
      ),
    );
  }
}
