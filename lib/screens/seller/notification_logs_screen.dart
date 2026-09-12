import 'package:flutter/material.dart';

import '../../data/seller_repository.dart';
import '../../models/notification_log.dart';
import '../../theme/app_colors.dart';
import '../../widgets/paged_list_view.dart';

/// 본사 — FCM/인앱 알림 이력. 웹 포털 «FCM 알림 이력» 과 같은 조건(구분·매장·유형·기간·검색)과 요약.
class NotificationLogsScreen extends StatefulWidget {
  const NotificationLogsScreen({super.key, required this.repository});
  final SellerRepository repository;

  @override
  State<NotificationLogsScreen> createState() => _NotificationLogsScreenState();
}

class _NotificationLogsScreenState extends State<NotificationLogsScreen> {
  String _role = 'all'; // all | hq | store
  String? _storeId;
  String? _type;
  late DateTimeRange _range;
  String _q = '';
  final _search = TextEditingController();

  // 첫 페이지 응답에서 채움
  NotificationLogPage? _summary;
  List<NotificationLogOption> _stores = const [];
  List<NotificationLogOption> _types = const [];

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _range = DateTimeRange(start: today.subtract(const Duration(days: 7)), end: today); // 기본 최근 7일
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  static String _md(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  String get _filterKey => '$_role|$_storeId|$_type|${_ymd(_range.start)}|${_ymd(_range.end)}|$_q';

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _range,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateUtils.dateOnly(DateTime.now()),
    );
    if (picked != null) setState(() => _range = picked);
  }

  void _reset() {
    final today = DateUtils.dateOnly(DateTime.now());
    _search.clear();
    setState(() {
      _role = 'all';
      _storeId = null;
      _type = null;
      _q = '';
      _range = DateTimeRange(start: today.subtract(const Duration(days: 7)), end: today);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('FCM 알림 이력'),
        actions: [
          TextButton(onPressed: _reset, child: const Text('초기화')),
        ],
      ),
      body: Column(
        children: [
          _filters(),
          _summaryRow(),
          Expanded(
            child: PagedListView<NotificationLog>(
              key: ValueKey(_filterKey),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              emptyText: '해당 조건의 알림 내역이 없습니다',
              emptyIcon: Icons.notifications_off_outlined,
              fetch: (page) async {
                final r = await widget.repository.notificationLogs(
                  role: _role,
                  storeId: _storeId,
                  type: _type,
                  from: _ymd(_range.start),
                  to: _ymd(_range.end),
                  q: _q,
                  page: page,
                );
                if (page == 1) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() {
                      _summary = r;
                      if (_stores.isEmpty) _stores = r.stores;
                      if (_types.isEmpty) _types = r.types;
                    });
                  });
                }
                return r.page;
              },
              itemBuilder: (context, log) => _LogTile(log: log),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filters() {
    Widget roleChip(String key, String label) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: ChoiceChip(
            label: Text(label),
            selected: _role == key,
            onSelected: (_) => setState(() {
              _role = key;
              if (key == 'hq') _storeId = null; // 본사 수신분은 매장 구분 없음
            }),
          ),
        );

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            roleChip('all', '전체'),
            roleChip('hq', '본사'),
            roleChip('store', '매장'),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _pickRange,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.mango700,
                side: const BorderSide(color: AppColors.mango300),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              icon: const Icon(Icons.event_outlined, size: 16),
              label: Text('${_md(_range.start)} ~ ${_md(_range.end)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            if (_role != 'hq') ...[
              Expanded(
                child: _dropdown(
                  hint: '전체 매장',
                  value: _storeId,
                  options: _stores,
                  onChanged: (v) => setState(() => _storeId = v),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: _dropdown(
                hint: '전체 유형',
                value: _type,
                options: _types,
                onChanged: (v) => setState(() => _type = v),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onSubmitted: (v) => setState(() => _q = v.trim()),
            style: const TextStyle(fontSize: 14, color: AppColors.ink),
            decoration: InputDecoration(
              isDense: true,
              hintText: '제목·내용 검색',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _q.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _search.clear();
                        setState(() => _q = '');
                      },
                    ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  /// 매장·유형 드롭다운. 흰 배경에 글자색을 명시(흰 글자 겹침 방지).
  Widget _dropdown({
    required String hint,
    required String? value,
    required List<NotificationLogOption> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: options.any((o) => o.key == value) ? value : null,
          isExpanded: true,
          dropdownColor: AppColors.surface,
          style: const TextStyle(fontSize: 13, color: AppColors.ink),
          hint: Text(hint, style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
          items: [
            DropdownMenuItem<String?>(
                value: null,
                child: Text(hint, style: const TextStyle(fontSize: 13, color: AppColors.ink))),
            for (final o in options)
              DropdownMenuItem<String?>(
                value: o.key,
                child: Text(o.label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: AppColors.ink)),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _summaryRow() {
    final s = _summary;
    Widget pill(String label, int? n, Color color) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
              const SizedBox(height: 2),
              Text(n == null ? '–' : '$n건',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
            ]),
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(children: [
        pill('전체 알림', s?.total, AppColors.ink),
        const SizedBox(width: 8),
        pill('본사 수신', s?.hqCount, const Color(0xFF1B6CC4)),
        const SizedBox(width: 8),
        pill('매장 수신', s?.storeCount, const Color(0xFF1E8E4E)),
      ]),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log});
  final NotificationLog log;

  @override
  Widget build(BuildContext context) {
    final roleColor = log.isHq ? const Color(0xFF1B6CC4) : const Color(0xFF1E8E4E);
    Widget chip(String text, Color fg, Color bg) => Container(
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
          child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: fg)),
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            chip(log.isHq ? '본사' : '매장', roleColor, roleColor.withValues(alpha: 0.12)),
            chip(log.typeLabel, AppColors.inkSoft, AppColors.cream),
            const Spacer(),
            Text(log.isRead ? '읽음' : '미읽음',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: log.isRead ? const Color(0xFF1E8E4E) : AppColors.inkSoft)),
          ]),
          const SizedBox(height: 8),
          Text(log.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          if ((log.body ?? '').isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(log.body!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: AppColors.inkSoft, height: 1.4)),
          ],
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.person_outline, size: 14, color: AppColors.inkSoft),
            const SizedBox(width: 3),
            Expanded(
              child: Text(
                  [log.userName ?? '', if (!log.isHq && (log.storeName ?? '').isNotEmpty) log.storeName!]
                      .where((s) => s.isNotEmpty)
                      .join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
            ),
            if (log.createdAt != null)
              Text(log.createdAt!, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
          ]),
        ],
      ),
    );
  }
}
