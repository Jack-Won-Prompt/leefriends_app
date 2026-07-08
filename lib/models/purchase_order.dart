int _i(dynamic v) => (v as num?)?.toInt() ?? 0;

/// 구매발주 (본사 → 공급사).
class PurchaseOrder {
  final int id;
  final String poNo;
  final String? supplierName;
  final String status;
  final String statusLabel;
  final int totalAmount;
  final int itemCount;
  final String? note;
  final String? createdAt;
  final String? confirmedAt;
  final String? receivedAt;
  final List<PurchaseOrderItem> items;

  const PurchaseOrder({
    required this.id,
    required this.poNo,
    required this.supplierName,
    required this.status,
    required this.statusLabel,
    required this.totalAmount,
    required this.itemCount,
    required this.note,
    required this.createdAt,
    required this.confirmedAt,
    required this.receivedAt,
    required this.items,
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> j) => PurchaseOrder(
        id: j['id'] as int,
        poNo: j['po_no'] as String? ?? '',
        supplierName: j['supplier_name'] as String?,
        status: j['status'] as String? ?? '',
        statusLabel: j['status_label'] as String? ?? '',
        totalAmount: _i(j['total_amount']),
        itemCount: _i(j['item_count']),
        note: j['note'] as String?,
        createdAt: j['created_at'] as String?,
        confirmedAt: j['confirmed_at'] as String?,
        receivedAt: j['received_at'] as String?,
        items: ((j['items'] as List?) ?? [])
            .map((e) => PurchaseOrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class PurchaseOrderItem {
  final String productName;
  final String unit;
  final int qty;
  final int unitPrice;
  final int lineAmount;
  final int receivedQty;

  const PurchaseOrderItem({
    required this.productName,
    required this.unit,
    required this.qty,
    required this.unitPrice,
    required this.lineAmount,
    required this.receivedQty,
  });

  factory PurchaseOrderItem.fromJson(Map<String, dynamic> j) => PurchaseOrderItem(
        productName: j['product_name'] as String? ?? '',
        unit: j['unit'] as String? ?? '',
        qty: _i(j['qty']),
        unitPrice: _i(j['unit_price']),
        lineAmount: _i(j['line_amount']),
        receivedQty: _i(j['received_qty']),
      );
}

/// 구매발주 생성 폼용 공급처.
class PoSupplier {
  final int id;
  final String name;
  const PoSupplier({required this.id, required this.name});
  factory PoSupplier.fromJson(Map<String, dynamic> j) =>
      PoSupplier(id: j['id'] as int, name: j['name'] as String? ?? '');
}

/// 구매발주 생성 폼용 공급 품목.
class PoProduct {
  final int id;
  final int supplierId;
  final String name;
  final String unit;
  final int supplyPrice;
  const PoProduct({
    required this.id,
    required this.supplierId,
    required this.name,
    required this.unit,
    required this.supplyPrice,
  });
  factory PoProduct.fromJson(Map<String, dynamic> j) => PoProduct(
        id: j['id'] as int,
        supplierId: _i(j['supplier_id']),
        name: j['name'] as String? ?? '',
        unit: j['unit'] as String? ?? '',
        supplyPrice: _i(j['supply_price']),
      );
}
