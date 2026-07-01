import 'package:flutter/material.dart';

import '../../data/attendance_repository.dart';
import '../../models/attendance.dart';
import '../../models/store_ops.dart' show won;
import '../../theme/app_colors.dart';

/// 근태관리 — 아르바이트(출퇴근·휴무) / 정직원(승인·급여). isPartTime 로 분기.
/// 홈 모드(아르바이트 전용): onLogout 등을 주면 AppBar에 인사·알림·로그아웃을 표시하고
/// 뒤로가기를 숨긴다(아르바이트는 이 화면이 앱의 전부).
class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({
    super.key,
    required this.repository,
    required this.isPartTime,
    this.homeMode = false,
    this.userName,
    this.unread = 0,
    this.onLogout,
    this.onNotifications,
  });

  final AttendanceRepository repository;
  final bool isPartTime;
  final bool homeMode;
  final String? userName;
  final int unread;
  final VoidCallback? onLogout;
  final VoidCallback? onNotifications;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          automaticallyImplyLeading: !homeMode,
          title: Text(homeMode ? '${userName ?? ''} · 근태' : '근태관리'),
          actions: homeMode
              ? [
                  if (onNotifications != null)
                    Stack(alignment: Alignment.center, children: [
                      IconButton(
                          onPressed: onNotifications,
                          icon: const Icon(Icons.notifications_none_rounded)),
                      if (unread > 0)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            constraints: const BoxConstraints(minWidth: 16),
                            decoration: BoxDecoration(
                                color: AppColors.accent, borderRadius: BorderRadius.circular(100)),
                            child: Text(unread > 99 ? '99+' : '$unread',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                          ),
                        ),
                    ]),
                  if (onLogout != null)
                    IconButton(onPressed: onLogout, icon: const Icon(Icons.logout_rounded)),
                  const SizedBox(width: 4),
                ]
              : null,
          bottom: TabBar(
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.inkSoft,
            indicatorColor: AppColors.accent,
            tabs: isPartTime
                ? const [Tab(text: '출퇴근'), Tab(text: '휴무')]
                : const [Tab(text: '승인'), Tab(text: '급여')],
          ),
        ),
        body: TabBarView(
          children: isPartTime
              ? [
                  _ClockTab(repository: repository),
                  _LeaveTab(repository: repository),
                ]
              : [
                  _ApprovalsTab(repository: repository),
                  _WageTab(repository: repository),
                ],
        ),
      ),
    );
  }
}

String _msg(Object e) => e.toString().replaceFirst('OrderException: ', '');

void _toast(BuildContext c, String m, {bool error = false}) {
  ScaffoldMessenger.of(c).showSnackBar(SnackBar(
    content: Text(m),
    behavior: SnackBarBehavior.floating,
    backgroundColor: error ? const Color(0xFFB02A2A) : AppColors.mango800,
  ));
}

Color _statusColor(String s) => switch (s) {
      'approved' => const Color(0xFF1E8E4E),
      'rejected' => const Color(0xFFB02A2A),
      _ => AppColors.mango700,
    };

// ─────────────────────────── 아르바이트: 출퇴근 ───────────────────────────
class _ClockTab extends StatefulWidget {
  const _ClockTab({required this.repository});
  final AttendanceRepository repository;
  @override
  State<_ClockTab> createState() => _ClockTabState();
}

class _ClockTabState extends State<_ClockTab> {
  Future<AttendanceIndex>? _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => setState(() { _future = widget.repository.myAttendance(); });

