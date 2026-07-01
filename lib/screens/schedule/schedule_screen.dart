import 'package:flutter/material.dart';

import '../../data/schedule_repository.dart';
import '../../models/schedule.dart';
import '../../theme/app_colors.dart';

/// 일정(캘린더) — 본사/매장/공급처 각자 소속 일정 조회·등록·수정·삭제.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key, required this.repository, this.roleLabel = ''});

  final ScheduleRepository repository;
  final String roleLabel;

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  static const _weekdays = ['일', '월', '화', '수', '목', '금', '토'];

  late Future<List<ScheduleItem>> _future;
  Map<String, List<ScheduleItem>> _byDate = {};
  late DateTime _month; // 표시 중인 달의 1일
  late DateTime _selected; // 선택된 날짜

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
    _selected = DateTime(now.year, now.month, now.day);
    _future = _load();
  }

  Future<List<ScheduleItem>> _load() async {
    final items = await widget.repository.list();
    final map = <String, List<ScheduleItem>>{};
    for (final s in items) {
      map.putIfAbsent(s.dateKey, () => []).add(s);
    }
    if (mounted) setState(() => _byDate = map);
    return items;
  }

  void _reload() => setState(() { _future = _load(); });

  String _key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta, 1));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = 24 + MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('일정'),
        actions: [
          IconButton(
            tooltip: '오늘',
            icon: const Icon(Icons.today_outlined),
            onPressed: () {
              final now = DateTime.now();
              setState(() {
                _month = DateTime(now.year, now.month, 1);
                _selected = DateTime(now.year, now.month, now.day);
              });
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('일정 추가'),
      ),
      body: FutureBuilder<List<ScheduleItem>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && _byDate.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }
          if (snap.hasError) {
            return _errorView(snap.error.toString());
          }
          return RefreshIndicator(
            color: AppColors.accent,
            onRefresh: _load,
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 12, 16, bottom),
              children: [
                _monthHeader(),
                const SizedBox(height: 8),
                _calendarGrid(),
                const SizedBox(height: 16),
                _selectedDayList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _errorView(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, color: AppColors.inkSoft, size: 40),
            const SizedBox(height: 10),
            Text(msg.replaceFirst('OrderException: ', ''),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.inkSoft)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _reload, child: const Text('다시 시도')),
          ]),
        ),
      );

  Widget _monthHeader() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
              onPressed: () => _shiftMonth(-1),
              icon: const Icon(Icons.chevron_left)),
          Text('${_month.year}년 ${_month.month}월',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          IconButton(
              onPressed: () => _shiftMonth(1),
              icon: const Icon(Icons.chevron_right)),
        ],
      );

  Widget _calendarGrid() {
    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday % 7; // 일=0
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final cells = <Widget>[];

    // 요일 헤더
    for (var i = 0; i < 7; i++) {
      cells.add(Center(
        child: Text(_weekdays[i],
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: i == 0
                    ? const Color(0xFFB02A2A)
                    : (i == 6 ? const Color(0xFF1B6CC4) : AppColors.inkSoft))),
      ));
    }

    // 빈 앞칸
    for (var i = 0; i < firstWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }

    final today = DateTime.now();
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_month.year, _month.month, day);
      final key = _key(date);
      final items = _byDate[key] ?? const [];
      final isSelected = _key(_selected) == key;
      final isToday = today.year == date.year &&
          today.month == date.month &&
          today.day == date.day;
      final weekday = date.weekday % 7;

      cells.add(GestureDetector(
        onTap: () => setState(() => _selected = date),
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isToday && !isSelected
                ? Border.all(color: AppColors.mango300)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$day',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (weekday == 0
                              ? const Color(0xFFB02A2A)
                              : (weekday == 6
                                  ? const Color(0xFF1B6CC4)
                                  : AppColors.ink)))),
              const SizedBox(height: 3),
              SizedBox(
                height: 6,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final s in items.take(3))
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : ScheduleColors.of(s.color),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ));
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.82,
      children: cells,
    );
  }

  Widget _selectedDayList() {
    final key = _key(_selected);
    final items = _byDate[key] ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('${_selected.month}월 ${_selected.day}일 (${_weekdays[_selected.weekday % 7]})',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          Text('${items.length}건',
              style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
        ]),
        const SizedBox(height: 10),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: const Text('등록된 일정이 없습니다',
                style: TextStyle(color: AppColors.inkSoft, fontSize: 13)),
          )
        else
          for (final s in items) _scheduleTile(s),
      ],
    );
  }

  Widget _scheduleTile(ScheduleItem s) {
    final color = ScheduleColors.of(s.color);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 5,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  if (s.content != null) ...[
                    const SizedBox(height: 4),
                    Text(s.content!,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.inkSoft, height: 1.4)),
                  ],
                ],
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.inkSoft),
            onSelected: (v) {
              if (v == 'edit') _openEditor(existing: s);
              if (v == 'delete') _confirmDelete(s);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('수정')),
              PopupMenuItem(value: 'delete', child: Text('삭제')),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(ScheduleItem s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('일정 삭제'),
        content: Text("'${s.title}' 일정을 삭제할까요?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB02A2A)),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.repository.delete(s.id);
      _reload();
    } catch (e) {
      _toast(e.toString().replaceFirst('OrderException: ', ''), error: true);
    }
  }

  Future<void> _openEditor({ScheduleItem? existing}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScheduleEditor(
        repository: widget.repository,
        initialDate: existing?.date ?? _selected,
        existing: existing,
      ),
    );
    if (result == true) {
      if (existing != null) {
        // 수정 시 해당 날짜로 이동
      }
      _reload();
    }
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? const Color(0xFFB02A2A) : AppColors.mango800,
    ));
  }
}

