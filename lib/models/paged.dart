/// 페이지네이션 결과 묶음.
class Paged<T> {
  const Paged({required this.items, required this.hasMore});
  final List<T> items;
  final bool hasMore;

  /// Laravel paginate 메타(current_page/last_page) 기준으로 hasMore 계산.
  static bool hasMoreFromMeta(Map<String, dynamic>? meta) {
    if (meta == null) return false;
    final cur = (meta['current_page'] as num?)?.toInt();
    final last = (meta['last_page'] as num?)?.toInt();
    if (cur != null && last != null) return cur < last;
    // has_more 직접 제공 시
    return meta['has_more'] == true;
  }
}
