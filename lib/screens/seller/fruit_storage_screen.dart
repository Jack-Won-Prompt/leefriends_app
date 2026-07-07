import 'package:flutter/material.dart';

import '../../data/seller_repository.dart';
import '../../data/store_ops_repository.dart';
import '../../models/store_ops.dart';
import '../../theme/app_colors.dart';

/// 과일 보관 가이드.
/// - 본사(manage=true): SellerRepository로 CRUD + 매장 공유 토글.
/// - 매장(manage=false): StoreOpsRepository로 공유 항목 읽기.
class FruitStorageScreen extends StatefulWidget {
  const FruitStorageScreen.manage({super.key, required SellerRepository repository})
      : _hq = repository,
        _store = null;
  const FruitStorageScreen.readonly({super.key, required StoreOpsRepository repository})
      : _hq = null,
        _store = repository;

  final SellerRepository? _hq;
  final StoreOpsRepository? _store;

  bool get manage => _hq != null;

  @override
  State<FruitStorageScreen> createState() => _FruitStorageScreenState();
}

class _FruitStorageScreenState extends State<FruitStorageScreen> {
  Future<List<FruitStorageItem>>? _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<List<FruitStorageItem>> _fetch() =>
      widget.manage ? widget._hq!.fruitStorages() : widget._store!.fruitStorages();

  void _reload() => setState(() { _future = _fetch(); });

  void _toast(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(m.replaceFirst('OrderException: ', '')),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? const Color(0xFFB02A2A) : AppColors.mango800));
  }

  Future<void> _run(Future<String> Function() action) async {
    setState(() => _busy = true);
    try {
      _toast(await action());
      _reload();
    } catch (e) {
      _toast(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit([FruitStorageItem? item]) async {
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _FruitEditor(item: item),
    );
    if (data == null) return;
    _run(() => widget._hq!.saveFruitStorage(data, id: item?.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(widget.manage ? '과일 보관 관리' : '과일 보관 가이드')),
      floatingActionButton: widget.manage
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.accent,
              onPressed: _busy ? null : () => _edit(),
              icon: const Icon(Icons.add),
              label: const Text('보관 추가'),
            )
          : null,
      body: FutureBuilder<List<FruitStorageItem>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            if (snap.hasError) {
              return Center(
                  child: Text(snap.error.toString().replaceFirst('OrderException: ', ''),
                      style: const TextStyle(color: AppColors.inkSoft)));
            }
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }
          final rows = snap.data!;
          return RefreshIndicator(
            color: AppColors.accent,
            onRefresh: () async => _reload(),
            child: rows.isEmpty
                ? ListView(children: [
                    const SizedBox(height: 120),
                    const Icon(Icons.ac_unit, size: 48, color: AppColors.inkSoft),
                    const SizedBox(height: 12),
                    Center(
                        child: Text(
                            widget.manage ? '등록된 보관 항목이 없습니다' : '공유된 보관 가이드가 없습니다',
                            style: const TextStyle(color: AppColors.inkSoft))),
                  ])
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                    itemCount: rows.length,
                    itemBuilder: (context, i) => _tile(rows[i]),
                  ),
          );
        },
      ),
    );
  }

  Widget _tile(FruitStorageItem f) {
    final chips = <Widget>[
      if (f.tempC != null && f.tempC!.isNotEmpty) _chip('🌡 ${f.tempC}'),
      if (f.humidity != null && f.humidity!.isNotEmpty) _chip('💧 ${f.humidity}'),
      if (f.ventilation != null && f.ventilation!.isNotEmpty) _chip('🌬 ${f.ventilation}'),
      if (f.dehumidification != null && f.dehumidification!.isNotEmpty) _chip('제습 ${f.dehumidification}'),
      if (f.storagePeriod != null && f.storagePeriod!.isNotEmpty) _chip('기간 ${f.storagePeriod}'),
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: f.isActive ? AppColors.line : const Color(0xFFE2E2E2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(f.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
            if (widget.manage) ...[
              if (f.isShared)
                _badge('공유중', const Color(0xFF1E8E4E), const Color(0xFFE7F6EC))
              else
                _badge('비공유', AppColors.inkSoft, const Color(0xFFEDEDED)),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.inkSoft),
                onSelected: (v) {
                  if (v == 'edit') _edit(f);
                  if (v == 'share') _run(() => widget._hq!.toggleFruitStorageShare(f.id));
                  if (v == 'del') _confirmDelete(f);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('수정')),
                  PopupMenuItem(value: 'share', child: Text(f.isShared ? '매장 공유 끄기' : '매장 공유 켜기')),
                  const PopupMenuItem(value: 'del', child: Text('삭제')),
                ],
              ),
            ],
          ]),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: chips),
          ],
          if (f.note != null && f.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(f.note!, style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
          ],
        ],
      ),
    );
  }

  Widget _chip(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: AppColors.cream, borderRadius: BorderRadius.circular(100)),
        child: Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      );

  Widget _badge(String t, Color fg, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
        child: Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
      );

  Future<void> _confirmDelete(FruitStorageItem f) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제'),
        content: Text("‘${f.name}’ 보관 항목을 삭제할까요?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제')),
        ],
      ),
    );
    if (ok == true) _run(() => widget._hq!.deleteFruitStorage(f.id));
  }
}

/// 보관 항목 추가/수정 — 결과 맵 반환.
class _FruitEditor extends StatefulWidget {
  const _FruitEditor({this.item});
  final FruitStorageItem? item;

  @override
  State<_FruitEditor> createState() => _FruitEditorState();
}

class _FruitEditorState extends State<_FruitEditor> {
  late final _name = TextEditingController(text: widget.item?.name ?? '');
  late final _tempC = TextEditingController(text: widget.item?.tempC ?? '');
  late final _humidity = TextEditingController(text: widget.item?.humidity ?? '');
  late final _ventilation = TextEditingController(text: widget.item?.ventilation ?? '');
  late final _period = TextEditingController(text: widget.item?.storagePeriod ?? '');
  late final _note = TextEditingController(text: widget.item?.note ?? '');
  late bool _shared = widget.item?.isShared ?? true;

  @override
  void dispose() {
    _name.dispose();
    _tempC.dispose();
    _humidity.dispose();
    _ventilation.dispose();
    _period.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? '보관 항목 추가' : '보관 항목 수정'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _f(_name, '품목명 (예: 애플망고)'),
          _f(_tempC, '보관 온도 (예: 11~13℃)'),
          _f(_humidity, '습도 (예: 85~90%)'),
          _f(_ventilation, '환기 (예: 필요)'),
          _f(_period, '보관 기간 (예: 7~10일)'),
          _f(_note, '메모', lines: 2),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _shared,
            activeThumbColor: AppColors.accent,
            title: const Text('매장에 공유', style: TextStyle(fontSize: 14)),
            onChanged: (v) => setState(() => _shared = v),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
        FilledButton(
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(context, {
              'name': name,
              'temp_c': _tempC.text.trim(),
              'humidity': _humidity.text.trim(),
              'ventilation': _ventilation.text.trim(),
              'storage_period': _period.text.trim(),
              'note': _note.text.trim(),
              'is_shared': _shared,
              'is_active': true,
            });
          },
          child: const Text('저장'),
        ),
      ],
    );
  }

  Widget _f(TextEditingController c, String label, {int lines = 1}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          maxLines: lines,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        ),
      );
}
