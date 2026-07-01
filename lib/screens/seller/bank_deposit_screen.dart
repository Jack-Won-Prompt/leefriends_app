import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/seller_repository.dart';
import '../../models/bank_deposit.dart';
import '../../models/store_ops.dart' show won;
import '../../theme/app_colors.dart';

/// 본사 계좌 입금확인 — 계좌 거래내역 수집 + 입금자↔매장 매핑 + 주문 대사.
class BankDepositScreen extends StatefulWidget {
  const BankDepositScreen({super.key, required this.repository});

  final SellerRepository repository;

  @override
  State<BankDepositScreen> createState() => _BankDepositScreenState();
}

class _BankDepositScreenState extends State<BankDepositScreen> {
  Future<BankIndex>? _future;
  String? _acc;
  String? _jobId;
  Timer? _poll;
  bool _busy = false;

  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  void _reload() {
    setState(() => _future = widget.repository.bank(acc: _acc, jobId: _jobId));
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _msg(Object e) => e.toString().replaceFirst('OrderException: ', '');

  void _toast(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m),
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? const Color(0xFFB02A2A) : AppColors.mango800,
    ));
  }

  Future<void> _run(Future<String> Function() action) async {
    setState(() => _busy = true);
    try {
      final msg = await action();
      _toast(msg);
      _reload();
    } catch (e) {
      _toast(_msg(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pick(bool start, DateTime fallback) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (start ? _start : _end) ?? fallback,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => start ? _start = picked : _end = picked);
    }
  }

  Future<void> _request() async {
    if (_acc == null) {
      _toast('계좌를 먼저 선택해 주세요.', error: true);
      return;
    }
    final s = _start ?? DateTime.now().subtract(const Duration(days: 30));
    final e = _end ?? DateTime.now();
    setState(() => _busy = true);
    try {
      await widget.repository.bankRequest(acc: _acc!, startDate: _fmt(s), endDate: _fmt(e));
      _toast('수집을 요청했습니다. 잠시 후 완료됩니다.');
      _reload();
      // 폴링: 최신 job이 완료되면 재조회
      _poll?.cancel();
      _poll = Timer.periodic(const Duration(seconds: 4), (t) async {
        try {
          final idx = await widget.repository.bank(acc: _acc);
          final latest = idx.jobs.isNotEmpty ? idx.jobs.first : null;
          if (latest == null) {
            t.cancel();
            return;
          }
          if (latest.done) {
            t.cancel();
            setState(() => _jobId = latest.jobId);
            _reload();
            _toast('수집 완료');
          } else {
            final st = await widget.repository.bankJobState(latest.jobId);
            if (st.done) {
              t.cancel();
              setState(() => _jobId = latest.jobId);
              _reload();
              _toast('수집 완료');
            }
          }
        } catch (_) {
          t.cancel();
        }
      });
    } catch (e) {
      _toast(_msg(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = 24 + MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('계좌 입금확인')),
      body: FutureBuilder<BankIndex>(
        future: _future,
        builder: (context, snap) {
          return RefreshIndicator(
            color: AppColors.accent,
            onRefresh: () async => _reload(),
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 12, 16, bottom),
              children: [
                if (snap.connectionState == ConnectionState.waiting && !snap.hasData)
                  const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(child: CircularProgressIndicator(color: AppColors.accent)))
                else if (snap.hasError)
                  _errorBox(_msg(snap.error!))
                else if (snap.hasData)
                  ..._content(snap.data!),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _content(BankIndex d) {
    _acc ??= d.selectedAcc;
    return [
      if (d.accountsError != null)
        _note('계좌 목록 조회 오류: ${d.accountsError}', error: true),
      if (d.accounts.isEmpty && d.accountsError == null)
        _note('등록된 계좌가 없습니다. 팝빌 콘솔에서 계좌를 먼저 등록하세요.'),
      if (d.accounts.isNotEmpty) _accountSelector(d),
      const SizedBox(height: 12),
      _requestCard(d),
      const SizedBox(height: 12),
      _summaryCard(d),
      const SizedBox(height: 12),
      if (d.deposits.isNotEmpty) ...[
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('입금 내역', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          TextButton.icon(
            onPressed: _busy ? null : () => _run(() => widget.repository.bankAutoMatch(_acc)),
            icon: const Icon(Icons.auto_fix_high, size: 16),
            label: const Text('자동 대사'),
          ),
        ]),
        for (final dep in d.deposits) _depositTile(dep, d.stores),
      ] else
        _note('입금 내역이 없습니다. 계좌·기간을 선택하고 수집을 요청하세요.'),
    ];
  }

  Widget _accountSelector(BankIndex d) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: _acc,
            hint: const Text('계좌 선택'),
            items: [
              for (final a in d.accounts)
                DropdownMenuItem(value: a.key, child: Text(a.label)),
            ],
            onChanged: (v) {
              setState(() {
                _acc = v;
                _jobId = null;
              });
              _reload();
            },
          ),
        ),
      );

  Widget _requestCard(BankIndex d) {
    final s = _start ?? DateTime.tryParse(d.defStart ?? '') ?? DateTime.now();
    final e = _end ?? DateTime.tryParse(d.defEnd ?? '') ?? DateTime.now();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('거래내역 수집',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _dateField('시작일', s, () => _pick(true, s))),
          const SizedBox(width: 10),
          Expanded(child: _dateField('종료일', e, () => _pick(false, e))),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _busy ? null : _request,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            icon: const Icon(Icons.cloud_download_outlined, size: 18),
            label: Text(_busy ? '요청 중…' : '수집 요청'),
          ),
        ),
      ]),
    );
  }

  Widget _dateField(String label, DateTime d, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
            const SizedBox(height: 3),
            Text(_fmt(d), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ]),
        ),
      );

  Widget _summaryCard(BankIndex d) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AppColors.mango600, AppColors.mango700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('총 입금 · ${d.count}건',
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(won(d.total),
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Row(children: [
            _chip('대사완료 ${d.matchedCount}', Colors.white24),
            const SizedBox(width: 8),
            _chip('미대사 ${d.unmatchedCount}', Colors.white24),
          ]),
        ]),
      );

  Widget _chip(String t, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
        child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
      );

  Widget _depositTile(BankDepositItem dep, List<BankStoreRef> stores) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dep.matched ? const Color(0xFFA7DCB9) : AppColors.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(dep.depositor ?? '(입금자 미상)',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('${dep.tradeDate ?? ''}${dep.remark != null ? ' · ${dep.remark}' : ''}',
                  style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
            ]),
          ),
          Text(won(dep.accIn),
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.accent)),
        ]),
        const SizedBox(height: 10),
        if (dep.matched && dep.matchedOrder != null)
          Row(children: [
            const Icon(Icons.check_circle, size: 16, color: Color(0xFF1E8E4E)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                  '대사완료 · ${dep.matchedOrder!.orderNo}${dep.matchedOrder!.storeName != null ? ' (${dep.matchedOrder!.storeName})' : ''}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF1E8E4E), fontWeight: FontWeight.w700)),
            ),
            TextButton(
              onPressed: _busy ? null : () => _run(() => widget.repository.bankUnmatch(dep.id)),
              child: const Text('해제'),
            ),
          ])
        else ...[
          Row(children: [
            Icon(Icons.storefront_outlined,
                size: 16,
                color: dep.resolvedStore != null ? AppColors.mango700 : AppColors.inkSoft),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                  dep.resolvedStore != null
                      ? '매장: ${dep.resolvedStore!.name}'
                      : '매장 미지정 (입금자 매핑 필요)',
                  style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
            ),
            TextButton(
              onPressed: _busy ? null : () => _mapDepositor(dep, stores),
              child: Text(dep.resolvedStore != null ? '매장 변경' : '매장 매핑'),
            ),
          ]),
          if (dep.candidates.isNotEmpty) ...[
            const SizedBox(height: 6),
            const Text('금액 일치 주문 (탭하여 대사)',
                style: TextStyle(fontSize: 11, color: AppColors.inkSoft)),
            const SizedBox(height: 4),
            for (final o in dep.candidates)
              InkWell(
                onTap: _busy ? null : () => _confirmMatch(dep, o),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.mango50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.mango300),
                  ),
                  child: Row(children: [
                    Expanded(
                        child: Text('${o.orderNo} · ${o.createdAt ?? ''}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                    Text(won(o.total ?? 0),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.accent)),
                    const Icon(Icons.link, size: 15, color: AppColors.mango700),
                  ]),
                ),
              ),
          ],
        ],
      ]),
    );
  }

  Future<void> _confirmMatch(BankDepositItem dep, BankOrderRef o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('입금 대사'),
        content: Text('${dep.depositor ?? '입금'} ${won(dep.accIn)} → ${o.orderNo} 주문과 대사하고 입금 완료 처리할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('대사')),
        ],
      ),
    );
    if (ok == true) _run(() => widget.repository.bankMatch(dep.id, o.id));
  }

  Future<void> _mapDepositor(BankDepositItem dep, List<BankStoreRef> stores) async {
    final selected = await showModalBottomSheet<BankStoreRef>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StorePicker(stores: stores, depositor: dep.depositor ?? ''),
    );
    if (selected != null) {
      _run(() => widget.repository
          .bankMapDepositor(dep.depositor ?? '', selected.id)
          .then((m) => '$m — 입금자 ${dep.depositor}'));
    }
  }

  Widget _note(String t, {bool error = false}) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: error ? const Color(0xFFFDECEC) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: error ? const Color(0xFFE9B0B0) : AppColors.line),
        ),
        child: Text(t,
            style: TextStyle(
                fontSize: 13,
                color: error ? const Color(0xFFB02A2A) : AppColors.inkSoft)),
      );

  Widget _errorBox(String msg) => Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(children: [
          const Icon(Icons.error_outline, color: AppColors.inkSoft, size: 40),
          const SizedBox(height: 10),
          Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.inkSoft)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _reload, child: const Text('다시 시도')),
        ]),
      );
}

/// 입금자 → 매장 매핑용 매장 선택 시트.
class _StorePicker extends StatefulWidget {
  const _StorePicker({required this.stores, required this.depositor});
  final List<BankStoreRef> stores;
  final String depositor;

  @override
  State<_StorePicker> createState() => _StorePickerState();
}

class _StorePickerState extends State<_StorePicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    final filtered = widget.stores
        .where((s) => s.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.line, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 14),
          Text("입금자 '${widget.depositor}' → 매장 선택",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: '매장 검색',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) => ListTile(
                title: Text(filtered[i].name),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(context, filtered[i]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
