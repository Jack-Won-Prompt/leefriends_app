import 'package:flutter/material.dart';

import '../../data/seller_repository.dart';
import '../../models/edocs.dart';
import '../../models/paged.dart';
import '../../models/store_ops.dart' show won;
import '../../theme/app_colors.dart';
import '../../widgets/paged_list_view.dart';
import 'seller_tax_invoices_screen.dart' show EDocStatusBadge;

/// 본사/공급처 거래명세서 — 이력·작성/전송·발행.
class SellerStatementsScreen extends StatefulWidget {
  const SellerStatementsScreen({super.key, required this.repository, required this.roleLabel});
  final SellerRepository repository;
  final String roleLabel; // '본사' | '공급처'

  @override
  State<SellerStatementsScreen> createState() => _SellerStatementsScreenState();
}

class _SellerStatementsScreenState extends State<SellerStatementsScreen> {
  int _reloadToken = 0;

  bool get _isHq => widget.roleLabel == '본사';

  void _reload() => setState(() => _reloadToken++);

  Future<void> _create() async {
    final done = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => CreateStatementScreen(repository: widget.repository, roleLabel: widget.roleLabel),
    ));
    if (done == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('거래명세서')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add),
        label: Text(_isHq ? '작성·전송' : '작성'),
      ),
      body: PagedListView<StatementListItem>(
        key: ValueKey(_reloadToken),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        emptyText: '작성한 거래명세서가 없습니다',
        emptyIcon: Icons.receipt_long_outlined,
        fetch: (page) async {
          final r = await widget.repository.statements(page: page);
          return Paged(items: r.statements, hasMore: r.hasMore);
        },
        itemBuilder: (context, item) => _StatementCard(
          item: item,
          isHq: _isHq,
          onTap: () async {
            final changed = await Navigator.of(context).push<bool>(MaterialPageRoute(
              builder: (_) => StatementDetailScreen(
                  repository: widget.repository, id: item.id, roleLabel: widget.roleLabel),
            ));
            if (changed == true) _reload();
          },
        ),
      ),
    );
  }
}

class _StatementCard extends StatelessWidget {
  const _StatementCard({required this.item, required this.isHq, required this.onTap});
  final StatementListItem item;
  final bool isHq;
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
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(item.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              ),
              if (item.invoiced)
                const EDocStatusBadge(status: 'issued', label: '발행됨')
              else if (isHq && item.resendCount > 0)
                _MiniBadge(label: '재전송 ${item.resendCount}')
              else if (!isHq && item.emailed)
                const _MiniBadge(label: '전송됨'),
            ]),
            const SizedBox(height: 6),
            Text('${item.sub ?? ''} · ${item.date ?? ''} · ${item.itemCount}품목',
                style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
            const SizedBox(height: 8),
            Row(children: [
              const Spacer(),
              Text(won(item.total),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.accent)),
            ]),
          ],
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
            color: const Color(0xFFEFF3FA), borderRadius: BorderRadius.circular(100)),
        child: Text(label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF1B6CC4))),
      );
}

/// 거래명세서 상세 — 품목·합계 + 재전송 / (공급처) 세금계산서 발행.
class StatementDetailScreen extends StatefulWidget {
  const StatementDetailScreen({
    super.key,
    required this.repository,
    required this.id,
    required this.roleLabel,
  });
  final SellerRepository repository;
  final int id;
  final String roleLabel;

  @override
  State<StatementDetailScreen> createState() => _StatementDetailScreenState();
}

class _StatementDetailScreenState extends State<StatementDetailScreen> {
  late Future<StatementDetail> _future;
  bool _busy = false;
  bool _changed = false;

  bool get _isHq => widget.roleLabel == '본사';

  @override
  void initState() {
    super.initState();
    _future = widget.repository.statementDetail(widget.id);
  }

  void _refresh() => setState(() { _future = widget.repository.statementDetail(widget.id); });

  Future<void> _send() async {
    setState(() => _busy = true);
    try {
      final msg = await widget.repository.sendStatement(widget.id);
      _changed = true;
      _toast(msg, ok: true);
      _refresh();
    } catch (e) {
      _toast('$e'.replaceFirst('OrderException: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _issue() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('세금계산서 발행'),
        content: const Text('이 거래명세서로 본사 청구 세금계산서를 팝빌로 즉시 발행합니다.\n진행할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('닫기')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('발행')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy = true);
    try {
      final msg = await widget.repository.issueStatement(widget.id);
      _changed = true;
      _toast(msg, ok: true);
      _refresh();
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
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('거래명세서'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _changed),
        ),
      ),
      body: FutureBuilder<StatementDetail>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }
          final s = snap.data!;
          return ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 32 + MediaQuery.of(context).padding.bottom),
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
                      const Expanded(
                        child: Text('거래명세서',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
                      if (s.invoiced) const EDocStatusBadge(status: 'issued', label: '발행됨'),
                    ]),
                    const SizedBox(height: 6),
                    Text('${s.title} · ${s.date ?? ''}',
                        style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                    if (s.email != null && s.email!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('수신 ${s.email}',
                          style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Text('품목', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
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
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.mango900,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(children: [
                  if (s.supplyTotal != null) ...[
                    _row('공급가액', won(s.supplyTotal!)),
                    const SizedBox(height: 6),
                    _row('세액', won(s.vat ?? 0)),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(color: Colors.white24, height: 1),
                    ),
                  ],
                  _row('합계', won(s.total), big: true),
                ]),
              ),
              const SizedBox(height: 20),
              if (!_isHq && s.canIssue)
                FilledButton.icon(
                  onPressed: _busy ? null : _issue,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  icon: const Icon(Icons.receipt_long, size: 18),
                  label: const Text('세금계산서 발행 (본사 청구)'),
                ),
              if (!_isHq && s.canIssue) const SizedBox(height: 10),
              if (s.canResend)
                OutlinedButton.icon(
                  onPressed: _busy ? null : _send,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.mango300),
                    minimumSize: const Size.fromHeight(50),
                  ),
                  icon: _busy
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2))
                      : const Icon(Icons.mail_outline, size: 18),
                  label: Text(_isHq ? '매장에 재전송' : '본사에 전송'),
                ),
            ],
          );
        },
      ),
    );
  }

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

