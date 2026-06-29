import 'package:flutter/foundation.dart';

import '../models/order.dart';
import '../models/supply_product.dart';

class CartLine {
  final SupplyProduct product;
  ProductUnit unit;
  int qty;
  CartLine({required this.product, required this.unit, this.qty = 1});

  /// 싯가 품목은 발주 시점 단가 미정 → 합계에 0으로 반영 (본사 확정).
  int get lineAmount => product.isMarketPrice ? 0 : unit.storePrice * qty;
}

/// 발주 장바구니. 물품(productId) 단위로 1줄, 단위/수량 변경 가능.
class CartController extends ChangeNotifier {
  final Map<int, CartLine> _lines = {};

  List<CartLine> get lines => _lines.values.toList();
  bool get isEmpty => _lines.isEmpty;
  int get count => _lines.length;
  int get totalQty => _lines.values.fold(0, (s, l) => s + l.qty);
  int get totalAmount => _lines.values.fold(0, (s, l) => s + l.lineAmount);

  int qtyOf(int productId) => _lines[productId]?.qty ?? 0;
  CartLine? lineOf(int productId) => _lines[productId];

  void add(SupplyProduct product, {ProductUnit? unit, int qty = 1}) {
    final existing = _lines[product.id];
    if (existing != null) {
      existing.qty += qty;
    } else {
      _lines[product.id] = CartLine(
        product: product,
        unit: unit ?? product.defaultUnit,
        qty: qty,
      );
    }
    notifyListeners();
  }

  void setQty(int productId, int qty) {
    final line = _lines[productId];
    if (line == null) return;
    if (qty <= 0) {
      _lines.remove(productId);
    } else {
      line.qty = qty;
    }
    notifyListeners();
  }

  void setUnit(int productId, ProductUnit unit) {
    final line = _lines[productId];
    if (line == null) return;
    line.unit = unit;
    notifyListeners();
  }

  void remove(int productId) {
    _lines.remove(productId);
    notifyListeners();
  }

  void clear() {
    _lines.clear();
    notifyListeners();
  }

  /// 발주 수정용 — 기존 주문 항목으로 장바구니를 채운다.
  /// 주문 항목 스냅샷만으로 최소 상품/단위를 구성한다(카탈로그 조회 불필요).
  void seedFromOrder(List<OrderItemView> items) {
    _lines.clear();
    for (final it in items) {
      if (it.productId == null) continue;
      final unit = ProductUnit(
        id: it.unitId,
        name: it.unit,
        storePrice: it.storeUnitPrice,
        isDefault: true,
      );
      final product = SupplyProduct(
        id: it.productId!,
        code: '',
        name: it.productName,
        category: '',
        categoryCode: null,
        spec: null,
        unit: it.unit,
        supplyTypeLabel: '',
        supplierName: it.supplierName,
        storePrice: it.storeUnitPrice,
        isMarketPrice: it.pricePending,
        imageUrl: null,
        units: [unit],
      );
      _lines[product.id] = CartLine(product: product, unit: unit, qty: it.qty);
    }
    notifyListeners();
  }

  /// API 전송용 payload.
  List<Map<String, dynamic>> toItems() => _lines.values
      .map((l) => {
            'product_id': l.product.id,
            if (l.unit.id != null) 'unit_id': l.unit.id,
            'qty': l.qty,
          })
      .toList();
}
