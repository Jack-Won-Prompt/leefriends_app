import 'paged.dart';

/// 본사 — FCM/인앱 알림 이력 한 건 (수신자별).
class NotificationLog {
  final int id;
  final String type;
  final String typeLabel;
  final String title;
  final String? body;
  final bool isRead;
  final String? createdAt; // Y.m.d H:i
  final String? userName;
  final String userRole; // hq | store
  final String? storeName;

  const NotificationLog({
    required this.id,
    required this.type,
    required this.typeLabel,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    required this.userName,
    required this.userRole,
    required this.storeName,
  });

  bool get isHq => userRole == 'hq';

  factory NotificationLog.fromJson(Map<String, dynamic> j) => NotificationLog(
        id: (j['id'] as num).toInt(),
        type: j['type'] as String? ?? '',
        typeLabel: j['type_label'] as String? ?? (j['type'] as String? ?? ''),
        title: j['title'] as String? ?? '',
        body: j['body'] as String?,
        isRead: j['is_read'] as bool? ?? false,
        createdAt: j['created_at'] as String?,
        userName: j['user_name'] as String?,
        userRole: j['user_role'] as String? ?? '',
        storeName: j['store_name'] as String?,
      );
}

/// 필터 선택지 (매장: key=id / 유형: key=type).
class NotificationLogOption {
  final String key;
  final String label;
  const NotificationLogOption({required this.key, required this.label});
}

/// 알림 이력 한 페이지 + 요약 건수 + 필터 선택지.
class NotificationLogPage {
  final Paged<NotificationLog> page;
  final int total;
  final int hqCount;
  final int storeCount;
  final List<NotificationLogOption> stores;
  final List<NotificationLogOption> types;

  const NotificationLogPage({
    required this.page,
    required this.total,
    required this.hqCount,
    required this.storeCount,
    required this.stores,
    required this.types,
  });

  factory NotificationLogPage.fromJson(Map<String, dynamic> body) {
    final meta = body['meta'] as Map<String, dynamic>? ?? const {};
    int n(Object? v) => (v as num?)?.toInt() ?? 0;
    return NotificationLogPage(
      page: Paged(
        items: (body['data'] as List? ?? [])
            .map((e) => NotificationLog.fromJson(e as Map<String, dynamic>))
            .toList(),
        hasMore: Paged.hasMoreFromMeta(meta),
      ),
      total: n(meta['total']),
      hqCount: n(meta['hq_count']),
      storeCount: n(meta['store_count']),
      stores: (meta['stores'] as List? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .map((e) => NotificationLogOption(key: '${e['id']}', label: e['name'] as String? ?? ''))
          .toList(),
      types: (meta['types'] as List? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .map((e) => NotificationLogOption(
              key: e['key'] as String? ?? '', label: e['label'] as String? ?? ''))
          .toList(),
    );
  }
}
