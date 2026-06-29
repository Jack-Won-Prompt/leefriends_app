import 'package:flutter/material.dart';

import '../../data/seller_repository.dart';
import '../../models/edocs.dart';
import '../../models/store_ops.dart' show won;
import '../../theme/app_colors.dart';
import '../../widgets/paged_list_view.dart';

/// 본사/공급처 전자세금계산서 — 이력·발행·취소.
class SellerTaxInvoicesScreen extends StatefulWidget {
  const SellerTaxInvoicesScreen({super.key, required this.repository, required this.roleLabel});
  final SellerRepository repository;
  final String roleLabel; // '본사' | '공급처'

  @override
  State<SellerTaxInvoicesScreen> createState() => _SellerTaxInvoicesScreenState();
}

class _SellerTaxInvoicesScreenState extends State<SellerTaxInvoicesScreen> {
  int _reloadToken = 0;

  bool get _isHq => widget.roleLabel == '본사';

  void _reload() => setState(() => _reloadToken++);

  Future<void> _openIssue() async {
    final issued = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => IssueTaxInvoiceScreen(repository: widget.repository, roleLabel: widget.roleLabel),
    ));
    if (issued == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('세금계산서')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openIssue,
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add),
        label: Text(_isHq ? '매장 발행' : '본사 청구 발행'),
      ),
      body: PagedListView<SellerTaxInvoice>(
        key: ValueKey(_reloadToken),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        emptyText: '발행한 세금계산서가 없습니다',
        emptyIcon: Icons.description_outlined,
        fetch: (page) => widget.repository.taxInvoices(page: page),
        itemBuilder: (context, t) => _TaxInvoiceCard(
          invoice: t,
          onTap: () async {
            final changed = await Navigator.of(context).push<bool>(MaterialPageRoute(
              builder: (_) => SellerTaxInvoiceDetailScreen(
                  repository: widget.repository, id: t.id),
            ));
            if (changed == true) _reload();
          },
        ),
      ),
    );
  }
}

class _TaxInvoiceCard extends StatelessWidget {
  const _TaxInvoiceCard({required this.invoice, required this.onTap});
  final SellerTaxInvoice invoice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = invoice;
    return GestureDetector(
      onTap: onTap,
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
            Row(children: [
              Expanded(
                child: Text(t.invoiceNo,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              ),
              EDocStatusBadge(status: t.status, label: t.statusLabel),
            ]),
            const SizedBox(height: 6),
            Text('${t.counterpartyName ?? ''} · ${t.issueDate ?? ''}',
                style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
            const SizedBox(height: 8),
            Row(children: [
              if (t.note != null && t.note!.isNotEmpty)
                Text(t.note!, style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
              const Spacer(),
              Text(won(t.totalAmount),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.accent)),
            ]),
          ],
        ),
      ),
    );
  }
}

class EDocStatusBadge extends StatelessWidget {
  const EDocStatusBadge({super.key, required this.status, required this.label});
  final String status;
  final String label;
  @override
  Widget build(BuildContext context) {
    final (bg, fg) = status == 'canceled'
        ? (const Color(0xFFFDECEC), const Color(0xFFB02A2A))
        : (const Color(0xFFE7F6EC), const Color(0xFF1E8E4E));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: fg)),
    );
  }
}

/// 세금계산서 상세 — 문서 렌더 + 발행취소.
class SellerTaxInvoiceDetailScreen extends StatefulWidget {
  const SellerTaxInvoiceDetailScreen({super.key, required this.repository, required this.id});
  final SellerRepository repository;
  final int id;

  @override
  State<SellerTaxInvoiceDetailScreen> createState() => _SellerTaxInvoiceDetailScreenState();
}