  Future<void> _do(Future<String> Function() action) async {
    setState(() => _busy = true);
    try {
      final m = await action();
      if (!mounted) return;
      _toast(context, m);
      _reload();
    } catch (e) {
      if (mounted) _toast(context, _msg(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = 24 + MediaQuery.of(context).padding.bottom;
    return FutureBuilder<AttendanceIndex>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accent));
        }
        if (snap.hasError) {
          return _ErrorView(msg: _msg(snap.error!), onRetry: _reload);
        }
        final d = snap.data!;
        return RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () async => _reload(),
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, bottom),
            children: [
              _clockCard(d.open),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('내 출퇴근 기록', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                TextButton.icon(
                  onPressed: _busy ? null : () => _openEditor(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('수동 등록'),
                ),
              ]),
              const SizedBox(height: 4),
              if (d.records.isEmpty)
                const Padding(
                    padding: EdgeInsets.only(top: 30),
                    child: Center(child: Text('기록이 없습니다', style: TextStyle(color: AppColors.inkSoft))))
              else
                for (final r in d.records) _recordTile(r),
            ],
          ),
        );
      },
    );
  }

  Widget _clockCard(AttendanceRecord? open) {
    final working = open != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: working
              ? [const Color(0xFF1E8E4E), const Color(0xFF167A41)]
              : [AppColors.mango600, AppColors.mango700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: [
        Text(working ? '근무 중' : '출근 전',
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(working ? '출근 ${open.clockIn ?? ''}' : '오늘도 화이팅!',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _busy
                ? null
                : () => _do(working ? widget.repository.clockOut : widget.repository.clockIn),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: working ? const Color(0xFF167A41) : AppColors.mango700,
              minimumSize: const Size.fromHeight(52),
            ),
            child: Text(working ? '퇴근하기' : '출근하기',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ),
        ),
      ]),
    );
  }

  Widget _recordTile(AttendanceRecord r) {
    return Container(
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
            Text('${r.workDate ?? ''}  ${r.clockIn ?? '--:--'} ~ ${r.clockOut ?? '근무중'}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text('${r.hours}시간',
                style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: _statusColor(r.status).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(100)),
          child: Text(r.statusLabel,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800, color: _statusColor(r.status))),
        ),
        if (!r.isApproved)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18, color: AppColors.inkSoft),
            onSelected: (v) {
              if (v == 'edit') _openEditor(existing: r);
              if (v == 'delete') _do(() => widget.repository.deleteOwn(r.id));
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('수정')),
              PopupMenuItem(value: 'delete', child: Text('삭제')),
            ],
          ),
      ]),
    );
  }

  Future<void> _openEditor({AttendanceRecord? existing}) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AttendanceEditor(
        title: existing == null ? '출퇴근 수동 등록' : '출퇴근 수정',
        initialDate: existing?.workDate,
        initialIn: existing?.clockIn,
        initialOut: existing?.clockOut,
        onSubmit: (date, cin, cout) => existing == null
            ? widget.repository.addRecord(workDate: date, clockIn: cin, clockOut: cout)
            : widget.repository.updateOwn(existing.id, workDate: date, clockIn: cin, clockOut: cout),
      ),
    );
    if (ok == true) _reload();
  }
}

// ─────────────────────────── 아르바이트: 휴무 ───────────────────────────
class _LeaveTab extends StatefulWidget {
  const _LeaveTab({required this.repository});
  final AttendanceRepository repository;
  @override
  State<_LeaveTab> createState() => _LeaveTabState();
}

class _LeaveTabState extends State<_LeaveTab> {
  Future<({bool isPartTime, List<LeaveRecord> leaves})>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => setState(() { _future = widget.repository.myLeaves(); });

  @override
  Widget build(BuildContext context) {
    final bottom = 24 + MediaQuery.of(context).padding.bottom;
    return FutureBuilder<({bool isPartTime, List<LeaveRecord> leaves})>(
      future: _future,
      builder: (context, snap) {
        return RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () async => _reload(),
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, bottom),
            children: [
              // 상단 휴무 신청 버튼 (FAB 대신 — 하단 시스템바 가림 방지)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _requestLeave,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  icon: const Icon(Icons.add),
                  label: const Text('휴무 신청'),
                ),
              ),
              const SizedBox(height: 14),
              if (snap.connectionState == ConnectionState.waiting && !snap.hasData)
                const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Center(child: CircularProgressIndicator(color: AppColors.accent)))
              else if (snap.hasError)
                _ErrorView(msg: _msg(snap.error!), onRetry: _reload)
              else if ((snap.data?.leaves ?? const []).isEmpty)
                const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: Text('신청한 휴무가 없습니다', style: TextStyle(color: AppColors.inkSoft))))
              else
                for (final l in snap.data!.leaves) _leaveTile(l),
            ],
          ),
        );
      },
    );
  }

  Widget _leaveTile(LeaveRecord l) => Container(
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
              Text(l.leaveDate ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              if (l.reason != null && l.reason!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(l.reason!, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
              ],
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: _statusColor(l.status).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(100)),
            child: Text(l.statusLabel,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _statusColor(l.status))),
          ),
          if (!l.isApproved)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.inkSoft),
              onPressed: () async {
                try {
                  final m = await widget.repository.cancelLeave(l.id);
                  if (!mounted) return;
                  _toast(context, m);
                  _reload();
                } catch (e) {
                  if (mounted) _toast(context, _msg(e), error: true);
                }
              },
            ),
        ]),
      );

  Future<void> _requestLeave() async {
    final result = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _LeaveEditor(),
    );
    if (result == null) return;
    try {
      final m = await widget.repository.requestLeave(result.$1, result.$2);
      if (mounted) {
        _toast(context, m);
        _reload();
      }
    } catch (e) {
      if (mounted) _toast(context, _msg(e), error: true);
    }
  }
}

