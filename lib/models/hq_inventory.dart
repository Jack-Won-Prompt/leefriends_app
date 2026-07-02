// 본사 재고/물류 관리 모델.

class HqInventoryRow {
  HqInventoryRow({
    required this.productId,
    required this.name,
    this.code,
    this.unit,
    this.imageUrl,
    this.managed = false,
    this.qty,
    this.reserved = 0,
    this.available,
  });

  final int productId;
  final String name;
  final String? code;
  final String? unit;
  final String? imageUrl;
  final bool managed;
  final int? qty; // 미등록이면 null
  final int reserved;
  final int? available;

  factory HqInventoryRow.fromJson(Map<String, dynamic> j) => HqInventoryRow(
        productId: (j['product_id'] as num).toInt(),
        name: j['name']?.toString() ?? '',
        code: j['code']?.toString(),
        unit: j['unit']?.toString(),
        imageUrl: j['image']?.toString(),
        managed: j['managed'] == true,
        qty: (j['qty'] as num?)?.toInt(),
        reserved: (j['reserved'] as num?)?.toInt() ?? 0,
        available: (j['available'] as num?)?.toInt(),
      );
}

class HqInventoryMove {
  HqInventoryMove({
    required this.id,
    this.productName = '',
    this.type = '',
    this.delta = 0,
    this.note,
    this.createdAt,
  });

  final int id;
  final String productName;
  final String type;
  final int delta;
  final String? note;
  final String? createdAt;

  factory HqInventoryMove.fromJson(Map<String, dynamic> j) => HqInventoryMove(
        id: (j['id'] as num).toInt(),
        productName: j['product_name']?.toString() ?? '',
        type: j['type']?.toString() ?? '',
        delta: (j['delta'] as num?)?.toInt() ?? 0,
        note: j['note']?.toString(),
        createdAt: j['created_at']?.toString(),
      );
}

class HqInventoryIndex {
  HqInventoryIndex({
    this.rows = const [],
    this.recent = const [],
    this.page = 1,
    this.lastPage = 1,
  });

  final List<HqInventoryRow> rows;
  final List<HqInventoryMove> recent;
  final int page;
  final int lastPage;

  factory HqInventoryIndex.fromJson(Map<String, dynamic> j) {
    final meta = (j['meta'] as Map<String, dynamic>?) ?? {};
    return HqInventoryIndex(
      rows: (j['data'] as List? ?? [])
          .map((e) => HqInventoryRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      recent: (j['recent'] as List? ?? [])
          .map((e) => HqInventoryMove.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: (meta['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
    );
  }
}
