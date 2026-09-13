import 'package:flutter/material.dart';

import '../../models/fulfillment.dart' show PortalNoticeItem;
import '../../models/paged.dart';
import '../../theme/app_colors.dart';
import '../../widgets/paged_list_view.dart';

/// 매장·공급처 — 본사 공지사항 목록. 웹 포털 «공지사항» 과 같은 내용(대상: 전체 + 내 역할).
/// 조회 함수를 받아 매장(StoreOpsRepository)·공급처(SellerRepository) 어디서든 쓸 수 있다.
class PortalNoticesScreen extends StatelessWidget {
  const PortalNoticesScreen({super.key, required this.fetch, required this.fetchOne});

  final Future<Paged<PortalNoticeItem>> Function(int page) fetch;
  final Future<PortalNoticeItem> Function(int id) fetchOne;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('공지사항')),
      body: PagedListView<PortalNoticeItem>(
        emptyText: '공지사항이 없습니다',
        emptyIcon: Icons.campaign_outlined,
        fetch: fetch,
        itemBuilder: (context, n) => _NoticeTile(
          notice: n,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => PortalNoticeDetailScreen(id: n.id, fetchOne: fetchOne, initial: n),
          )),
        ),
      ),
    );
  }
}

class _NoticeTile extends StatelessWidget {
  const _NoticeTile({required this.notice, required this.onTap});
  final PortalNoticeItem notice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: notice.isPinned ? AppColors.mango300 : AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (notice.isPinned) const _PinnedChip(),
                Expanded(
                  child: Text(notice.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
                ),
                const Icon(Icons.chevron_right, color: AppColors.inkSoft),
              ]),
              if ((notice.content ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(notice.content!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: AppColors.inkSoft, height: 1.4)),
              ],
              if (notice.createdAt != null) ...[
                const SizedBox(height: 8),
                Text(notice.createdAt!,
                    style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
              ],
            ],
          ),
        ),
      ),
    ).withBottomGap();
  }
}

class _PinnedChip extends StatelessWidget {
  const _PinnedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6, top: 1),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.mango100,
        borderRadius: BorderRadius.circular(100),
      ),
      child: const Text('고정',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.mango800)),
    );
  }
}

extension on Widget {
  Widget withBottomGap() => Padding(padding: const EdgeInsets.only(bottom: 10), child: this);
}

/// 공지 상세 — id 로 불러온다(알림에서 바로 열 때). 목록에서 오면 [initial] 을 먼저 보여주고 최신 내용으로 갱신.
class PortalNoticeDetailScreen extends StatefulWidget {
  const PortalNoticeDetailScreen({
    super.key,
    required this.id,
    required this.fetchOne,
    this.initial,
  });

  final int id;
  final Future<PortalNoticeItem> Function(int id) fetchOne;
  final PortalNoticeItem? initial;

  @override
  State<PortalNoticeDetailScreen> createState() => _PortalNoticeDetailScreenState();
}

class _PortalNoticeDetailScreenState extends State<PortalNoticeDetailScreen> {
  late Future<PortalNoticeItem> _future = widget.fetchOne(widget.id);

  void _retry() => setState(() => _future = widget.fetchOne(widget.id));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('공지사항')),
      body: FutureBuilder<PortalNoticeItem>(
        future: _future,
        builder: (context, snap) {
          final n = snap.data ?? widget.initial;
          if (n == null) {
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.campaign_outlined, size: 40, color: AppColors.inkSoft),
                    const SizedBox(height: 10),
                    Text(
                      snap.error.toString().replaceFirst('OrderException: ', ''),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.inkSoft),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: _retry, child: const Text('다시 시도')),
                  ]),
                ),
              );
            }
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }
          return ListView(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 32 + MediaQuery.of(context).padding.bottom),
            children: [
              if (n.isPinned)
                const Align(alignment: Alignment.centerLeft, child: _PinnedChip()),
              if (n.isPinned) const SizedBox(height: 8),
              Text(n.title,
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.ink, height: 1.35)),
              if (n.createdAt != null) ...[
                const SizedBox(height: 6),
                Text('본사 · ${n.createdAt}',
                    style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
              ],
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.line),
              const SizedBox(height: 16),
              SelectableText(
                (n.content ?? '').isEmpty ? '내용이 없습니다.' : n.content!,
                style: const TextStyle(fontSize: 15, color: AppColors.ink, height: 1.65),
              ),
            ],
          );
        },
      ),
    );
  }
}
