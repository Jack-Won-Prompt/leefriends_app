import 'package:flutter/material.dart';

import '../../data/seller_repository.dart';
import '../../models/fulfillment.dart';
import '../../theme/app_colors.dart';

/// 포털 공지 관리 — 본사 (발송/삭제). 발송 시 대상 전원에게 알림+FCM.
class NoticesManageScreen extends StatefulWidget {
  const NoticesManageScreen({super.key, required this.repository});
  final SellerRepository repository;

  @override
  State<NoticesManageScreen> createState() => _NoticesManageScreenState();
}

class _NoticesManageScreenState extends State<NoticesManageScreen> {
  late Future<({List<PortalNoticeItem> notices, List<({String key, String label})> audiences})> _future;
  List<({String key, String label})> _audiences = const [];

  @override
  void initState() {
    super.initState();
    _future = widget.repository.portalNotices();
  }

  void _reload() => setState(() { _future = widget.repository.portalNotices(); });

  void _snack(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(m), behavior: SnackBarBehavior.floating, backgroundColor: AppColors.mango800));
    }
  }

  Future<void> _compose() async {
    final title = TextEditingController();
    final content = TextEditingController();
    String audience = 'all';
    bool pinned = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('공지 발송'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: title, decoration: const InputDecoration(labelText: '제목')),
              const SizedBox(height: 8),
              TextField(controller: content, maxLines: 4, decoration: const InputDecoration(labelText: '내용')),
              const SizedBox(height: 12),
              Row(children: [
                const Text('대상', style: TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                const SizedBox(width: 10),
                for (final a in (_audiences.isEmpty
                    ? const [(key: 'all', label: '전체'), (key: 'store', label: '매장'), (key: 'supplier', label: '공급처')]
                    : _audiences))
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setLocal(() => audience = a.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: audience == a.key ? AppColors.accent : AppColors.cream,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: audience == a.key ? AppColors.accent : AppColors.line),
                        ),
                        child: Text(a.label,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: audience == a.key ? Colors.white : AppColors.inkSoft)),
                      ),
                    ),
                  ),
              ]),
              SwitchListTile(
                value: pinned,
                onChanged: (v) => setLocal(() => pinned = v),
                activeThumbColor: AppColors.accent,
                contentPadding: EdgeInsets.zero,
                title: const Text('상단 고정', style: TextStyle(fontSize: 14)),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('발송')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    if (title.text.trim().isEmpty || content.text.trim().isEmpty) {
      _snack('제목과 내용을 입력해 주세요.');
      return;
    }
    try {
      final msg = await widget.repository.createNotice({
        'title': title.text.trim(),
        'content': content.text.trim(),
        'audience': audience,
        'is_pinned': pinned,
      });
      _snack(msg);
      _reload();
    } catch (e) {
      _snack(e.toString());
    }
  }

  Future<void> _delete(PortalNoticeItem n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제'),
        content: const Text('이 공지를 삭제할까요?'),
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
      _snack(await widget.repository.deleteNotice(n.id));
      _reload();
    } catch (e) {
      _snack(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('공지 관리')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        onPressed: _compose,
        icon: const Icon(Icons.campaign_outlined),
        label: const Text('공지 발송', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: FutureBuilder<({List<PortalNoticeItem> notices, List<({String key, String label})> audiences})>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasData && _audiences.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _audiences = snap.data!.audiences);
            });
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }
          final list = snap.data?.notices ?? const [];
          if (list.isEmpty) {
            return const Center(child: Text('공지가 없습니다', style: TextStyle(color: AppColors.inkSoft)));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final n = list[i];
              return Container(
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
                      if (n.isPinned) const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(Icons.push_pin, size: 14, color: AppColors.accent),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.mango100, borderRadius: BorderRadius.circular(6)),
                        child: Text(n.audienceLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.mango800)),
                      ),
                      const Spacer(),
                      Text(n.createdAt ?? '', style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
                      IconButton(
                          onPressed: () => _delete(n),
                          icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.inkSoft)),
                    ]),
                    const SizedBox(height: 4),
                    Text(n.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    if (n.content != null && n.content!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(n.content!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: AppColors.inkSoft, height: 1.4)),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
