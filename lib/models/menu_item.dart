/// 메뉴 1개. 서버 /api/v1/menus 응답 스키마와 1:1 매핑됩니다.
class MenuItem {
  final int id;
  final String category;
  final String categoryLabel;
  final String name;
  final String? nameEn;
  final String? description;
  final int price;

  /// 원격 이미지 URL (API) 또는 null. null 이면 [assetImage] 로 폴백.
  final String? imageUrl;

  /// 번들 에셋 경로 (오프라인/샘플용). 파일명 기준으로 추론됩니다.
  final String assetImage;
  final String? badge; // best, new, hot

  const MenuItem({
    required this.id,
    required this.category,
    required this.categoryLabel,
    required this.name,
    required this.nameEn,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.assetImage,
    required this.badge,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    final image = json['image'] as String?;
    return MenuItem(
      id: json['id'] as int,
      category: json['category'] as String? ?? 'bingsu',
      categoryLabel: json['category_label'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameEn: json['name_en'] as String?,
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toInt() ?? 0,
      imageUrl: image,
      assetImage: _assetFrom(image),
      badge: json['badge'] as String?,
    );
  }

  /// API 의 image URL(…/images/menu/foo.svg) 에서 번들 에셋 경로를 추론.
  static String _assetFrom(String? url) {
    const fallback = 'assets/images/menu/mango-patbingsu.svg';
    if (url == null || url.isEmpty) return fallback;
    final file = url.split('/').last;
    if (file.isEmpty) return fallback;
    return 'assets/images/menu/$file';
  }

  String get priceLabel => '${_comma(price)}원';

  static String _comma(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class MenuCategory {
  final String key;
  final String label;
  const MenuCategory({required this.key, required this.label});

  factory MenuCategory.fromJson(Map<String, dynamic> json) => MenuCategory(
        key: json['key'] as String,
        label: json['label'] as String,
      );
}
