import 'package:flutter/material.dart';

import '../../data/content_repository.dart';
import '../../theme/app_colors.dart';

/// 가맹(창업) 문의 — 소비자 공개 폼.
class FranchiseInquiryScreen extends StatefulWidget {
  const FranchiseInquiryScreen({super.key, required this.repository});
  final ContentRepository repository;

  @override
  State<FranchiseInquiryScreen> createState() => _FranchiseInquiryScreenState();
}

class _FranchiseInquiryScreenState extends State<FranchiseInquiryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _region = TextEditingController();
  final _budget = TextEditingController();
  final _message = TextEditingController();
  bool _agree = false;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _region.dispose();
    _budget.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agree) {
      _toast('개인정보 수집·이용에 동의해 주세요.', error: true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final msg = await widget.repository.submitFranchiseInquiry({
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        'region': _region.text.trim(),
        'budget': _budget.text.trim(),
        'message': _message.text.trim(),
        'agree_privacy': true,
      });
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('접수 완료'),
          content: Text(msg),
          actions: [
            FilledButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('확인')),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _toast(e.toString().replaceFirst('OrderException: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(m),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? const Color(0xFFB02A2A) : AppColors.mango800));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('창업 · 가맹 문의')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + MediaQuery.of(context).viewInsets.bottom),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🥭 리프렌즈와 함께하세요',
                      style: TextStyle(
                          color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  SizedBox(height: 6),
                  Text('아래 정보를 남겨주시면 담당자가 연락드립니다.',
                      style: TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _field(_name, '성함 *',
                validator: (v) => (v == null || v.trim().isEmpty) ? '성함을 입력해 주세요.' : null),
            _field(_phone, '연락처 *',
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.trim().isEmpty) ? '연락처를 입력해 주세요.' : null),
            _field(_email, '이메일', keyboardType: TextInputType.emailAddress),
            _field(_region, '희망 지역 (예: 서울 강서구)'),
            _field(_budget, '창업 예산 (예: 1억 내외)'),
            _field(_message, '문의 내용', lines: 4),
            const SizedBox(height: 4),
            CheckboxListTile(
              value: _agree,
              onChanged: (v) => setState(() => _agree = v ?? false),
              activeColor: AppColors.accent,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('개인정보 수집·이용에 동의합니다. *',
                  style: TextStyle(fontSize: 13)),
              subtitle: const Text('문의 응대 목적으로만 이용되며, 처리 후 파기됩니다.',
                  style: TextStyle(fontSize: 11, color: AppColors.inkSoft)),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                  : const Text('문의 접수하기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
          {int lines = 1,
          TextInputType? keyboardType,
          String? Function(String?)? validator}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          maxLines: lines,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: AppColors.surface,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.6),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );
}
