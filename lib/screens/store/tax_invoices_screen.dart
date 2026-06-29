import 'package:flutter/material.dart';

import '../../data/store_ops_repository.dart';
import '../../models/store_ops.dart';
import '../../theme/app_colors.dart';
import '../../widgets/paged_list_view.dart';

/// 매장 세금계산서 — 본사 발행분 조회.
class TaxInvoicesScreen extends StatefulWidget {
  const TaxInvoicesScreen({super.key, required this.repository});
  final StoreOpsRepository repository;

  @override
  State<TaxInvoicesScreen> createState() => _TaxInvoicesScreenState();
}

class _TaxInvoicesScreenState extends State<TaxInvoicesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('세금계산서')),
      body: PagedListView<StoreTaxInvoice>(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        emptyText: '발행된 세금계산서가 없습니다',
        emptyIcon: Icons.description_outlined,
        fetch: (page) => widget.repository.taxInvoices(page: page),
        itemBuilder: (context, t) => GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => TaxInvoiceDetailScreen(repository: widget.repository, id: t.id),
          )),
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
                  _StatusBadge(status: t.status, label: t.statusLabel),
                ]),
                const SizedBox(height: 6),
                Text('${t.invoicerName ?? '본사'} · ${t.issueDate ?? ''}',
                    style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                const SizedBox(height: 8),
                Row(children: [
                  const Text('합계', style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                  const Spacer(),
                  Text(won(t.totalAmount),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.accent)),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.label});
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

/// 세금계산서 상세 — 문서 형태 렌더.
class TaxInvoiceDetailScreen extends StatefulWidget {
  const TaxInvoiceDetailScreen({super.key, required this.repository, required this.id});
  final StoreOpsRepository repository;
  final int id;

  @override
  State<TaxInvoiceDetailScreen> createState() => _TaxInvoiceDetailScreenState();
}

class _TaxInvoiceDetailScreenState extends State<TaxInvoiceDetailScreen> {
  late Future<StoreTaxInvoice> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.taxInvoiceDetail(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('세금계산서')),
      body: FutureBuilder<StoreTaxInvoice>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }
          final t = snap.data!;
          return ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 32 + MediaQuery.of(context).padding.bottom),
            children: [
              _card([
                Row(children: [
                  const Text('전자세금계산서',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  _StatusBadge(status: t.status, label: t.statusLabel),
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
              _party('공급자', t.invoicerCorpName ?? t.invoicerName, t.invoicerCorpNum),
              const SizedBox(height: 8),
              _party('공급받는자', t.invoiceeCorpName, t.invoiceeCorpNum),
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
                        child: Text('${it.name}  ${it.qty > 0 ? '· ${it.qty}' : ''}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                      Text(won(it.amount),
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.accent)),
                    ]),
                  ),
              const SizedBox(height: 8),
              _totals(t),
            ],
          );
        },
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

  Widget _party(String label, String? name, String? corpNum) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(children: [
          SizedBox(
              width: 80,
              child: Text(label,
                  style: const TextStyle(fontSize: 12, color: AppColors.inkSoft))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name ?? '-',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                if (corpNum != null && corpNum.isNotEmpty)
                  Text('사업자 $corpNum',
                      style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
              ],
            ),
          ),
        ]),
      );

  Widget _totals(StoreTaxInvoice t) => Container(
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