class _SellerTaxInvoiceDetailScreenState extends State<SellerTaxInvoiceDetailScreen> {
  late Future<SellerTaxInvoice> _future;
  bool _busy = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.taxInvoiceDetail(widget.id);
  }

  Future<void> _cancel(SellerTaxInvoice t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('발행취소'),
        content: Text('세금계산서 ${t.invoiceNo}을(를) 발행취소할까요?\n국세청 전송 완료 후에는 취소가 불가할 수 있습니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('닫기')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB02A2A)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('발행취소'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy = true);
    try {
      final msg = await widget.repository.cancelTaxInvoice(t.id);
      _changed = true;
      setState(() { _future = widget.repository.taxInvoiceDetail(widget.id); });
      _toast(msg, ok: true);
    } catch (e) {
      _toast('$e'.replaceFirst('OrderException: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg, {bool ok = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: ok ? AppColors.mango800 : const Color(0xFFB02A2A),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {},
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          title: const Text('세금계산서'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _changed),
          ),
        ),
        body: FutureBuilder<SellerTaxInvoice>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator(color: AppColors.accent));
            }
            final t = snap.data!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _card([
                  Row(children: [
                    Expanded(
                      child: Text(t.note ?? '전자세금계산서',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                    EDocStatusBadge(status: t.status, label: t.statusLabel),
                  ]),
                  const SizedBox(height: 6),
                  Text('${t.invoiceNo} · ${t.issueDate ?? ''}',
                      style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                  if (t.ntsConfirmNum != null && t.ntsConfirmNum!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('국세청승인번호 ${t.ntsConfirmNum}',
                        style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                  ],
                ]),
                const SizedBox(height: 12),
                _party('공급자', t.invoicerName, t.invoicerCorpNum),
                const SizedBox(height: 8),
                _party('공급받는자', t.invoiceeCorpName ?? t.counterpartyName, t.invoiceeCorpNum,
                    email: t.invoiceeEmail),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
                  child: Text('품목', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ),
                if (t.lineItems.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('품목 내역 없음', style: TextStyle(color: AppColors.inkSoft)),
                  )
                else
                  for (final it in t.lineItems)
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
                              if (it.qty > 0) ...[
                                const SizedBox(height: 2),
                                Text('${it.qty}${it.unit} × ${won(it.unitPrice)}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                              ],
                            ],
                          ),
                        ),
                        Text(won(it.amount),
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.accent)),
                      ]),
                    ),
                const SizedBox(height: 8),
                _totals(t),
                if (t.canCancel) ...[
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _cancel(t),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB02A2A),
                      side: const BorderSide(color: Color(0xFFE0A3A3)),
                      minimumSize: const Size.fromHeight(50),
                    ),
                    icon: _busy
                        ? const SizedBox(
                            width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2))
                        : const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('발행취소'),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget _party(String label, String? name, String? corpNum, {String? email}) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 80,
              child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name ?? '-',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                if (corpNum != null && corpNum.isNotEmpty)
                  Text('사업자 $corpNum',
                      style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                if (email != null && email.isNotEmpty)
                  Text(email, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
              ],
            ),
          ),
        ]),
      );

  Widget _totals(SellerTaxInvoice t) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.mango900,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(children: [
          _row('공급가액', won(t.supplyAmount)),
          const SizedBox(height: 6),
          _row('세액', won(t.vat)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Colors.white24, height: 1),
          ),
          _row('합계', won(t.totalAmount), big: true),
        ]),
      );

  Widget _row(String k, String v, {bool big = false}) => Row(children: [
        Text(k,
            style: TextStyle(
                color: Colors.white70, fontSize: big ? 14 : 13, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(v,
            style: TextStyle(
                color: Colors.white, fontSize: big ? 20 : 14, fontWeight: FontWeight.w800)),
      ]);
}

/// 세금계산서 발행 — 본사: 매장+발주 선택 / 공급처: 배송완료 품목 선택.
class IssueTaxInvoiceScreen extends StatefulWidget {
  const IssueTaxInvoiceScreen({super.key, required this.repository, required this.roleLabel});
  final SellerRepository repository;
  final String roleLabel;

  @override
  State<IssueTaxInvoiceScreen> createState() => _IssueTaxInvoiceScreenState();
}

class _IssueTaxInvoiceScreenState extends State<IssueTaxInvoiceScreen> {
  bool get _isHq => widget.roleLabel == '본사';

  // 본사
  List<IssuableStore> _stores = const [];
  IssuableStore? _store;
  // 공통
  IssuableData? _data;
  final Set<int> _selected = {};
  bool _loading = true;
  bool _loadingTargets = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      if (_isHq) {
        _stores = await widget.repository.issuableStores();
      } else {
        _data = await widget.repository.taxInvoiceIssuable();
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = '$e'.replaceFirst('OrderException: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _loadStoreOrders(IssuableStore s) async {
    setState(() {
      _store = s;
      _loadingTargets = true;
      _selected.clear();
      _data = null;
    });
    try {
      final d = await widget.repository.taxInvoiceIssuable(storeId: s.id);
      setState(() {
        _data = d;
        _loadingTargets = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e'.replaceFirst('OrderException: ', '');
        _loadingTargets = false;
      });
    }
  }

  int get _selectedAmount {
    final d = _data;
    if (d == null) return 0;
    if (d.mode == 'orders') {
      return d.orders.where((o) => _selected.contains(o.id)).fold(0, (s, o) => s + o.amount);
    }
    return d.items.where((it) => _selected.contains(it.id)).fold(0, (s, it) => s + it.amount);
  }

  Future<void> _issue() async {
    if (_selected.isEmpty) return;
    if (_isHq && _store != null && !_store!.hasBizNo) {
      _toast('«${_store!.name}» 매장 사업자등록번호가 없습니다. 매장 관리에서 먼저 등록하세요.');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('세금계산서 발행'),
        content: Text(
            '선택한 ${_selected.length}건(합계 ${won(_selectedAmount)})을 팝빌로 즉시 발행합니다.\n발행 후에는 취소만 가능합니다. 진행할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('닫기')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('발행')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy = true);
    try {
      final msg = _isHq
          ? await widget.repository.issueTaxInvoice(storeId: _store!.id, orderIds: _selected.toList())
          : await widget.repository.issueTaxInvoice(itemIds: _selected.toList());
      if (!mounted) return;
      _toast(msg, ok: true);
      Navigator.pop(context, true);
    } catch (e) {
      _toast('$e'.replaceFirst('OrderException: ', ''));
      setState(() => _busy = false);
    }
  }

  void _toast(String msg, {bool ok = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: ok ? AppColors.mango800 : const Color(0xFFB02A2A),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(_isHq ? '세금계산서 발행 (매장)' : '세금계산서 발행 (본사 청구)')),
      bottomNavigationBar: _selected.isEmpty ? null : _bottomBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.inkSoft)),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    if (_isHq) _storePicker(),
                    if (_isHq && _store == null)
                      const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(
                            child: Text('매장을 선택하면 미발행 발주가 표시됩니다',
                                style: TextStyle(color: AppColors.inkSoft))),
                      ),
                    if (_loadingTargets)
                      const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
                      ),
                    if (_data != null) ..._targets(),
                  ],
                ),
    );
  }

  Widget _storePicker() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<IssuableStore>(
          value: _store,
          isExpanded: true,
          hint: const Text('매장 선택'),
          items: _stores
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.hasBizNo ? s.name : '${s.name} (사업자번호 없음)',
                        style: TextStyle(color: s.hasBizNo ? AppColors.ink : AppColors.inkSoft)),
                  ))
              .toList(),
          onChanged: (s) {
            if (s != null) _loadStoreOrders(s);
          },
        ),
      ),
    );
  }

  List<Widget> _targets() {
    final d = _data!;
    if (d.mode == 'orders') {
      if (d.orders.isEmpty) {
        return [
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(
                child: Text('미발행 발주가 없습니다', style: TextStyle(color: AppColors.inkSoft))),
          ),
        ];
      }
      return [
        _selectAllRow(d.orders.map((o) => o.id).toList()),
        for (final o in d.orders)
          _selectTile(
            id: o.id,
            title: o.orderNo,
            sub: '${o.createdAt ?? ''} · ${o.itemCount}품목',
            amount: o.amount,
          ),
      ];
    }
    // supplier items
    if (d.items.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.only(top: 40),
          child: Center(
              child: Text('배송완료·미청구 품목이 없습니다', style: TextStyle(color: AppColors.inkSoft))),
        ),
      ];
    }
    return [
      _selectAllRow(d.items.map((it) => it.id).toList()),
      for (final it in d.items)
        _selectTile(
          id: it.id,
          title: it.productName,
          sub: '${it.storeName ?? ''} · ${it.orderNo ?? ''} · ${it.qty}${it.unit}',
          amount: it.amount,
        ),
    ];
  }

  Widget _selectAllRow(List<int> ids) {
    final allSelected = ids.isNotEmpty && ids.every(_selected.contains);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Row(children: [
        Text('${_selected.length} / ${ids.length} 선택',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        const Spacer(),
        TextButton(
          onPressed: () => setState(() {
            if (allSelected) {
              _selected.removeAll(ids);
            } else {
              _selected.addAll(ids);
            }
          }),
          child: Text(allSelected ? '전체 해제' : '전체 선택'),
        ),
      ]),
    );
  }

  Widget _selectTile({
    required int id,
    required String title,
    required String sub,
    required int amount,
  }) {
    final on = _selected.contains(id);
    return GestureDetector(
      onTap: () => setState(() => on ? _selected.remove(id) : _selected.add(id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: on ? AppColors.mango50 : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: on ? AppColors.mango300 : AppColors.line),
        ),
        child: Row(children: [
          Icon(on ? Icons.check_box : Icons.check_box_outline_blank,
              color: on ? AppColors.accent : AppColors.inkSoft, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
              ],
            ),
          ),
          Text(won(amount),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.accent)),
        ]),
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${_selected.length}건 선택',
                  style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
              Text(won(_selectedAmount),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: _busy ? null : _issue,
          style: FilledButton.styleFrom(minimumSize: const Size(150, 52)),
          icon: _busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
              : const Icon(Icons.receipt_long, size: 18),
          label: const Text('발행하기'),
        ),
      ]),
    );
  }
}
