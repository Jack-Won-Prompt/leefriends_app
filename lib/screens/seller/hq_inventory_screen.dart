import 'package:flutter/material.dart';

import '../../data/seller_repository.dart';
import '../../models/hq_inventory.dart';
import '../../theme/app_colors.dart';
import '../../widgets/product_thumb.dart';

/// 본사 재고/물류 관리 — 창고 재고 조회·조정·수동입고·기본셋팅·입고알림. 본사 전용.
class HqInventoryScreen extends StatefulWidget {
  const HqInventoryScreen({super.key, required this.repository, this.embedded = false});

  final SellerRepository repository;
  /// 셸 하단 탭에 삽입될 때 true — Scaffold/AppBar 없이 본문만 렌더.
  final bool embedded;

  @override
  State<HqInventoryScreen> createState() => _HqInventoryScreenState();
}

class _HqInventoryScreenState extends State<HqInventoryScreen> {
  Future<HqInventoryIndex>? _future;
  String _q = '';
  String _only = 'all';

  @override
  void initState() {
    super.initState();
    // initState 에서는 setState 없이 직접 대입 (셸 IndexedStack 내 build 중 생성 대비)
    _future = widget.repository.hqInventory(q: _q, only: _only);
  }

  void _reload() =>
      setState(() { _future = widget.repository.hqInventory(q: _q, only: _only); });

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
    try {
      _toast(await action());
      _reload();
    } catch (e) {
      _toast(_msg(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = 24 + MediaQuery.of(context).padding.bottom;
    final body = Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => _q = v,
                  onSubmitted: (_) => _reload(),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: '품목명·코드 검색',
                    prefixIcon: const Icon(Icons.search, color: AppColors.inkSoft),
                    filled: true,
                    fillColor: AppColors.surface,
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.line)),
                  ),
                ),
              ),
              // 임베드 모드에선 AppBar가 없으므로 기본셋팅 버튼을 검색줄에 둠
              if (widget.embedded)
                IconButton(
                  tooltip: '기본재고 일괄 셋팅',
                  icon: const Icon(Icons.playlist_add, color: AppColors.mango700),
                  onPressed: _confirmSeed,
                ),
            ]),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final f in const [('all', '전체'), ('managed', '등록됨'), ('shortage', '부족')])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _chip(f.$2, _only == f.$1, () {
                      setState(() => _only = f.$1);
                      _reload();
                    }),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<HqInventoryIndex>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                }
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(_msg(snap.error!),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.inkSoft)),
                        const SizedBox(height: 12),
                        OutlinedButton(onPressed: _reload, child: const Text('다시 시도')),
                      ]),
                    ),
                  );
                }
                final rows = snap.data?.rows ?? const [];
                return RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: () async => _reload(),
                  child: rows.isEmpty
                      ? ListView(children: const [
                          Padding(
                              padding: EdgeInsets.only(top: 80),
                              child: Center(child: Text('품목이 없습니다', style: TextStyle(color: AppColors.inkSoft))))
                        ])
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(16, 8, 16, bottom),
                          itemCount: rows.length,
                          itemBuilder: (context, i) => _tile(rows[i]),
                        ),
                );
              },
            ),
          ),
        ],
      );

    if (widget.embedded) return body;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('본사 재고'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              if (v == 'seed') _confirmSeed();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'seed', child: Text('기본재고 일괄 셋팅(10개)')),
            ],
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
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

  Widget _tile(HqInventoryRow r) {
    final shortage = r.available != null && r.available! <= 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: shortage ? const Color(0xFFF0C9C9) : AppColors.line),
      ),
      child: Row(children: [
        ProductThumb(url: r.imageUrl, size: 46),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            if (!r.managed)
              const Text('미등록', style: TextStyle(fontSize: 12, color: AppColors.inkSoft))
            else
              Text('실물 ${r.qty} · 예약 ${r.reserved} · 가용 ${r.available}',
                  style: TextStyle(
                      fontSize: 12,
                      color: shortage ? const Color(0xFFB02A2A) : AppColors.inkSoft,
                      fontWeight: shortage ? FontWeight.w700 : FontWeight.w500)),
          ]),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.inkSoft),
          onSelected: (v) {
            if (v == 'adjust') _openAdjust(r);
            if (v == 'inbound') _openInbound(r);
            if (v == 'notify') _run(() => widget.repository.hqInventoryNotify(r.productId));
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'adjust', child: Text('재고 조정')),
            const PopupMenuItem(value: 'inbound', child: Text('입고(＋)')),
            if (r.managed && (r.qty ?? 0) > 0)
              const PopupMenuItem(value: 'notify', child: Text('입고 알림(전 매장)')),
          ],
        ),
      ]),
    );
  }

  Future<void> _confirmSeed() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('기본재고 일괄 셋팅'),
        content: const Text('재고가 없는(미등록/0) 품목에 기본 10개를 설정합니다. 진행할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('설정')),
        ],
      ),
    );
    if (ok == true) _run(() => widget.repository.hqInventorySeed());
  }

  Future<void> _openAdjust(HqInventoryRow r) => _openQty(
        title: '재고 조정 — ${r.name}',
        hint: '목표 수량 (실사값)',
        initial: r.qty ?? 0,
        min: 0,
        action: (qty, note) => widget.repository.hqInventoryAdjust(r.productId, qty, note: note),
      );

  Future<void> _openInbound(HqInventoryRow r) => _openQty(
        title: '입고 — ${r.name}',
        hint: '입고 수량 (가산)',
        initial: 0,
        min: 1,
        action: (qty, note) => widget.repository.hqInventoryInbound(r.productId, qty, note: note),
      );

  Future<void> _openQty({
    required String title,
    required String hint,
    required int initial,
    required int min,
    required Future<String> Function(int qty, String? note) action,
  }) async {
    final result = await showDialog<(int, String)>(
      context: context,
      builder: (_) => _QtyDialog(title: title, hint: hint, initial: initial, min: min),
    );
    if (result == null) return;
    _run(() => action(result.$1, result.$2.isEmpty ? null : result.$2));
  }
}

/// 재고 조정/입고 수량 입력 다이얼로그 — 컨트롤러를 자체 dispose 하여
/// showDialog 후 수동 dispose(닫힘 애니메이션 중 오류) 문제를 방지.
class _QtyDialog extends StatefulWidget {
  const _QtyDialog(
      {required this.title, required this.hint, required this.initial, required this.min});
  final String title;
  final String hint;
  final int initial;
  final int min;

  @override
  State<_QtyDialog> createState() => _QtyDialogState();
}

class _QtyDialogState extends State<_QtyDialog> {
  late final TextEditingController _qty =
      TextEditingController(text: widget.initial > 0 ? '${widget.initial}' : '');
  final _note = TextEditingController();
  String? _err;

  @override
  void dispose() {
    _qty.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    final qty = int.tryParse(_qty.text.trim()) ?? -1;
    if (qty < widget.min) {
      setState(() => _err = '수량을 확인해 주세요.');
      return;
    }
    Navigator.pop(context, (qty, _note.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title, style: const TextStyle(fontSize: 16)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          controller: _qty,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
              labelText: widget.hint,
              errorText: _err,
              border: const OutlineInputBorder()),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _note,
          decoration: const InputDecoration(labelText: '메모 (선택)', border: OutlineInputBorder()),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
        FilledButton(onPressed: _submit, child: const Text('저장')),
      ],
    );
  }
}