/// 휴무 신청 바텀시트 — (yyyy-MM-dd, 사유) 반환.
class _LeaveEditor extends StatefulWidget {
  const _LeaveEditor();
  @override
  State<_LeaveEditor> createState() => _LeaveEditorState();
}

class _LeaveEditorState extends State<_LeaveEditor> {
  DateTime? _date;
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    final safe = MediaQuery.of(context).viewPadding.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: Container(
        decoration: const BoxDecoration(
            color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + safe),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Center(child: Text('휴무 신청', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final p = await showDatePicker(
                    context: context,
                    initialDate: _date ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100));
                if (p != null) setState(() => _date = p);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
                child: Row(children: [
                  const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.mango700),
                  const SizedBox(width: 10),
                  Text(_date == null ? '휴무 날짜 선택' : _fmt(_date!),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reason,
              maxLength: 200,
              decoration: const InputDecoration(
                  labelText: '사유 (선택)', border: OutlineInputBorder(), counterText: ''),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (_date == null) {
                    _toast(context, '휴무 날짜를 선택해 주세요.', error: true);
                    return;
                  }
                  Navigator.pop(context, (_fmt(_date!), _reason.text.trim()));
                },
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                child: const Text('신청'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────── 정직원: 승인 ───────────────────────────
class _ApprovalsTab extends StatefulWidget {
  const _ApprovalsTab({required this.repository});
  final AttendanceRepository repository;
  @override
  State<_ApprovalsTab> createState() => _ApprovalsTabState();
}

class _ApprovalsTabState extends State<_ApprovalsTab> {
  Future<ApprovalsData>? _future;
  String _status = 'pending';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => setState(() { _future = widget.repository.approvals(status: _status); });

  Future<void> _do(Future<String> Function() action) async {
    setState(() => _busy = true);
    try {
      final m = await action();
      if (!mounted) return;
      _toast(context, m);
      _reload();
    } catch (e) {
      if (mounted) _toast(context, _msg(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = 24 + MediaQuery.of(context).padding.bottom;
    return FutureBuilder<ApprovalsData>(
      future: _future,
      builder: (context, snap) {
        return RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () async => _reload(),
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 12, 16, bottom),
            children: [
              _statusBar(),
              const SizedBox(height: 12),
              if (snap.connectionState == ConnectionState.waiting && !snap.hasData)
                const Padding(padding: EdgeInsets.only(top: 60), child: Center(child: CircularProgressIndicator(color: AppColors.accent)))
              else if (snap.hasError)
                _ErrorView(msg: _msg(snap.error!), onRetry: _reload)
              else if (snap.hasData) ...[
                _attSection(snap.data!.attendances),
                const SizedBox(height: 16),
                _leaveSection(snap.data!.leaves),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _statusBar() => Row(children: [
        for (final s in const [('pending', '대기'), ('approved', '승인'), ('rejected', '반려'), ('all', '전체')])
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _status = s.$1);
                _reload();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _status == s.$1 ? AppColors.accent : AppColors.surface,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: _status == s.$1 ? AppColors.accent : AppColors.line),
                ),
                child: Text(s.$2,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _status == s.$1 ? Colors.white : AppColors.inkSoft)),
              ),
            ),
          ),
      ]);

  Widget _attSection(List<AttendanceRecord> atts) {
    final bulkable = atts.where((a) => a.status == 'pending' && a.clockOut != null).map((a) => a.id).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('출퇴근', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        if (bulkable.isNotEmpty)
          TextButton.icon(
            onPressed: _busy ? null : () => _do(() => widget.repository.bulkApprove(bulkable)),
            icon: const Icon(Icons.done_all, size: 16),
            label: Text('일괄 승인 (${bulkable.length})'),
          ),
      ]),
      const SizedBox(height: 4),
      if (atts.isEmpty)
        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('내역 없음', style: TextStyle(color: AppColors.inkSoft)))
      else
        for (final a in atts) _attTile(a),
    ]);
  }

  Widget _attTile(AttendanceRecord a) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text('${a.user?.name ?? ''} · ${a.workDate ?? ''}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            ),
            Text(a.statusLabel,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _statusColor(a.status))),
          ]),
          const SizedBox(height: 4),
          Text('${a.clockIn ?? '--:--'} ~ ${a.clockOut ?? '근무중'} · ${a.hours}시간',
              style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
          if (a.status == 'pending') ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy || a.clockOut == null ? null : () => _do(() => widget.repository.approve(a.id)),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E8E4E),
                      side: const BorderSide(color: Color(0xFFA7DCB9))),
                  child: Text(a.clockOut == null ? '퇴근 미기록' : '승인'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : () => _do(() => widget.repository.reject(a.id)),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB02A2A),
                      side: const BorderSide(color: Color(0xFFE9B0B0))),
                  child: const Text('반려'),
                ),
              ),
            ]),
          ],
        ]),
      );

  Widget _leaveSection(List<LeaveRecord> leaves) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('휴무', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          if (leaves.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('내역 없음', style: TextStyle(color: AppColors.inkSoft)))
          else
            for (final l in leaves) _leaveTile(l),
        ],
      );

  Widget _leaveTile(LeaveRecord l) => Container(
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
              Text('${l.user?.name ?? ''} · ${l.leaveDate ?? ''}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              if (l.reason != null && l.reason!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(l.reason!, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
              ],
            ]),
          ),
          if (l.status == 'pending') ...[
            IconButton(
              icon: const Icon(Icons.check_circle_outline, color: Color(0xFF1E8E4E)),
              onPressed: _busy ? null : () => _do(() => widget.repository.approveLeave(l.id)),
            ),
            IconButton(
              icon: const Icon(Icons.cancel_outlined, color: Color(0xFFB02A2A)),
              onPressed: _busy ? null : () => _do(() => widget.repository.rejectLeave(l.id)),
            ),
          ] else
            Text(l.statusLabel,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _statusColor(l.status))),
        ]),
      );
}

