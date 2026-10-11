/// 레시피 — 본사가 물품별로 이미지+영상+글(HTML)로 등록, 매장/공급처가 열람.
/// 웹 포털 «레시피» 와 같은 데이터. content 는 정규화된 표준 HTML.
/// 영상: videoUrl(업로드 파일) 은 앱 내 재생, videoLink(외부 링크) 는 외부 열기.
class RecipeItem {
  final int id;
  final String title;
  final String? productName;
  final String? content; // HTML
  final String? imageUrl;
  final String? videoUrl; // 업로드한 영상 파일 (앱 내 플레이어)
  final String? videoLink; // 외부 링크(유튜브 등) — 원본 주소, 외부 앱/브라우저로 열기
  final bool hasVideo;
  final String? author;
  final String? createdAt;

  const RecipeItem({
    required this.id,
    required this.title,
    this.productName,
    this.content,
    this.imageUrl,
    this.videoUrl,
    this.videoLink,
    this.hasVideo = false,
    this.author,
    this.createdAt,
  });

  factory RecipeItem.fromJson(Map<String, dynamic> j) => RecipeItem(
        id: j['id'] as int,
        title: j['title'] as String? ?? '',
        productName: j['product_name'] as String?,
        content: j['content'] as String?,
        imageUrl: j['image_url'] as String?,
        videoUrl: j['video_url'] as String?,
        videoLink: j['video_link'] as String?,
        hasVideo: j['has_video'] as bool? ?? false,
        author: j['author'] as String?,
        createdAt: j['created_at'] as String?,
      );
}
