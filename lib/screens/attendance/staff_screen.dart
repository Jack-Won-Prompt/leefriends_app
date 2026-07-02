import 'package:flutter/material.dart';

import '../../data/attendance_repository.dart';
import '../../models/attendance.dart';
import '../../models/store_ops.dart' show won;
import '../../theme/app_colors.dart';

/// 직원 관리 — 정직원/아르바이트 계정 등록·수정·삭제·시급 설정. 정직원 전용.
class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key, required this.repository});

  final AttendanceRepository repository;

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  Future<List<StaffMember>>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => setState(() { _future = widget.repository.staff(); });

  String _msg(Object e) => e.toString().replaceFirst('OrderException: ', '');
  void _toast(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m),
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? const Color(0xFFB02A2A) : AppColors.mango800,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = 24 + MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('직원 관리')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('직원 등록'),
      ),
      body: FutureBuilder<List<StaffMember>>(
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
                      textAlign: TextAlign.center, style: const TextStyle(color: AppColors.inkSoft)),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: _reload, child: const Text('다시 시도')),
                ]),
              ),
            );
          }
          final list = snap.data ?? const [];
          return RefreshIndicator(
            color: AppColors.accent,
            onRefresh: () async => _reload(),
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 60),
              children: [
                if (list.isEmpty)
                  const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Center(child: Text('등록된 직원이 없습니다', style: TextStyle(color: AppColors.inkSoft))))
                else
                  for (final s in list) _tile(s),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _tile(StaffMember s) {
    final partColor = s.isPartTime ? AppColors.mango700 : const Color(0xFF1B6CC4);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.mango50,
          child: Text(s.name.isNotEmpty ? s.name.characters.first : '?',
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.mango700)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                child: Text(s.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                    color: partColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100)),
                child: Text(s.employmentLabel,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: partColor)),
              ),
              if (s.isAdmin) ...[
                const SizedBox(width: 4),
                const Icon(Icons.shield_outlined, size: 14, color: AppColors.inkSoft),
              ],
            ]),
            const SizedBox(height: 3),
            Text(s.email + (s.phone != null ? ' · ${s.phone}' : ''),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
            if (s.isPartTime)
              Text('시급 ${won(s.hourlyWage)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.mango700, fontWeight: FontWeight.w700)),
          ]),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.inkSoft),
          onSelected: (v) {
            if (v == 'edit') _openEditor(existing: s);
            if (v == 'delete') _confirmDelete(s);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('수정')),
            if (!s.isSelf) const PopupMenuItem(value: 'delete', child: Text('삭제')),
          ],
        ),
      ]),
    );
  }

  Future<void> _confirmDelete(StaffMember s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('직원 삭제'),
        content: Text("'${s.name}' 계정을 삭제할까요?"),
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
      _toast(await widget.repository.deleteStaff(s.id));
      _reload();
    } catch (e) {
      _toast(_msg(e), error: true);
    }
  }

  Future<void> _openEditor({StaffMember? existing}) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StaffEditor(repository: widget.repository, existing: existing),
    );
    if (ok == true) _reload();
  }
}

class _StaffEditor extends StatefulWidget {
  const _StaffEditor({required this.repository, this.existing});
  final AttendanceRepository repository;
  final StaffMember? existing;

  @override
  State<_StaffEditor> createState() => _StaffEditorState();
}

class _StaffEditorState extends State<_StaffEditor> {
  late TextEditingController _name;
  late TextEditingController _email;
  late TextEditingController _phone;
  late TextEditingController _password;
  late TextEditingController _wage;
  String _type = 'regular';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _email = TextEditingController(text: e?.email ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _password = TextEditingController();
    _wage = TextEditingController(text: (e?.isPartTime ?? false) ? '${e!.hourlyWage}' : '');
    _type = e?.employmentType ?? 'regular';
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _wage.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    if (name.isEmpty || email.isEmpty) {
      _toast('이름과 이메일을 입력해 주세요.', error: true);
      return;
    }
    if (widget.existing == null && _password.text.trim().isEmpty) {
      _toast('임시 비밀번호를 입력해 주세요.', error: true);
      return;
    }
    if (_type == 'part_time' && (int.tryParse(_wage.text.trim()) ?? 0) <= 0) {
      _toast('아르바이트는 시급을 입력해 주세요.', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final wage = int.tryParse(_wage.text.trim());
      String msg;
      if (widget.existing == null) {
        msg = await widget.repository.createStaff(
          name: name, email: email, password: _password.text.trim(),
          phone: _phone.text.trim(), employmentType: _type, hourlyWage: wage,
        );
      } else {
        msg = await widget.repository.updateStaff(
          widget.existing!.id,
          name: name, email: email, password: _password.text.trim(),
          phone: _phone.text.trim(), employmentType: _type, hourlyWage: wage,
        );
      }
      if (mounted) {
        _toast(msg);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        _toast(e.toString().replaceFirst('OrderException: ', ''), error: true);
      }
    }
  }

  void _toast(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m),
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? const Color(0xFFB02A2A) : AppColors.mango800,
    ));
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
            Center(
                child: Text(widget.existing == null ? '직원 등록' : '직원 수정',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
            const SizedBox(height: 16),
            // 고용형태
            Row(children: [
              _typeBtn('regular', '정직원'),
              const SizedBox(width: 10),
              _typeBtn('part_time', '아르바이트'),
            ]),
            const SizedBox(height: 12),
            _field(_name, '이름'),
            const SizedBox(height: 10),
            _field(_email, '이메일', keyboard: TextInputType.emailAddress),
            const SizedBox(height: 10),
            _field(_phone, '전화번호 (선택)', keyboard: TextInputType.phone),
            const SizedBox(height: 10),
            _field(_password, widget.existing == null ? '임시 비밀번호' : '비밀번호 재설정 (선택)',
                obscure: true),
            if (_type == 'part_time') ...[
              const SizedBox(height: 10),
              _field(_wage, '시급 (원)', keyboard: TextInputType.number),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : _save,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                child: Text(_busy ? '저장 중…' : '저장'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _typeBtn(String t, String label) {
    final active = _type == t;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = t),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.accent : AppColors.cream,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? AppColors.accent : AppColors.line),
          ),
          child: Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: active ? Colors.white : AppColors.inkSoft)),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
          {bool obscure = false, TextInputType? keyboard}) =>
      TextField(
        controller: c,
        obscureText: obscure,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      );
}