// ─────────────────────────── 정직원: 급여 ───────────────────────────
class _WageTab extends StatefulWidget {
  const _WageTab({required this.repository});
  final AttendanceRepository repository;
  @override
  State<_WageTab> createState() => _WageTabState();
}

class _WageTabState extends State<_WageTab> {
  Future<WageIndex>? _future;
  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _to = DateTime.now();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => setState(() { _future = widget.repository.wages(from: _fmt(_from), to: _fmt(_to)); });

  Future<void> _pick(bool from) async {
    final p = await showDatePicker(
        context: context,
        initialDate: from ? _from : _to,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100));
    if (p != null) {
      setState(() => from ? _from = p : _to = p);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = 24 + MediaQuery.of(context).padding.bottom;
    return FutureBuilder<WageIndex>(
      future: _future,
      builder: (context, snap) {
        return RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () async => _reload(),
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 14, 16, bottom),
            children: [
              Row(children: [
                Expanded(child: _dateField('시작', _from, () => _pick(true))),
                const SizedBox(width: 10),
                Expanded(child: _dateField('종료', _to, () => _pick(false))),
              ]),
              const SizedBox(height: 14),
              if (snap.connectionState == ConnectionState.waiting && !snap.hasData)
                const Padding(padding: EdgeInsets.only(top: 50), child: Center(child: CircularProgressIndicator(color: AppColors.accent)))
              else if (snap.hasError)
                _ErrorView(msg: _msg(snap.error!), onRetry: _reload)
              else if (snap.hasData) ...[
                _totalCard(snap.data!.grandAmount),
                const SizedBox(height: 12),
                if (snap.data!.rows.isEmpty)
                  const Padding(padding: EdgeInsets.only(top: 20), child: Center(child: Text('아르바이트가 없습니다', style: TextStyle(color: AppColors.inkSoft))))
                else
                  for (final r in snap.data!.rows) _wageTile(r),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _dateField(String label, DateTime d, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.line)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
            const SizedBox(height: 3),
            Text(_fmt(d), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ]),
        ),
      );

  Widget _totalCard(int grand) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AppColors.mango600, AppColors.mango700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('기간 급여 합계',
              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(won(grand),
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
        ]),
      );

