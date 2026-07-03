import 'package:flutter/material.dart';

import '../../data/seller_repository.dart';
import '../../models/fulfillment.dart';
import '../../models/paged.dart';
import '../../models/store_ops.dart' show won;
import '../../theme/app_colors.dart';
import '../../widgets/product_thumb.dart';
import '../../widgets/paged_list_view.dart';
import 'seller_widgets.dart';

class SellerSalesOrdersScreen extends StatefulWidget {
  const SellerSalesOrdersScreen(
      {super.key,
      required this.repository,
      this.onChanged,
      this.initialStatus = 'all',
      this.inlineConfirm = false});
  final SellerRepository repository;
  final VoidCallback? onChanged;
  final String initialStatus;

  /// true면 확인 대기(신규 발주)만 보여주고, 목록에서 바로 발주확인.
  final bool inlineConfirm;

  @override
  State<SellerSalesOrdersScreen> createState() => _SellerSalesOrdersScreenState();
}

class _SellerSalesOrdersScreenState extends State<SellerSalesOrdersScreen> {
  late String _status = widget.initialStatus;
  List<StatusOption> _statuses = const [];
  int _reloadToken = 0;
  final Set<int> _confirming = {};

  void _select(String s) => setState(() => _status = s);
  void _reload() => setState(() => _reloadToken++);

  void _toast(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(m.replaceFirst('OrderException: ', '')),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? const Color(0xFFB02A2A) : AppColors.mango800));
  }

  Future<void> _confirmInline(SellerSalesOrder so) async {
    setState(() => _confirming.add(so.id));
    try {
      final msg = await widget.repository.confirmSalesOrder(so.id);
      widget.onChanged?.call();
      if (mounted) {
        _toast(msg.isEmpty ? '발주를 확인했습니다. 출고 대기로 이동합니다.' : msg);
        _reload(); // 확인된 발주는 신규 목록에서 사라짐
      }
    } catch (e) {
      if (mounted) {
        setState(() => _confirming.remove(so.id));
        _toast(e.toString(), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(widget.inlineConfirm ? '확인 대기 (신규 발주)' : '판매주문')),
      body: Column(
        children: [
          if (!widget.inlineConfirm)
            StatusFilterBar(
                statuses: _statuses, selected: _status, onSelect: _select),
          Expanded(
            child: PagedListView<SellerSalesOrder>(
              key: ValueKey('$_status-$_reloadToken'),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              emptyText: widget.inlineConfirm
                  ? '확인 대기 중인 신규 발주가 없습니다'
                  : '판매주문이 없습니다',
              fetch: (page) async {
                final r = await widget.repository.salesOrders(status: _status, page: page);
                if (page == 1 && _statuses.isEmpty && r.statuses.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _statuses = r.statuses);
                  });
                }
                return Paged(items: r.orders, hasMore: r.hasMore);
              },
              itemBuilder: (context, so) => _Tile(
                so: so,
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => SalesOrderDetailScreen(
                      repository: widget.repository,
                      id: so.id,
                      onChanged: widget.onChanged,
                    ),
                  ));
                  _reload();
                },
                onConfirm: (widget.inlineConfirm && so.status == 'created')
                    ? () => _confirmInline(so)
                    : null,
                confirming: _confirming.contains(so.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.so,
    required this.onTap,
    this.onConfirm,
    this.confirming = false,
  });
  final SellerSalesOrder so;
  final VoidCallback onTap;

  /// 목록에서 바로 발주확인 (null이면 버튼 숨김).
  final VoidCallback? onConfirm;
  final bool confirming;

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
                child: Text(so.salesOrderNo,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              ),
              FulfillStatusChip(status: so.status, label: so.statusLabel),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: Text('${so.storeName ?? ''} · ${so.itemCount}품목',
                    style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
              ),
              Text(won(so.amount),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.accent)),
            ]),
            if (onConfirm != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: confirming ? null : onConfirm,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                  icon: confirming
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(confirming ? '확인 중…' : '발주확인 → 출고 대기'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SalesOrderDetailScreen extends StatefulWidget {
  const SalesOrderDetailScreen(
      {super.key, required this.repository, required this.id, this.onChanged});
  final SellerRepository repository;
  final int id;
  final VoidCallback? onChanged;

  @override
  State<SalesOrderDetailScreen> createState() => _SalesOrderDetailScreenState();
}

class _SalesOrderDetailScreenState extends State<SalesOrderDetailScreen> {
  late Future<SellerSalesOrder> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.salesOrderDetail(widget.id);
  }

  Future<void> _confirm() async {
    setState(() => _busy = true);
    try {
      final msg = await widget.repository.confirmSalesOrder(widget.id);
      widget.onChanged?.call();
      setState(() { _future = widget.repository.salesOrderDetail(widget.id); });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(msg),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.mango800));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFB02A2A)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('판매주문 상세')),
      body: FutureBuilder<SellerSalesOrder>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.accent));
          }
          final so = snap.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _card([
                Row(children: [
                  Text(so.salesOrderNo,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  FulfillStatusChip(status: so.status, label: so.statusLabel),
                ]),
                const SizedBox(height: 10),
                _row('매장', so.storeName ?? '-'),
                _row('발주번호', so.orderNo ?? '-'),
                if (so.createdAt != null) _row('접수', so.createdAt!),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.mango900,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Text(so.sellerType == 'supplier' ? '판매주문 합계 (공급가)' : '판매주문 합계',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(won(so.amount),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  ]),
                ),
              ]),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Text('품목', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
              for (final it in so.items)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(children: [
                    ProductThumb(url: it.imageUrl, size: 42),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text('${it.productName}  ·  ${it.qty}${it.unit}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                    Text(won(so.itemAmount(it)),
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.accent)),
                  ]),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: FutureBuilder<SellerSalesOrder>(
        future: _future,
        builder: (context, snap) {
          if (snap.data?.status != 'created') return const SizedBox.shrink();
          return Container(
            color: AppColors.cream,
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, 16 + MediaQuery.of(context).padding.bottom),
            child: FilledButton.icon(
              onPressed: _busy ? null : _confirm,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
              icon: _busy
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline),
              label: const Text('판매주문 확인'),
            ),
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

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          SizedBox(width: 64, child: Text(k, style: const TextStyle(fontSize: 13, color: AppColors.inkSoft))),
          Expanded(child: Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        ]),
      );
}
