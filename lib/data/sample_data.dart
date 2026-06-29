import '../models/menu_item.dart';

/// API 미연결 시 사용하는 번들 샘플 데이터.
/// 서버 DB(mangobing.menus)의 실제 13개 메뉴와 동일하게 구성되어 있어,
/// 오프라인에서도 동일한 화면을 보여줍니다.
class SampleData {
  SampleData._();

  static const categories = <MenuCategory>[
    MenuCategory(key: 'signature', label: '시그니처'),
    MenuCategory(key: 'bingsu', label: '빙수'),
    MenuCategory(key: 'drink', label: '음료'),
    MenuCategory(key: 'dessert', label: '디저트'),
  ];

  static List<MenuItem> menus() => _raw.map(_build).toList();

  static MenuItem _build(List<dynamic> r) {
    final file = r[6] as String;
    return MenuItem(
      id: r[0] as int,
      category: r[1] as String,
      categoryLabel: r[2] as String,
      name: r[3] as String,
      nameEn: r[4] as String,
      description: r[8] as String,
      price: r[5] as int,
      imageUrl: null,
      assetImage: 'assets/images/menu/$file',
      badge: (r[7] as String).isEmpty ? null : r[7] as String,
    );
  }

  // id, category, categoryLabel, name, nameEn, price, imageFile, badge, description
  static const _raw = <List<dynamic>>[
    [1, 'signature', '시그니처', '망고치즈빙수', 'Mango Cheese Bingsu', 15900, 'mango-cheese-bingsu.svg', 'best', '농익은 애플망고와 부드러운 크림치즈가 어우러진 시그니처 빙수'],
    [2, 'signature', '시그니처', '애플망고빙수', 'Apple Mango Bingsu', 16900, 'apple-mango-bingsu.svg', 'best', '한 통 가득 올린 애플망고, 리프렌즈의 자존심'],
    [3, 'bingsu', '빙수', '망고요거트빙수', 'Mango Yogurt Bingsu', 13900, 'mango-yogurt-bingsu.svg', '', '상큼한 요거트 빙수 위 생망고 토핑'],
    [4, 'bingsu', '빙수', '트로피컬망고빙수', 'Tropical Mango Bingsu', 14900, 'tropical-mango-bingsu.svg', 'new', '망고·파인애플·패션후르츠가 가득한 열대 빙수'],
    [5, 'bingsu', '빙수', '망고팥빙수', 'Mango Patbingsu', 12900, 'mango-patbingsu.svg', '', '국산 팥과 망고의 전통과 트렌드의 만남'],
    [6, 'bingsu', '빙수', '망고초코빙수', 'Mango Choco Bingsu', 13900, 'mango-choco-bingsu.svg', '', '진한 벨기에 초코와 망고의 달콤한 조화'],
    [7, 'drink', '음료', '망고에이드', 'Mango Ade', 5900, 'mango-ade.svg', '', '톡 쏘는 청량감과 생망고의 만남'],
    [8, 'drink', '음료', '망고스무디', 'Mango Smoothie', 6900, 'mango-smoothie.svg', 'best', '생망고를 통째로 갈아 만든 진한 스무디'],
    [9, 'drink', '음료', '망고요거트스무디', 'Mango Yogurt Smoothie', 7200, 'mango-yogurt-smoothie.svg', '', '요거트와 망고의 부드러운 블렌딩'],
    [10, 'drink', '음료', '망고주스', 'Mango Juice', 6200, 'mango-juice.svg', '', '100% 망고 과즙의 순수한 한 잔'],
    [11, 'dessert', '디저트', '망고크림케이크', 'Mango Cream Cake', 7900, 'mango-cream-cake.svg', '', '생크림과 생망고가 층층이 쌓인 케이크'],
    [12, 'dessert', '디저트', '망고타르트', 'Mango Tart', 6900, 'mango-tart.svg', 'new', '바삭한 타르트 위 향긋한 망고'],
    [13, 'dessert', '디저트', '망고푸딩', 'Mango Pudding', 5500, 'mango-pudding.svg', '', '입에서 녹는 부드러운 망고 푸딩'],
  ];
}