  Widget _wageTile(WageRow r) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: r.paid ? const Color(0xFFA7DCB9) : AppColors.line),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text('${r.days}일 · ${r.hours}시간 · 시급 ${won(r.hourlyWage)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(won(r.amount),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.accent)),
            const SizedBox(height: 4),
            if (r.paid)
              TextButton(
                onPressed: _busy ? null : () => _unpay(r),
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero, minimumSize: const Size(50, 28)),
                child: Text('입금완료${r.paidAt != null ? ' ${r.paidAt}' : ''} · 취소',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF1E8E4E))),
              )
            else
              FilledButton(
                onPressed: _busy || r.amount <= 0 ? null : () => _pay(r),
                style: FilledButton.styleFrom(
                    minimumSize: const Size(64, 34), padding: const EdgeInsets.symmetric(horizontal: 12)),
                child: const Text('입금'),
              ),
          ]),
        ]),
      );

  Future<void> _pay(WageRow r) async {
    setState(() => _busy = true);
    try {
      final m = await widget.repository.payWage(
          userId: r.userId, from: _fmt(_from), to: _fmt(_to), hours: r.hours, amount: r.amount);
      if (!mounted) return;
      _toast(context, m);
      _reload();
    } catch (e) {
      if (mounted) _toast(context, _msg(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unpay(WageRow r) async {
    if (r.settlementId == null) return;
    setState(() => _busy = true);
    try {
      final m = await widget.repository.unpayWage(r.settlementId!);
      if (!mounted) return;
      _toast(context, m);
      _reload();
    } catch (e) {
      if (mounted) _toast(context, _msg(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

// ─────────────────────────── 공통 ───────────────────────────
String _fmt(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.msg, required this.onRetry});
  final String msg;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 50),
        child: Column(children: [
          const Icon(Icons.error_outline, color: AppColors.inkSoft, size: 40),
          const SizedBox(height: 10),
          Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.inkSoft)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
        ]),
      );
}

/// 출퇴근 입력/수정 바텀시트 (날짜 + 출근/퇴근 시각).
class _AttendanceEditor extends StatefulWidget {
  const _AttendanceEditor({
    required this.title,
    required this.onSubmit,
    this.initialDate,
    this.initialIn,
    this.initialOut,
  });

  final String title;
  final String? initialDate;
  final String? initialIn;
  final String? initialOut;
  final Future<String> Function(String date, String clockIn, String? clockOut) onSubmit;

  @override
  State<_AttendanceEditor> createState() => _AttendanceEditorState();
}

class _AttendanceEditorState extends State<_AttendanceEditor> {
  late DateTime _date;
  TimeOfDay? _in;
  TimeOfDay? _out;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _date = DateTime.tryParse(widget.initialDate ?? '') ?? DateTime.now();
    _in = _parse(widget.initialIn);
    _out = _parse(widget.initialOut);
  }

  TimeOfDay? _parse(String? s) {
    if (s == null || !s.contains(':')) return null;
    final p = s.split(':');
    return TimeOfDay(hour: int.tryParse(p[0]) ?? 0, minute: int.tryParse(p[1]) ?? 0);
  }

  String _t(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(bool isIn) async {
    final p = await showTimePicker(
        context: context, initialTime: (isIn ? _in : _out) ?? TimeOfDay.now());
    if (p != null) setState(() => isIn ? _in = p : _out = p);
  }

  Future<void> _submit() async {
    if (_in == null) {
      _toast(context, '출근 시간을 선택해 주세요.', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.onSubmit(_fmt(_date), _t(_in!), _out != null ? _t(_out!) : null);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        _toast(context, _msg(e), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    final safe = MediaQuery.of(context).viewPadding.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: Container(
        decoration: const BoxDecoration(
            color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + safe),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              final p = await showDatePicker(
                  context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2100));
              if (p != null) setState(() => _date = p);
            },
            child: _box(Icons.calendar_today_outlined, _fmt(_date)),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: InkWell(onTap: () => _pickTime(true), child: _box(Icons.login, _in == null ? '출근' : _t(_in!)))),
            const SizedBox(width: 10),
            Expanded(child: InkWell(onTap: () => _pickTime(false), child: _box(Icons.logout, _out == null ? '퇴근(선택)' : _t(_out!)))),
          ]),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: Text(_busy ? '저장 중…' : '저장'),
            ),
          ),
        ]),
        ),
      ),
    );
  }

  Widget _box(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
        child: Row(children: [
          Icon(icon, size: 18, color: AppColors.mango700),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ]),
      );
}
