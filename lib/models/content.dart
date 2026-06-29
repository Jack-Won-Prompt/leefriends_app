// 소비자 공지/매장찾기 모델.

class NoticeItem {
  final int id;
  final String category;
  final String categoryLabel;
  final String title;
  final bool isPinned;
  final int views;
  final String? publishedAt;
  final String? content;

  const NoticeItem({
    required this.id,
    required this.category,
    required this.categoryLabel,
    required this.title,
    required this.isPinned,
    required this.views,
    required this.publishedAt,
    required this.content,
  });

  factory NoticeItem.fromJson(Map<String, dynamic> j) => NoticeItem(
        id: j['id'] as int,
        category: j['category'] as String? ?? '',
        categoryLabel: j['category_label'] as String? ?? '',
        title: j['title'] as String? ?? '',
        isPinned: j['is_pinned'] as bool? ?? false,
        views: (j['views'] as num?)?.toInt() ?? 0,
        publishedAt: j['published_at'] as String?,
        content: j['content'] as String?,
      );
}

class NoticeCategory {
  final String key;
  final String label;
  const NoticeCategory({required this.key, required this.label});
  factory NoticeCategory.fromJson(Map<String, dynamic> j) => NoticeCategory(
        key: j['key'] as String,
        label: j['label'] as String,
      );
}

class StoreLocation {
  final int id;
  final String name;
  final String region;
  final String address;
  final String? phone;
  final String? hours;
  final double? lat;
  final double? lng;
  final String? image;

  const StoreLocation({
    required this.id,
    required this.name,
    required this.region,
    required this.address,
    required this.phone,
    required this.hours,
    required this.lat,
    required this.lng,
    required this.image,
  });

  factory StoreLocation.fromJson(Map<String, dynamic> j) => StoreLocation(
        id: j['id'] as int,
        name: j['name'] as String? ?? '',
        region: j['region'] as String? ?? '',
        address: j['address'] as String? ?? '',
        phone: j['phone'] as String?,
        hours: j['hours'] as String?,
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
        image: j['image'] as String?,
      );
}
