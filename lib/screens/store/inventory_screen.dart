import 'package:flutter/material.dart';

import '../../data/store_ops_repository.dart';
import '../../models/store_ops.dart';
import '../../theme/app_colors.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key, required this.repository});

  final StoreOpsRepository repository;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  late Future<List<InventoryItem>> _stock;
  late Future<List<InventoryMovementItem>> _moves;
  String _q = '';
  String _type = 'all';

  @override
  void initState() {
    super.initState();
    _stock = widget.repository.inventory();
    _moves = widget.repository.movements();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _reloadStock() =>
      setState(() { _stock = widget.repository.inventory(q: _q); });
  void _reloadMoves() =>
      setState(() { _moves = widget.repository.movements(type: _type); });

  Future<void> _useStock(InventoryItem item) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UsageSheet(repository: widget.repository, item: item),
    );
    if (result == true) {
      _reloadStock();
      _reloadMoves();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('재고'),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.inkSoft,
          indicatorColor: AppColors.accent,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800),
          tabs: const [Tab(text: '재고 현황'), Tab(text: '이동 내역')],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [_stockTab(), _movesTab()],
      ),
    );
  }

  Widget _stockTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: (v) => _q = v,
            onSubmitted: (_) => _reloadStock(),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: '품목명 검색',
              prefixIcon: const Icon(Icons.search, color: AppColors.inkSoft),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.accent),
              ),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<InventoryItem>>(
            future: _stock,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: AppColors.accent));
              }
              final items = snap.data ?? const [];
              if (items.isEmpty) {
                return const Center(
                    child: Text('재고가 없습니다',
                        style: TextStyle(color: AppColors.inkSoft)));
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final it = items[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(it.productName,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text('단위: ${it.unitName}',
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.inkSoft)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${it.qty}',
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.accent)),
                            Text(it.unitName,
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.inkSoft)),
                          ],
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => _useStock(it),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.accent,
                            side: const BorderSide(color: AppColors.mango300),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                          ),
                          child: const Text('사용',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _movesTab() {
    const types = {'all': '전체', 'in': '입고', 'out': '출고', 'adjust': '조정'};
    return Column(
      children: [
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            children: [
              for (final e in types.entries)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      _type = e.key;
                      _reloadMoves();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _type == e.key
                            ? AppColors.accent
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                            color: _type == e.key
                                ? AppColors.accent
                                : AppColors.line),
                      ),
                      child: Text(e.value,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _type == e.key
                                  ? Colors.white
                                  : AppColors.inkSoft)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<InventoryMovementItem>>(
            future: _moves,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: AppColors.accent));
              }
              final items = snap.data ?? const [];
              if (items.isEmpty) {
                return const Center(
                    child: Text('이동 내역이 없습니다',
                        style: TextStyle(color: AppColors.inkSoft)));
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final m = items[i];
                  final isIn = m.type == 'in';
                  final color = isIn
                      ? const Color(0xFF1E8E4E)
                      : (m.type == 'out'
                          ? const Color(0xFFB02A2A)
                          : AppColors.inkSoft);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6)),
                          child: Text(m.typeLabel,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: color)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.productName,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                              if (m.createdAt != null)
                                Text(m.createdAt!,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.inkSoft)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${m.qty > 0 ? '+' : ''}${m.qty}',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: color)),
                            Text('잔여 ${m.balanceAfter}',
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.inkSoft)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _UsageSheet extends StatefulWidget {
  const _UsageSheet({required this.repository, required this.item});
  final StoreOpsRepository repository;
  final InventoryItem item;

  @override
  State<_UsageSheet> createState() => _UsageSheetState();
}

class _UsageSheetState extends State<_UsageSheet> {
  int _qty = 1;
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      final msg = await widget.repository.useStock(
        inventoryId: widget.item.id,
        qty: _qty,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(msg),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.mango800),
      );
    } catch (e) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.toString()),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFB02A2A)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, 20 + MediaQuery.of(context).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(100)),
              ),
            ),
            const SizedBox(height: 16),
            Text('${item.productName} 사용',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('현재 재고 ${item.qty}${item.unitName}',
                style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text('사용 수량',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const Spacer(),
                _StepBtn(
                    icon: Icons.remove,
                    onTap: () => setState(() {
                          if (_qty > 1) _qty--;
                        })),
                SizedBox(
                  width: 48,
                  child: Text('$_qty',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                ),
                _StepBtn(
                    icon: Icons.add,
                    onTap: () => setState(() {
                          if (_qty < item.qty) _qty++;
                        })),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _note,
              decoration: InputDecoration(
                hintText: '메모 (선택)',
                filled: true,
                fillColor: AppColors.surface,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _submit,
              style:
                  FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.2, color: Colors.white))
                  : const Text('사용 처리'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.mango100,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: AppColors.mango800),
        ),
      ),
    );
  }
}