/// 일정 추가/수정 바텀시트.
class _ScheduleEditor extends StatefulWidget {
  const _ScheduleEditor({
    required this.repository,
    required this.initialDate,
    this.existing,
  });

  final ScheduleRepository repository;
  final DateTime initialDate;
  final ScheduleItem? existing;

  @override
  State<_ScheduleEditor> createState() => _ScheduleEditorState();
}

class _ScheduleEditorState extends State<_ScheduleEditor> {
  late DateTime _date;
  late TextEditingController _title;
  late TextEditingController _content;
  late String _color;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _date = widget.existing?.date ?? widget.initialDate;
    _title = TextEditingController(text: widget.existing?.title ?? '');
    _content = TextEditingController(text: widget.existing?.content ?? '');
    _color = widget.existing?.color ?? 'mango';
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = DateTime(picked.year, picked.month, picked.day));
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('일정 제목을 입력해 주세요.'), behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _busy = true);
    try {
      final content = _content.text.trim();
      if (widget.existing == null) {
        await widget.repository.create(
            date: _fmt(_date), title: title, content: content, color: _color);
      } else {
        await widget.repository.update(widget.existing!.id,
            date: _fmt(_date), title: title, content: content, color: _color);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceFirst('OrderException: ', '')),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFB02A2A)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.line, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(widget.existing == null ? '일정 추가' : '일정 수정',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            // 날짜
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.mango700),
                  const SizedBox(width: 10),
                  Text(_fmt(_date),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  const Icon(Icons.expand_more, color: AppColors.inkSoft),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: '제목',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _content,
              maxLines: 3,
              maxLength: 2000,
              decoration: const InputDecoration(
                labelText: '내용 (선택)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 4),
            // 색상
            Wrap(
              spacing: 10,
              children: [
                for (final c in ScheduleColors.keys)
                  GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: ScheduleColors.of(c),
                        shape: BoxShape.circle,
                        border: _color == c
                            ? Border.all(color: AppColors.ink, width: 2.5)
                            : null,
                      ),
                      child: _color == c
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : _save,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                child: Text(_busy ? '저장 중…' : '저장'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
