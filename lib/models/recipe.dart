/// 레시피 — 본사가 물품별로 이미지+글(HTML)로 등록, 매장/공급처가 열람.
/// 웹 포털 «레시피» 와 같은 데이터. content 는 정규화된 표준 HTML.
class RecipeItem {
  final int id;
  final String title;
  final String? productName;
  final String? content; // HTML
  final String? imageUrl;
  final String? author;
  final String? createdAt;

  const RecipeItem({
    required this.id,
    required this.title,
    this.productName,
    this.content,
    this.imageUrl,
    this.author,
    this.createdAt,
  });

  factory RecipeItem.fromJson(Map<String, dynamic> j) => RecipeItem(
        id: j['id'] as int,
        title: j['title'] as String? ?? '',
        productName: j['product_name'] as String?,
        content: j['content'] as String?,
        imageUrl: j['image_url'] as String?,
        author: j['author'] as String?,
        createdAt: j['created_at'] as String?,
      );
}
