// 매장 운영(입고·재고·매입·알림) 모델.

import 'paged.dart';

String won(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return '${b.toString()}원';
}

/// 매장 세금계산서 (본사 → 매장)
class StoreTaxInvoice {
  final int id;
  final String invoiceNo;
  final String? invoicerName;
  final int supplyAmount;
  final int vat;
  final int totalAmount;
  final String status;
  final String statusLabel;
  final String? ntsConfirmNum;
  final String? issueDate;
  // 상세
  final String? invoicerCorpNum;
  final String? invoicerCorpName;
  final String? invoiceeCorpNum;
  final String? invoiceeCorpName;
  final String? note;
  final List<TaxInvoiceLine> lineItems;

  const StoreTaxInvoice({
    required this.id,
    required this.invoiceNo,
    required this.invoicerName,
    required this.supplyAmount,
    required this.vat,
    required this.totalAmount,
    required this.status,
    required this.statusLabel,
    required this.ntsConfirmNum,
    required this.issueDate,
    this.invoicerCorpNum,
    this.invoicerCorpName,
    this.invoiceeCorpNum,
    this.invoiceeCorpName,
    this.note,
    this.lineItems = const [],
  });

  factory StoreTaxInvoice.fromJson(Map<String, dynamic> j) => StoreTaxInvoice(
        id: j['id'] as int,
        invoiceNo: j['invoice_no'] as String? ?? '',
        invoicerName: j['invoicer_name'] as String?,
        supplyAmount: (j['supply_amount'] as num?)?.toInt() ?? 0,
        vat: (j['vat'] as num?)?.toInt() ?? 0,
        totalAmount: (j['total_amount'] as num?)?.toInt() ?? 0,
        status: j['status'] as String? ?? '',
        statusLabel: j['status_label'] as String? ?? '',
        ntsConfirmNum: j['nts_confirm_num'] as String?,
        issueDate: j['issue_date'] as String?,
        invoicerCorpNum: j['invoicer_corp_num'] as String?,
        invoicerCorpName: j['invoicer_corp_name'] as String?,
        invoiceeCorpNum: j['invoicee_corp_num'] as String?,
        invoiceeCorpName: j['invoicee_corp_name'] as String?,
        note: j['note'] as String?,
        lineItems: (j['line_items'] as List? ?? [])
            .map((e) => TaxInvoiceLine.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class TaxInvoiceLine {
  final String name;
  final int qty;
  final int unitPrice;
  final int amount;
  const TaxInvoiceLine(
      {required this.name, required this.qty, required this.unitPrice, required this.amount});
  factory TaxInvoiceLine.fromJson(Map<String, dynamic> j) => TaxInvoiceLine(
        name: j['name'] as String? ?? '',
        qty: (j['qty'] as num?)?.toInt() ?? 0,
        unitPrice: (j['unit_price'] as num?)?.toInt() ?? 0,
        amount: (j['amount'] as num?)?.toInt() ?? 0,
      );
}

/// 발주 거래명세서
class OrderStatement {
  final String orderNo;
  final String? createdAt;
  final String? storeName;
  final String? storeAddress;
  final int total;
  final List<StatementGroup> groups;

  const OrderStatement({
    required this.orderNo,
    required this.createdAt,
    required this.storeName,
    required this.storeAddress,
    required this.total,
    required this.groups,
  });

  factory OrderStatement.fromJson(Map<String, dynamic> j) => OrderStatement(
        orderNo: j['order_no'] as String? ?? '',
        createdAt: j['created_at'] as String?,
        storeName: j['store_name'] as String?,
        storeAddress: j['store_address'] as String?,
        total: (j['total'] as num?)?.toInt() ?? 0,
        groups: (j['groups'] as List? ?? [])
            .map((e) => StatementGroup.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class StatementGroup {
  final String seller;
  final int subtotal;
  final List<StatementLine> items;
  const StatementGroup({required this.seller, required this.subtotal, required this.items});
  factory StatementGroup.fromJson(Map<String, dynamic> j) => StatementGroup(
        seller: j['seller'] as String? ?? '',
        subtotal: (j['subtotal'] as num?)?.toInt() ?? 0,
        items: (j['items'] as List? ?? [])
            .map((e) => StatementLine.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class StatementLine {
  final String name;
  final String unit;
  final int qty;
  final int unitPrice;
  final int amount;
  const StatementLine(
      {required this.name, required this.unit, required this.qty, required this.unitPrice, required this.amount});
  factory StatementLine.fromJson(Map<String, dynamic> j) => StatementLine(
        name: j['name'] as String? ?? '',
        unit: j['unit'] as String? ?? '',
        qty: (j['qty'] as num?)?.toInt() ?? 0,
        unitPrice: (j['unit_price'] as num?)?.toInt() ?? 0,
        amount: (j['amount'] as num?)?.toInt() ?? 0,
      );
}

/// 매장 홈 대시보드 요약
class StoreDashboard {
  final int activeOrders;
  final int inTransit;
  final int inventoryItems;
  final int lowStock;
  final int monthAmount;

  const StoreDashboard({
    required this.activeOrders,
    required this.inTransit,
    required this.inventoryItems,
    required this.lowStock,
    required this.monthAmount,
  });

  factory StoreDashboard.fromJson(Map<String, dynamic> j) => StoreDashboard(
        activeOrders: (j['active_orders'] as num?)?.toInt() ?? 0,
        inTransit: (j['in_transit'] as num?)?.toInt() ?? 0,
        inventoryItems: (j['inventory_items'] as num?)?.toInt() ?? 0,
        lowStock: (j['low_stock'] as num?)?.toInt() ?? 0,
        monthAmount: (j['month_amount'] as num?)?.toInt() ?? 0,
      );
}

/// 알림
class AppNotificationItem {
  final int id;
  final String type;
  final String title;
  final String? body;
  final bool isRead;
  final String? createdAt;

  const AppNotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotificationItem.fromJson(Map<String, dynamic> j) =>
      AppNotificationItem(
        id: j['id'] as int,
        type: j['type'] as String? ?? '',
        title: j['title'] as String? ?? '',
        body: j['body'] as String?,
        isRead: j['is_read'] as bool? ?? false,
        createdAt: j['created_at'] as String?,
      );
}

/// 입고예정(확인된 판매주문)
class InboundExpected {
  final int id;
  final String salesOrderNo;
  final String? orderNo;
  final String? seller;
  final int itemCount;
  final int storeAmount;
  final String? createdAt;

  const InboundExpected({
    required this.id,
    required this.salesOrderNo,
    required this.orderNo,
    required this.seller,
    required this.itemCount,
    required this.storeAmount,
    required this.createdAt,
  });

  factory InboundExpected.fromJson(Map<String, dynamic> j) => InboundExpected(
        id: j['id'] as int,
        salesOrderNo: j['sales_order_no'] as String? ?? '',
        orderNo: j['order_no'] as String?,
        seller: j['seller'] as String?,
        itemCount: (j['item_count'] as num?)?.toInt() ?? 0,
        storeAmount: (j['store_amount'] as num?)?.toInt() ?? 0,
        createdAt: j['created_at'] as String?,
      );
}

/// 출고(배송) 요약/상세
class ShipmentModel {
  final int id;
  final String shipmentNo;
  final String status;
  final String statusLabel;
  final String? seller;
  final String? carrier;
  final String? trackingNo;
  final int itemCount;
  final int totalQty;
  final String? confirmedAt;
  final String? receivedAt;
  final String? note;
  final List<ShipmentItem> items;

  const ShipmentModel({
    required this.id,
    required this.shipmentNo,
    required this.status,
    required this.statusLabel,
    required this.seller,
    required this.carrier,
    required this.trackingNo,
    required this.itemCount,
    required this.totalQty,
    required this.confirmedAt,
    required this.receivedAt,
    required this.note,
    required this.items,
  });

  factory ShipmentModel.fromJson(Map<String, dynamic> j) => ShipmentModel(
        id: j['id'] as int,
        shipmentNo: j['shipment_no'] as String? ?? '',
        status: j['status'] as String? ?? '',
        statusLabel: j['status_label'] as String? ?? '',
        seller: j['seller'] as String?,
        carrier: j['carrier'] as String?,
        trackingNo: j['tracking_no'] as String?,
        itemCount: (j['item_count'] as num?)?.toInt() ?? 0,
        totalQty: (j['total_qty'] as num?)?.toInt() ?? 0,
        confirmedAt: j['confirmed_at'] as String?,
        receivedAt: j['received_at'] as String?,
        note: j['note'] as String?,
        items: (j['items'] as List? ?? [])
            .map((e) => ShipmentItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class ShipmentItem {
  final int id;
  final String productName;
  final String unit;
  final int qty;
  final String? imageUrl;

  const ShipmentItem({
    required this.id,
    required this.productName,
    required this.unit,
    required this.qty,
    this.imageUrl,
  });

  factory ShipmentItem.fromJson(Map<String, dynamic> j) => ShipmentItem(
        id: j['id'] as int,
        productName: j['product_name'] as String? ?? '',
        unit: j['unit'] as String? ?? '',
        qty: (j['qty'] as num?)?.toInt() ?? 0,
        imageUrl: j['image'] as String?,
      );
}

/// 재고 항목
class InventoryItem {
  final int id;
  final int? productId;
  final int? unitId;
  final String productName;
  final String unitName;
  final int qty;
  final String? imageUrl;

  const InventoryItem({
    required this.id,
    required this.productId,
    required this.unitId,
    required this.productName,
    required this.unitName,
    required this.qty,
    this.imageUrl,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> j) => InventoryItem(
        id: j['id'] as int,
        productId: j['product_id'] as int?,
        unitId: j['unit_id'] as int?,
        productName: j['product_name'] as String? ?? '',
        unitName: j['unit_name'] as String? ?? '',
        qty: (j['qty'] as num?)?.toInt() ?? 0,
        imageUrl: j['image'] as String?,
      );
}

/// 재고 이동내역
class InventoryMovementItem {
  final int id;
  final String type; // in/out/adjust
  final String typeLabel;
  final String productName;
  final String unitName;
  final int qty;
  final int balanceAfter;
  final String? note;
  final String? createdAt;

  const InventoryMovementItem({
    required this.id,
    required this.type,
    required this.typeLabel,
    required this.productName,
    required this.unitName,
    required this.qty,
    required this.balanceAfter,
    required this.note,
    required this.createdAt,
  });

  factory InventoryMovementItem.fromJson(Map<String, dynamic> j) =>
      InventoryMovementItem(
        id: j['id'] as int,
        type: j['type'] as String? ?? '',
        typeLabel: j['type_label'] as String? ?? '',
        productName: j['product_name'] as String? ?? '',
        unitName: j['unit_name'] as String? ?? '',
        qty: (j['qty'] as num?)?.toInt() ?? 0,
        balanceAfter: (j['balance_after'] as num?)?.toInt() ?? 0,
        note: j['note'] as String?,
        createdAt: j['created_at'] as String?,
      );
}

/// 매입 내역 (합계 + 주문 목록)
class PurchaseSummary {
  final int totalAmount;
  final int totalOrders;
  final List<PurchaseOrder> orders;
  final bool hasMore;

  const PurchaseSummary({
    required this.totalAmount,
    required this.totalOrders,
    required this.orders,
    this.hasMore = false,
  });

  factory PurchaseSummary.fromJson(Map<String, dynamic> j) => PurchaseSummary(
        totalAmount: (j['totals']?['amount'] as num?)?.toInt() ?? 0,
        totalOrders: (j['totals']?['orders'] as num?)?.toInt() ?? 0,
        orders: (j['data'] as List? ?? [])
            .map((e) => PurchaseOrder.fromJson(e as Map<String, dynamic>))
            .toList(),
        hasMore: Paged.hasMoreFromMeta(j['meta'] as Map<String, dynamic>?),
      );
}

class PurchaseOrder {
  final int id;
  final String orderNo;
  final String statusLabel;
  final int itemCount;
  final int storeAmount;
  final String? createdAt;

  const PurchaseOrder({
    required this.id,
    required this.orderNo,
    required this.statusLabel,
    required this.itemCount,
    required this.storeAmount,
    required this.createdAt,
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> j) => PurchaseOrder(
        id: j['id'] as int,
        orderNo: j['order_no'] as String? ?? '',
        statusLabel: j['status_label'] as String? ?? '',
        itemCount: (j['item_count'] as num?)?.toInt() ?? 0,
        storeAmount: (j['store_amount'] as num?)?.toInt() ?? 0,
        createdAt: j['created_at'] as String?,
      );
}

/// 과일 보관 가이드 (냉장/냉동 조건). 본사 관리 / 매장 공유 조회 공용.
class FruitStorageItem {
  final int id;
  final String name;
  final String? tempC;
  final String? tempF;
  final String? ventilation;
  final String? humidity;
  final String? dehumidification;
  final String? storagePeriod;
  final String? note;
  final bool isShared;
  final bool isActive;
  final int sortOrder;

  const FruitStorageItem({
    required this.id,
    required this.name,
    this.tempC,
    this.tempF,
    this.ventilation,
    this.humidity,
    this.dehumidification,
    this.storagePeriod,
    this.note,
    this.isShared = false,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory FruitStorageItem.fromJson(Map<String, dynamic> j) => FruitStorageItem(
        id: j['id'] as int,
        name: j['name'] as String? ?? '',
        tempC: j['temp_c'] as String?,
        tempF: j['temp_f'] as String?,
        ventilation: j['ventilation'] as String?,
        humidity: j['humidity'] as String?,
        dehumidification: j['dehumidification'] as String?,
        storagePeriod: j['storage_period'] as String?,
        note: j['note'] as String?,
        isShared: j['is_shared'] as bool? ?? false,
        isActive: j['is_active'] as bool? ?? true,
        sortOrder: (j['sort_order'] as num?)?.toInt() ?? 0,
      );
}
