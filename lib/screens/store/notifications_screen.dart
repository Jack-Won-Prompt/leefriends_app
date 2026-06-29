import 'package:flutter/material.dart';

import '../../data/store_ops_repository.dart';
import '../../models/paged.dart';
import '../../models/store_ops.dart';
import '../../theme/app_colors.dart';
import '../../widgets/paged_list_view.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.repository, this.onChanged});

  final StoreOpsRepository repository;

  /// 읽음 상태 변경 시 호출 (배지 갱신용)
  final VoidCallback? onChanged;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _reloadToken = 0;

  void _reload() => setState(() => _reloadToken++);

  Future<void> _markAll() async {
    await widget.repository.markAllRead();
    widget.onChanged?.call();
    _reload();
  }

  Future<void> _open(AppNotificationItem n) async {
    if (!n.isRead) {
      await widget.repository.markRead(n.id);
      widget.onChanged?.call();
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('알림'),
        actions: [
          TextButton(
            onPressed: _markAll,
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
            child: const Text('모두 읽음',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: PagedListView<AppNotificationItem>(
        key: ValueKey(_reloadToken),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        emptyText: '알림이 없습니다',
        emptyIcon: Icons.notifications_none,
        fetch: (page) async {
          final r = await widget.repository.notifications(page: page);
          return Paged(items: r.items, hasMore: r.hasMore);
        },
        itemBuilder: (context, item) => _Tile(item: item, onTap: () => _open(item)),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.item, required this.onTap});
  final AppNotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: item.isRead ? AppColors.surface : AppColors.mango50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: item.isRead ? AppColors.line : AppColors.mango300),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.mango100,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(_icon(item.type), size: 20, color: AppColors.mango700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.title,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: item.isRead
                                    ? FontWeight.w600
                                    : FontWeight.w800,
                                color: AppColors.ink)),
                      ),
                      if (!item.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: AppColors.accent, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  if (item.body != null && item.body!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(item.body!,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.inkSoft, height: 1.4)),
                  ],
                  if (item.createdAt != null) ...[
                    const SizedBox(height: 6),
                    Text(item.createdAt!,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.inkSoft)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _icon(String type) {
    if (type.contains('order')) return Icons.receipt_long_outlined;
    if (type.contains('shipment') || type.contains('inbound')) {
      return Icons.local_shipping_outlined;
    }
    return Icons.notifications_outlined;
  }
}
