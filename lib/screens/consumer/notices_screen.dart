import 'package:flutter/material.dart';

import '../../data/content_repository.dart';
import '../../models/content.dart';
import '../../theme/app_colors.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key, required this.repository});

  final ContentRepository repository;

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  late Future<({List<NoticeItem> notices, List<NoticeCategory> categories})>
      _future;
  String _cat = 'all';

  @override
  void initState() {
    super.initState();
    _future = widget.repository.notices();
  }

  void _select(String cat) {
    setState(() {
      _cat = cat;
      _future = widget.repository.notices(cat: cat);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('공지사항')),
      body: FutureBuilder<
          ({List<NoticeItem> notices, List<NoticeCategory> categories})>(
        future: _future,
        builder: (context, snap) {
          final cats = <NoticeCategory>[
            const NoticeCategory(key: 'all', label: '전체'),
            ...?snap.data?.categories,
          ];
          final notices = snap.data?.notices ?? const [];
          return Column(
            children: [
              SizedBox(
                height: 58,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: cats.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final c = cats[i];
                    final active = c.key == _cat;
                    return Align(
                      alignment: Alignment.center,
                      child: GestureDetector(
                      onTap: () => _select(c.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color: active ? AppColors.accent : AppColors.surface,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                              color: active ? AppColors.accent : AppColors.line),
                        ),
                        child: Text(c.label,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: active ? Colors.white : AppColors.inkSoft)),
                      ),
                    ),
                    );
                  },
                ),
              ),
              Expanded(
                child: snap.connectionState == ConnectionState.waiting
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.accent))
                    : notices.isEmpty
                        ? const Center(
                            child: Text('공지사항이 없습니다',
                                style: TextStyle(color: AppColors.inkSoft)))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: notices.length,
                            itemBuilder: (context, i) => _NoticeTile(
                              notice: notices[i],
                              repository: widget.repository,
                            ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NoticeTile extends StatelessWidget {
  const _NoticeTile({required this.notice, required this.repository});
  final NoticeItem notice;
  final ContentRepository repository;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              NoticeDetailScreen(repository: repository, notice: notice),
        ),
      ),
      child: Container(
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
            Row(
              children: [
                if (notice.isPinned) ...[
                  const Icon(Icons.push_pin, size: 14, color: AppColors.accent),
                  const SizedBox(width: 4),
                ],
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: AppColors.mango100,
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(notice.categoryLabel,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mango800)),
                ),
                const Spacer(),
                if (notice.publishedAt != null)
                  Text(notice.publishedAt!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.inkSoft)),
              ],
            ),
            const SizedBox(height: 10),
            Text(notice.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    height: 1.4)),
          ],
        ),
      ),
    );
  }
}

class NoticeDetailScreen extends StatefulWidget {
  const NoticeDetailScreen(
      {super.key, required this.repository, required this.notice});
  final ContentRepository repository;
  final NoticeItem notice;

  @override
  State<NoticeDetailScreen> createState() => _NoticeDetailScreenState();
}

class _NoticeDetailScreenState extends State<NoticeDetailScreen> {
  late Future<NoticeItem> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.noticeDetail(widget.notice.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(widget.notice.categoryLabel)),
      body: FutureBuilder<NoticeItem>(
        future: _future,
        builder: (context, snap) {
          final n = snap.data ?? widget.notice;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            children: [
              Text(n.title,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                      color: AppColors.ink)),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (n.publishedAt != null)
                    Text(n.publishedAt!,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.inkSoft)),
                  const SizedBox(width: 12),
                  Text('조회 ${n.views}',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.inkSoft)),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Divider(),
              ),
              if (snap.connectionState == ConnectionState.waiting)
                const Center(
                    child: CircularProgressIndicator(color: AppColors.accent))
              else
                Text(n.content ?? '',
                    style: const TextStyle(
                        fontSize: 15, height: 1.7, color: AppColors.ink)),
            ],
          );
        },
      ),
    );
  }
}
