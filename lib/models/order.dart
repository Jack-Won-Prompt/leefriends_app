String _won(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return '${b.toString()}원';
}

class OrderItemView {
  final int id;
  final int? productId;
  final int? unitId;
  final String productName;
  final String unit;
  final int qty;
  final int storeUnitPrice;
  final int storeLineAmount;
  final bool pricePending;
  final String? supplierName;

  const OrderItemView({
    required this.id,
    required this.productId,
    required this.unitId,
    required this.productName,
    required this.unit,
    required this.qty,
    required this.storeUnitPrice,
    required this.storeLineAmount,
    required this.pricePending,
    required this.supplierName,
  });

  /// 싯가 미확정이면 금액 대신 안내 문구.
  String get lineLabel => pricePending ? '싯가 · 확정 대기' : _won(storeLineAmount);

  factory OrderItemView.fromJson(Map<String, dynamic> j) => OrderItemView(
        id: j['id'] as int,
        productId: j['product_id'] as int?,
        unitId: j['unit_id'] as int?,
        productName: j['product_name'] as String? ?? '',
        unit: j['unit'] as String? ?? '',
        qty: (j['qty'] as num?)?.toInt() ?? 0,
        storeUnitPrice: (j['store_unit_price'] as num?)?.toInt() ?? 0,
        storeLineAmount: (j['store_line_amount'] as num?)?.toInt() ?? 0,
        pricePending: j['price_pending'] as bool? ?? false,
        supplierName: j['supplier_name'] as String?,
      );
}

class OrderModel {
  final int id;
  final String orderNo;
  final String status;
  final String statusLabel;
  final int itemCount;
  final int storeAmount;
  final String? createdAt;
  final String? note;
  final bool editable;
  final bool isSample;
  final List<OrderItemView> items;

  const OrderModel({
    required this.id,
    required this.orderNo,
    required this.status,
    required this.statusLabel,
    required this.itemCount,
    required this.storeAmount,
    required this.createdAt,
    required this.note,
    required this.editable,
    required this.isSample,
    required this.items,
  });

  String get amountLabel => _won(storeAmount);

  /// 상세를 불러오기 전 목록 데이터로는 editable 판단이 불확실하므로,
  /// pending 상태이면 수정/취소 후보로 본다(최종 판단은 서버가 409로 보장).
  bool get maybeEditable => editable || status == 'pending';

  factory OrderModel.fromJson(Map<String, dynamic> j) => OrderModel(
        id: j['id'] as int,
        orderNo: j['order_no'] as String? ?? '',
        status: j['status'] as String? ?? '',
        statusLabel: j['status_label'] as String? ?? '',
        itemCount: (j['item_count'] as num?)?.toInt() ?? 0,
        storeAmount: (j['store_amount'] as num?)?.toInt() ?? 0,
        createdAt: j['created_at'] as String?,
        note: j['note'] as String?,
        editable: j['editable'] as bool? ?? false,
        isSample: j['is_sample'] as bool? ?? false,
        items: (j['items'] as List? ?? [])
            .map((e) => OrderItemView.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
