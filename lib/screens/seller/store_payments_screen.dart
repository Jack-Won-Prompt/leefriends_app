import 'package:flutter/material.dart';

import '../../data/seller_repository.dart';
import '../../models/store_payment.dart';
import '../../models/store_ops.dart' show won;
import '../../theme/app_colors.dart';

/// 매장별 입금현황 — 총 발주액 대비 입금완료/미입금 집계 (본사 전용).
class StorePaymentsScreen extends StatefulWidget {
  const StorePaymentsScreen({super.key, required this.repository});

  final SellerRepository repository;

  @override
  State<StorePaymentsScreen> createState() => _StorePaymentsScreenState();
}

class _StorePaymentsScreenState extends State<StorePaymentsScreen> {
  String _period = 'all'; // all | month | month_sel
  int? _month;
  late int _year;
  Future<StorePaymentIndex>? _future;

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
    _reload();
  }

  void _reload() {
    setState(() {
      _future = widget.repository.storePayments(period: _period, year: _year, month: _month);
    });
  }

  void _setPeriod(String p, {int? month}) {
    setState(() {
      _period = p;
      _month = month;
    });
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = 24 + MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('매장별 입금현황')),
      body: FutureBuilder<StorePaymentIndex>(
        future: _future,
        builder: (context, snap) {
          return RefreshIndicator(
            color: AppColors.accent,
            onRefresh: () async => _reload(),
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 12, 16, bottom),
              children: [
                _periodBar(),
                const SizedBox(height: 12),
                if (snap.connectionState == ConnectionState.waiting && !snap.hasData)
                  const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Center(child: CircularProgressIndicator(color: AppColors.accent)))
                else if (snap.hasError)
                  _errorBox(snap.error.toString())
                else if (snap.hasData) ...[
                  _totalsCard(snap.data!.totals),
                  const SizedBox(height: 14),
                  const Text('매장별', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  if (snap.data!.stores.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Center(
                          child: Text('데이터가 없습니다',
                              style: TextStyle(color: AppColors.inkSoft))),
                    )
                  else
                    for (final s in snap.data!.stores) _storeTile(s),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _periodBar() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _pChip('전체', _period == 'all', () => _setPeriod('all')),
          const SizedBox(width: 8),
          _pChip('이번 달', _period == 'month', () => _setPeriod('month')),
          const SizedBox(width: 8),
          for (var m = 1; m <= 12; m++) ...[
            _pChip('$m월', _period == 'month_sel' && _month == m,
                () => _setPeriod('month_sel', month: m)),
            const SizedBox(width: 8),
          ],
        ]),
      );

  Widget _pChip(String label, bool active, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

  Widget _totalsCard(StorePaymentTotals t) {
    final rate = t.total > 0 ? (t.paid / t.total) : 0.0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppColors.mango600, AppColors.mango700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('총 발주액',
            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(won(t.total),
            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: rate,
            minHeight: 8,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _miniStat('입금완료', won(t.paid))),
          Expanded(child: _miniStat('미입금', won(t.unpaid))),
          Expanded(child: _miniStat('미입금 건', '${t.unpaidCnt}건')),
        ]),
      ]),
    );
  }

  Widget _miniStat(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
        ],
      );

  Widget _storeTile(StorePaymentRow s) => GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => _StorePaymentDetailScreen(
            repository: widget.repository,
            storeId: s.id,
            period: _period,
            year: _year,
            month: _month,
          ),
        )).then((_) => _reload()),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: s.unpaidCnt > 0 ? const Color(0xFFF0C9C9) : AppColors.line),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(s.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
              if (s.unpaidCnt > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFDECEC), borderRadius: BorderRadius.circular(100)),
                  child: Text('미입금 ${s.unpaidCnt}건',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFB02A2A))),
                )
              else
                const Icon(Icons.check_circle, size: 18, color: Color(0xFF1E8E4E)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _kv('발주', won(s.total))),
              Expanded(child: _kv('입금', won(s.paid))),
              Expanded(child: _kv('미입금', won(s.unpaid), warn: s.unpaid > 0)),
            ]),
          ]),
        ),
      );

  Widget _kv(String k, String v, {bool warn = false}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
          const SizedBox(height: 2),
          Text(v,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: warn ? const Color(0xFFB02A2A) : AppColors.ink)),
        ],
      );

  Widget _errorBox(String msg) => Padding(
        padding: const EdgeInsets.only(top: 50),
        child: Column(children: [
          const Icon(Icons.error_outline, color: AppColors.inkSoft, size: 40),
          const SizedBox(height: 10),
          Text(msg.replaceFirst('OrderException: ', ''),
              textAlign: TextAlign.center, style: const TextStyle(color: AppColors.inkSoft)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _reload, child: const Text('다시 시도')),
        ]),
      );
}

/// 매장 드릴다운 — 미입금/입금완료 발주 목록 + 미입금 안내 SMS.
class _StorePaymentDetailScreen extends StatefulWidget {
  const _StorePaymentDetailScreen({
    required this.repository,
    required this.storeId,
    required this.period,
    required this.year,
    required this.month,
  });

  final SellerRepository repository;
  final int storeId;
  final String period;
  final int year;
  final int? month;

  @override
  State<_StorePaymentDetailScreen> createState() => _StorePaymentDetailScreenState();
}

class _StorePaymentDetailScreenState extends State<_StorePaymentDetailScreen> {
  Future<StorePaymentDetail>? _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = widget.repository.storePaymentDetail(widget.storeId,
          period: widget.period, year: widget.year, month: widget.month);
    });
  }

  Future<void> _requestUnpaid() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('미입금 안내 SMS'),
        content: const Text('현재 기간의 미입금 총액·건수를 매장에 문자로 안내합니다. 진행할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('전송')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      final msg = await widget.repository.storePaymentRequestUnpaid(widget.storeId,
          period: widget.period, year: widget.year, month: widget.month);
      _toast(msg);
    } catch (e) {
      _toast(e.toString().replaceFirst('OrderException: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m),
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? const Color(0xFFB02A2A) : AppColors.mango800,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = 24 + MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('매장 입금 상세')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1E8E4E),
        onPressed: _busy ? null : _requestUnpaid,
        icon: const Icon(Icons.sms_outlined),
        label: const Text('미입금 안내 SMS'),
      ),
      body: FutureBuilder<StorePaymentDetail>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }
          if (snap.hasError) {
            return Center(
                child: Text(snap.error.toString().replaceFirst('OrderException: ', ''),
                    style: const TextStyle(color: AppColors.inkSoft)));
          }
          final d = snap.data!;
          return ListView(
            padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 60),
            children: [
              Text(d.storeName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              if (d.orders.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: Text('발주 내역이 없습니다', style: TextStyle(color: AppColors.inkSoft))),
                )
              else
                for (final o in d.orders) _orderTile(o),
            ],
          );
        },
      ),
    );
  }

  Widget _orderTile(StorePaymentOrder o) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: o.paid ? const Color(0xFFA7DCB9) : const Color(0xFFF0C9C9)),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(o.orderNo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text('${o.itemCount}품목 · ${o.createdAt ?? ''}${o.statusLabel != null ? ' · ${o.statusLabel}' : ''}',
                  style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(won(o.total),
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.accent)),
            const SizedBox(height: 3),
            o.paid
                ? Text('입금완료${o.paidAt != null ? ' ${o.paidAt}' : ''}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF1E8E4E), fontWeight: FontWeight.w700))
                : const Text('미입금',
                    style: TextStyle(fontSize: 11, color: Color(0xFFB02A2A), fontWeight: FontWeight.w700)),
          ]),
        ]),
      );
}
