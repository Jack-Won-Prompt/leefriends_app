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

/// 본사 물류 입고 — 공급처 거래명세서(입고 대상).
class LogisticsInboundStatement {
  final int id;
  final String statementNo;
  final String? supplierName;
  final int itemCount;
  final int total;
  final bool received;
  final String? receivedAt;
  final String? createdAt;
  final List<({String name, int qty, String unit})> items;

  const LogisticsInboundStatement({
    required this.id,
    required this.statementNo,
    required this.supplierName,
    required this.itemCount,
    required this.total,
    required this.received,
    required this.receivedAt,
    required this.createdAt,
    required this.items,
  });

  factory LogisticsInboundStatement.fromJson(Map<String, dynamic> j) =>
      LogisticsInboundStatement(
        id: j['id'] as int,
        statementNo: j['statement_no'] as String? ?? '',
        supplierName: j['supplier_name'] as String?,
        itemCount: (j['item_count'] as num?)?.toInt() ?? 0,
        total: (j['total'] as num?)?.toInt() ?? 0,
        received: j['received'] as bool? ?? false,
        receivedAt: j['received_at'] as String?,
        createdAt: j['created_at'] as String?,
        items: ((j['items'] as List?) ?? [])
            .map((e) => (
                  name: (e['name'] ?? '').toString(),
                  qty: (e['qty'] as num?)?.toInt() ?? 0,
                  unit: (e['unit'] ?? '').toString(),
                ))
            .toList(),
      );
}

/// 수동 입고용 공급 품목.
class SupplyProductLite {
  final int id;
  final String name;
  final String unit;
  const SupplyProductLite({required this.id, required this.name, required this.unit});
  factory SupplyProductLite.fromJson(Map<String, dynamic> j) => SupplyProductLite(
        id: j['id'] as int,
        name: j['name'] as String? ?? '',
        unit: j['unit'] as String? ?? '',
      );
}