/// 거래명세서 작성 — 본사: 매장+품목 선택 후 전송 / 공급처: 자사 품목 선택 후 저장(+전송).
class CreateStatementScreen extends StatefulWidget {
  const CreateStatementScreen({super.key, required this.repository, required this.roleLabel});
  final SellerRepository repository;
  final String roleLabel;

  @override
  State<CreateStatementScreen> createState() => _CreateStatementScreenState();
}

class _CreateStatementScreenState extends State<CreateStatementScreen> {
  bool get _isHq => widget.roleLabel == '본사';

  StatementCatalog? _catalog;
  CatalogStore? _store;
  final Map<int, int> _qty = {}; // productId → qty
  bool _loading = true;
  bool _busy = false;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _catalog = await widget.repository.statementCatalog();
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = '$e'.replaceFirst('OrderException: ', '');
        _loading = false;
      });
    }
  }

  int get _total {
    final c = _catalog;
    if (c == null) return 0;
    var sum = 0;
    for (final p in c.catalog) {
      final q = _qty[p.id] ?? 0;
      sum += q * p.price;
    }
    return sum;
  }

  int get _lineCount => _qty.values.where((q) => q > 0).length;

  List<Map<String, int>> get _items => _qty.entries
      .where((e) => e.value > 0)
      .map((e) => {'product_id': e.key, 'qty': e.value})
      .toList();

  Future<void> _submit({required bool send}) async {
    if (_items.isEmpty) {
      _toast('품목을 1개 이상 선택해 주세요.');
      return;
    }
    if (_isHq) {
      if (_store == null) {
        _toast('매장을 선택해 주세요.');
        return;
      }
      if (!_store!.hasEmail) {
        _toast('«${_store!.name}» 매장에 이메일이 없습니다. 매장 관리에서 먼저 등록하세요.');
        return;
      }
    }

    setState(() => _busy = true);
    try {
      final msg = await widget.repository.createStatement(
        storeId: _isHq ? _store!.id : null,
        items: _items,
        send: send,
      );
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
    final c = _catalog;
    final products = c == null
        ? <CatalogProduct>[]
        : c.catalog
            .where((p) => _search.isEmpty || p.name.toLowerCase().contains(_search.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('거래명세서 작성')),
      bottomNavigationBar: _lineCount == 0 ? null : _bottomBar(),
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
              : Column(
                  children: [
                    if (_isHq) _storePicker(c!),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: '품목 검색',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          isDense: true,
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.line),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.line),
                          ),
                        ),
                        onChanged: (v) => setState(() => _search = v),
                      ),
                    ),
                    Expanded(
                      child: products.isEmpty
                          ? const Center(
                              child: Text('품목이 없습니다', style: TextStyle(color: AppColors.inkSoft)))
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                              itemCount: products.length,
                              itemBuilder: (context, i) => _productRow(products[i]),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _storePicker(StatementCatalog c) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CatalogStore>(
          value: _store,
          isExpanded: true,
          hint: const Text('매장 선택 (수신처)'),
          items: c.stores
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.hasEmail ? s.name : '${s.name} (이메일 없음)',
                        style: TextStyle(color: s.hasEmail ? AppColors.ink : AppColors.inkSoft)),
                  ))
              .toList(),
          onChanged: (s) => setState(() => _store = s),
        ),
      ),
    );
  }

  Widget _productRow(CatalogProduct p) {
    final q = _qty[p.id] ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: q > 0 ? AppColors.mango50 : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: q > 0 ? AppColors.mango300 : AppColors.line),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('${p.unit} · ${won(p.price)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
            ],
          ),
        ),
        _stepper(p, q),
      ]),
    );
  }

  Widget _stepper(CatalogProduct p, int q) {
    if (q == 0) {
      return TextButton.icon(
        onPressed: () => setState(() => _qty[p.id] = 1),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('담기'),
        style: TextButton.styleFrom(foregroundColor: AppColors.accent),
      );
    }
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _circle(Icons.remove, () => setState(() {
            final n = q - 1;
            if (n <= 0) {
              _qty.remove(p.id);
            } else {
              _qty[p.id] = n;
            }
          })),
      SizedBox(
        width: 36,
        child: Text('$q',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ),
      _circle(Icons.add, () => setState(() => _qty[p.id] = q + 1)),
    ]);
  }

  Widget _circle(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.mango100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.mango700),
        ),
      );

  Widget _bottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Text('$_lineCount품목',
              style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
          const Spacer(),
          Text(won(_total),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 10),
        if (_isHq)
          FilledButton.icon(
            onPressed: _busy ? null : () => _submit(send: true),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            icon: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                : const Icon(Icons.send, size: 18),
            label: const Text('매장에 전송'),
          )
        else
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : () => _submit(send: false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.mango300),
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('저장만'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _busy ? null : () => _submit(send: true),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                icon: _busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                    : const Icon(Icons.send, size: 18),
                label: const Text('본사 전송'),
              ),
            ),
          ]),
      ]),
    );
  }
}
