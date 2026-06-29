import 'package:flutter/material.dart';

import '../../data/seller_repository.dart';
import '../../models/fulfillment.dart';
import '../../theme/app_colors.dart';

/// 가맹문의 처리 — 본사.
class InquiriesScreen extends StatefulWidget {
  const InquiriesScreen({super.key, required this.repository});
  final SellerRepository repository;

  @override
  State<InquiriesScreen> createState() => _InquiriesScreenState();
}

class _InquiriesScreenState extends State<InquiriesScreen> {
  late Future<({List<InquiryItem> inquiries, int newCount})> _future;
  String _status = 'all';

  static const _statuses = {'all': '전체', 'new': '신규', 'contacted': '상담중', 'done': '완료'};

  @override
  void initState() {
    super.initState();
    _future = widget.repository.inquiries();
  }

  void _select(String s) {
    setState(() {
      _status = s;
      _future = widget.repository.inquiries(status: s);
    });
  }

  void _reload() => setState(() { _future = widget.repository.inquiries(status: _status); });

  void _snack(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(m), behavior: SnackBarBehavior.floating, backgroundColor: AppColors.mango800));
    }
  }

  Future<void> _open(InquiryItem q) async {
    final detail = await widget.repository.inquiryDetail(q.id);
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(
        inquiry: detail,
        onStatus: (s) async {
          try {
            _snack(await widget.repository.updateInquiry(q.id, s));
            if (mounted) Navigator.pop(context);
            _reload();
          } catch (e) {
            _snack(e.toString());
          }
        },
        onDelete: () async {
          try {
            _snack(await widget.repository.deleteInquiry(q.id));
            if (mounted) Navigator.pop(context);
            _reload();
          } catch (e) {
            _snack(e.toString());
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('가맹문의')),
      body: Column(
        children: [
          SizedBox(
            height: 58,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final e in _statuses.entries)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: () => _select(e.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color: _status == e.key ? AppColors.accent : AppColors.surface,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: _status == e.key ? AppColors.accent : AppColors.line),
                        ),
                        child: Text(e.value,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _status == e.key ? Colors.white : AppColors.inkSoft)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<({List<InquiryItem> inquiries, int newCount})>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                }
                final list = snap.data?.inquiries ?? const [];
                if (list.isEmpty) {
                  return const Center(child: Text('문의가 없습니다', style: TextStyle(color: AppColors.inkSoft)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final q = list[i];
                    return GestureDetector(
                      onTap: () => _open(q),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: q.status == 'new' ? AppColors.mango300 : AppColors.line),
                        ),
                        child: Row(children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${q.name} · ${q.region ?? ''}',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Text('${q.phone ?? ''} · ${q.createdAt ?? ''}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                              ],
                            ),
                          ),
                          _StatusBadge(status: q.status, label: q.statusLabel),
                        ]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
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
    final (bg, fg) = switch (status) {
      'new' => (AppColors.mango100, AppColors.mango800),
      'contacted' => (const Color(0xFFE3F0FF), const Color(0xFF1B6CC4)),
      _ => (const Color(0xFFE9E9EC), const Color(0xFF44474F)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

class _DetailSheet extends StatelessWidget {
  const _DetailSheet({required this.inquiry, required this.onStatus, required this.onDelete});
  final InquiryItem inquiry;
  final ValueChanged<String> onStatus;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final q = inquiry;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(100)),
            ),
          ),
          const SizedBox(height: 16),
          Text(q.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          _row('연락처', q.phone ?? '-'),
          _row('지역', q.region ?? '-'),
          _row('이메일', q.email ?? '-'),
          _row('예산', q.budget ?? '-'),
          if (q.message != null && q.message!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
              child: Text(q.message!, style: const TextStyle(fontSize: 14, height: 1.5)),
            ),
          ],
          const SizedBox(height: 16),
          const Text('상태 변경', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
          const SizedBox(height: 8),
          Row(children: [
            for (final s in const [('new', '신규'), ('contacted', '상담중'), ('done', '완료')])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onStatus(s.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: q.status == s.$1 ? AppColors.accent : AppColors.surface,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: q.status == s.$1 ? AppColors.accent : AppColors.line),
                    ),
                    child: Text(s.$2,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: q.status == s.$1 ? Colors.white : AppColors.inkSoft)),
                  ),
                ),
              ),
            const Spacer(),
            IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, color: Color(0xFFB02A2A))),
          ]),
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          SizedBox(width: 56, child: Text(k, style: const TextStyle(fontSize: 13, color: AppColors.inkSoft))),
          Expanded(child: Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        ]),
      );
}
