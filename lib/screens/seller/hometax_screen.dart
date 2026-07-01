import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/seller_repository.dart';
import '../../models/hometax.dart';
import '../../models/store_ops.dart' show won;
import '../../theme/app_colors.dart';

/// 본사 매출/매입 — 홈택스 전자세금계산서 수집·조회.
class HometaxScreen extends StatefulWidget {
  const HometaxScreen({super.key, required this.repository});

  final SellerRepository repository;

  @override
  State<HometaxScreen> createState() => _HometaxScreenState();
}

class _HometaxScreenState extends State<HometaxScreen> {
  String _type = 'SELL'; // SELL 매출 / BUY 매입
  int _page = 1;
  String? _jobId;
  Future<HometaxIndex>? _future;
  Timer? _poll;
  bool _requesting = false;

  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _start = DateTime(now.year, now.month, 1);
    _end = DateTime(now.year, now.month, now.day);
    _reload();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = widget.repository.hometax(type: _type, page: _page, jobId: _jobId);
    });
  }

  void _switchType(String t) {
    if (_type == t) return;
    setState(() {
      _type = t;
      _page = 1;
      _jobId = null;
    });
    _reload();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pick(bool start) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? _start : _end,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (start) {
          _start = picked;
        } else {
          _end = picked;
        }
      });
    }
  }

  Future<void> _request() async {
    setState(() => _requesting = true);
    try {
      final job = await widget.repository.hometaxRequest(
        tiType: _type,
        startDate: _fmt(_start),
        endDate: _fmt(_end),
      );
      _toast('수집을 요청했습니다. 잠시 후 완료됩니다.');
      setState(() {
        _jobId = job.jobId;
        _page = 1;
      });
      _reload();
      _startPolling(job.id);
    } catch (e) {
      _toast(_msg(e), error: true);
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  void _startPolling(int jobRowId) {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 4), (t) async {
      try {
        final st = await widget.repository.hometaxJobState(jobRowId);
        if (!mounted) return;
        if (st.done) {
          t.cancel();
          _reload();
          _toast('수집 완료 (${st.count}건)');
        }
      } catch (_) {
        t.cancel();
      }
    });
  }

  Future<void> _openUrl(Future<String> Function() getter, String failMsg) async {
    try {
      final url = await getter();
      if (url.isEmpty) throw Exception('URL 없음');
      final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!ok) throw Exception('브라우저 열기 실패');
    } catch (e) {
      _toast('$failMsg: ${_msg(e)}', error: true);
    }
  }

  String _msg(Object e) => e.toString().replaceFirst('OrderException: ', '');

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
      appBar: AppBar(title: const Text('매출/매입 (홈택스)')),
      body: FutureBuilder<HometaxIndex>(
        future: _future,
        builder: (context, snap) {
          return RefreshIndicator(
            color: AppColors.accent,
            onRefresh: () async => _reload(),
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 12, 16, bottom),
              children: [
                _typeToggle(),
                const SizedBox(height: 14),
                if (snap.connectionState == ConnectionState.waiting && !snap.hasData)
                  const Padding(
                      padding: EdgeInsets.only(top: 60),
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

  Widget _typeToggle() => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(children: [
          _typeBtn('SELL', '매출'),
          _typeBtn('BUY', '매입'),
        ]),
      );

  Widget _typeBtn(String t, String label) {
    final active = _type == t;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchType(t),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: active ? Colors.white : AppColors.inkSoft)),
        ),
      ),
    );
  }

  List<Widget> _content(HometaxIndex d) => [
        _statusCard(d),
        const SizedBox(height: 12),
        _requestCard(),
        const SizedBox(height: 12),
        if (d.jobs.isNotEmpty) ...[
          _sectionTitle('수집 이력'),
          for (final j in d.jobs.take(8)) _jobTile(j, d.selectedJobId),
          const SizedBox(height: 12),
        ],
        if (d.summary != null) _summaryCard(d.summary!),
        if (d.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text('조회 오류: ${d.error}',
                style: const TextStyle(color: Color(0xFFB02A2A), fontSize: 12)),
          ),
        if (d.invoices.isNotEmpty) ...[
          const SizedBox(height: 12),
          _sectionTitle('${_type == 'BUY' ? '매입' : '매출'} 세금계산서'),
          for (final inv in d.invoices) _invoiceTile(inv),
          _pager(d),
        ] else if (d.summary != null)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text('조회된 세금계산서가 없습니다.',
                style: TextStyle(color: AppColors.inkSoft, fontSize: 13)),
          ),
      ];

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 6, 2, 8),
        child: Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
      );

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: child,
      );

  Widget _statusCard(HometaxIndex d) => _card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('홈택스 연동 상태',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.verified_user_outlined, size: 18, color: AppColors.mango700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                d.certExpire != null && d.certExpire!.isNotEmpty
                    ? '공동인증서 만료: ${d.certExpire}'
                    : '공동인증서 미등록',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: () => _openUrl(widget.repository.hometaxCertUrl, '인증서 등록'),
              child: const Text('인증서 등록'),
            ),
          ]),
          const Divider(height: 8),
          Row(children: [
            const Icon(Icons.workspace_premium_outlined, size: 18, color: AppColors.mango700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                d.flatRateState == '1' || d.flatRateState == 'true'
                    ? '정액제 사용 중'
                    : '정액제 미사용(건별 과금)',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: () => _openUrl(widget.repository.hometaxFlatRateUrl, '정액제 신청'),
              child: const Text('정액제 신청'),
            ),
          ]),
        ]),
      );

  Widget _requestCard() => _card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${_type == 'BUY' ? '매입' : '매출'} 세금계산서 수집',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _dateField('시작일', _start, () => _pick(true))),
            const SizedBox(width: 10),
            Expanded(child: _dateField('종료일', _end, () => _pick(false))),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _requesting ? null : _request,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              icon: const Icon(Icons.cloud_download_outlined, size: 18),
              label: Text(_requesting ? '요청 중…' : '수집 요청'),
            ),
          ),
          const SizedBox(height: 4),
          const Text('홈택스에서 기간 내 세금계산서를 가져옵니다 (수 초~수십 초 소요).',
              style: TextStyle(fontSize: 11, color: AppColors.inkSoft)),
        ]),
      );

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
            Text(_fmt(d),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ]),
        ),
      );

  Widget _jobTile(HometaxJob j, String? selected) {
    final isSel = j.jobId == selected;
    final color = j.done
        ? const Color(0xFF1E8E4E)
        : (j.jobState == 2 ? AppColors.mango700 : AppColors.inkSoft);
    return GestureDetector(
      onTap: j.done
          ? () {
              setState(() {
                _jobId = j.jobId;
                _page = 1;
              });
              _reload();
            }
          : () => _startPolling(j.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSel ? AppColors.mango50 : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSel ? AppColors.mango300 : AppColors.line),
        ),
        child: Row(children: [
          Icon(j.done ? Icons.check_circle : Icons.hourglass_bottom, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${j.typeLabel} · ${_period(j)}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                  j.done
                      ? '${j.stateLabel} · ${j.collectCount}건'
                      : (j.errorReason ?? j.stateLabel),
                  style: TextStyle(fontSize: 12, color: color)),
            ]),
          ),
          if (j.done)
            const Icon(Icons.chevron_right, color: AppColors.inkSoft)
          else if (j.jobState != 3)
            const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent)),
        ]),
      ),
    );
  }

  String _period(HometaxJob j) {
    String f(String? s) => (s != null && s.length == 8)
        ? '${s.substring(0, 4)}.${s.substring(4, 6)}.${s.substring(6, 8)}'
        : (s ?? '');
    return '${f(j.startDate)}~${f(j.endDate)}';
  }

  Widget _summaryCard(HometaxSummary s) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AppColors.mango600, AppColors.mango700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('합계 · ${s.count}건',
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _sumRow('공급가액', s.supply),
          _sumRow('세액', s.tax),
          const Divider(color: Colors.white24, height: 16),
          _sumRow('합계금액', s.amount, big: true),
        ]),
      );

  Widget _sumRow(String label, int v, {bool big = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: Colors.white70, fontSize: big ? 14 : 12, fontWeight: FontWeight.w600))),
          Text(won(v),
              style: TextStyle(
                  color: Colors.white,
                  fontSize: big ? 18 : 14,
                  fontWeight: FontWeight.w800)),
        ]),
      );

  Widget _invoiceTile(HometaxInvoice inv) {
    final counterparty =
        _type == 'BUY' ? inv.invoicerCorpName : inv.invoiceeCorpName;
    return GestureDetector(
      onTap: () => _showDetail(inv.ntsConfirmNum),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(counterparty ?? '-',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text('${inv.writeDate ?? ''} · 승인 ${inv.ntsConfirmNum}',
                  style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(won(inv.total),
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.accent)),
            Text('세액 ${won(inv.tax)}',
                style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
          ]),
        ]),
      ),
    );
  }

  Widget _pager(HometaxIndex d) {
    if (d.pageCount <= 1) return const SizedBox(height: 8);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton(
          onPressed: _page > 1
              ? () {
                  setState(() => _page--);
                  _reload();
                }
              : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('${d.page} / ${d.pageCount}',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        IconButton(
          onPressed: _page < d.pageCount
              ? () {
                  setState(() => _page++);
                  _reload();
                }
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ]),
    );
  }

  Future<void> _showDetail(String nts) async {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: FutureBuilder<Map<String, dynamic>>(
          future: widget.repository.hometaxDetail(nts),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator(color: AppColors.accent)));
            }
            if (snap.hasError) {
              return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_msg(snap.error!),
                      style: const TextStyle(color: Color(0xFFB02A2A))));
            }
            final d = snap.data ?? {};
            return _detailView(d);
          },
        ),
      ),
    );
  }

  Widget _detailView(Map<String, dynamic> d) {
    int n(String k) => (d[k] as num?)?.toInt() ?? 0;
    String s(String k) => d[k]?.toString() ?? '-';
    final items = (d['items'] as List? ?? []);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 560),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          const Text('세금계산서 상세',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _kv('작성일자', s('writeDate')),
          _kv('국세청승인번호', s('ntsconfirmNum')),
          const Divider(),
          _kv('공급자', '${s('invoicerCorpName')} (${s('invoicerCorpNum')})'),
          _kv('대표', s('invoicerCEOName')),
          _kv('공급받는자', '${s('invoiceeCorpName')} (${s('invoiceeCorpNum')})'),
          const Divider(),
          _kv('공급가액', won(n('supplyCostTotal'))),
          _kv('세액', won(n('taxTotal'))),
          _kv('합계', won(n('totalAmount'))),
          if (items.isNotEmpty) ...[
            const Divider(),
            const Text('품목', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            for (final it in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  Expanded(
                      child: Text('${(it as Map)['itemName'] ?? ''}',
                          style: const TextStyle(fontSize: 13))),
                  Text(won(((it)['supplyCost'] as num?)?.toInt() ?? 0),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ]),
              ),
          ],
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
                onPressed: () => Navigator.pop(context), child: const Text('닫기')),
          ),
        ]),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 96,
              child: Text(k, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft))),
          Expanded(
              child: Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        ]),
      );

  Widget _errorBox(String msg) => Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(children: [
          const Icon(Icons.error_outline, color: AppColors.inkSoft, size: 40),
          const SizedBox(height: 10),
          Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.inkSoft)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _reload, child: const Text('다시 시도')),
        ]),
      );
}
