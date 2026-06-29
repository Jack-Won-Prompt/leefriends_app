// 본사/공급처(판매자) 발주처리·출고 모델.

int _i(dynamic v) => (v as num?)?.toInt() ?? 0;

class StatusOption {
  final String key;
  final String label;
  const StatusOption({required this.key, required this.label});
  factory StatusOption.fromJson(Map<String, dynamic> j) =>
      StatusOption(key: j['key'] as String, label: j['label'] as String);
}

class SellerDashboard {
  final String role;
  final int pendingSalesOrders;
  final int confirmedSalesOrders;
  final int shipmentsToConfirm;
  final int inTransit;
  final int pendingChanges;
  final int todayOrders;
  final List<SellerOrder> recentOrders;

  const SellerDashboard({
    required this.role,
    required this.pendingSalesOrders,
    required this.confirmedSalesOrders,
    required this.shipmentsToConfirm,
    required this.inTransit,
    required this.pendingChanges,
    required this.todayOrders,
    required this.recentOrders,
  });

  factory SellerDashboard.fromJson(Map<String, dynamic> j) => SellerDashboard(
        role: j['role'] as String? ?? '',
        pendingSalesOrders: _i(j['pending_sales_orders']),
        confirmedSalesOrders: _i(j['confirmed_sales_orders']),
        shipmentsToConfirm: _i(j['shipments_to_confirm']),
        inTransit: _i(j['in_transit']),
        pendingChanges: _i(j['pending_changes']),
        todayOrders: _i(j['today_orders']),
        recentOrders: (j['recent_orders'] as List? ?? [])
            .map((e) => SellerOrder.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class FulfillItem {
  final int id;
  final String productName;
  final String unit;
  final int qty;
  final int supplyLineAmount;
  final int storeLineAmount;
  final int storeUnitPrice;
  final bool pricePending;
  final String? supplierName;
  final String? supplyType; // hq | supplier
  final String? fulfillmentStatus;

  const FulfillItem({
    required this.id,
    required this.productName,
    required this.unit,
    required this.qty,
    required this.supplyLineAmount,
    required this.storeLineAmount,
    required this.storeUnitPrice,
    required this.pricePending,
    required this.supplierName,
    required this.supplyType,
    required this.fulfillmentStatus,
  });

  factory FulfillItem.fromJson(Map<String, dynamic> j) => FulfillItem(
        id: j['id'] as int,
        productName: j['product_name'] as String? ?? '',
        unit: j['unit'] as String? ?? '',
        qty: _i(j['qty']),
        supplyLineAmount: _i(j['supply_line_amount']),
        storeLineAmount: _i(j['store_line_amount']),
        storeUnitPrice: _i(j['store_unit_price']),
        pricePending: j['price_pending'] as bool? ?? false,
        supplierName: j['supplier_name'] as String?,
        supplyType: j['supply_type'] as String?,
        fulfillmentStatus: j['fulfillment_status'] as String?,
      );
}

/// 택배사 옵션 (출고 확정 드롭다운용, 직접 배송 포함).
class CarrierOption {
  final int id;
  final String name;
  final bool isDirect;

  const CarrierOption({required this.id, required this.name, required this.isDirect});

  factory CarrierOption.fromJson(Map<String, dynamic> j) => CarrierOption(
        id: _i(j['id']),
        name: j['name'] as String? ?? '',
        isDirect: j['is_direct'] == true,
      );
}

class SellerSalesOrder {
  final int id;
  final String salesOrderNo;
  final String status;
  final String statusLabel;
  final String? sellerType; // hq | supplier
  final String? storeName;
  final String? orderNo;
  final int itemCount;
  final int storeAmount;
  final int supplyAmount;
  final String? confirmedAt;
  final String? createdAt;
  final List<FulfillItem> items;

  const SellerSalesOrder({
    required this.id,
    required this.salesOrderNo,
    required this.status,
    required this.statusLabel,
    required this.sellerType,
    required this.storeName,
    required this.orderNo,
    required this.itemCount,
    required this.storeAmount,
    required this.supplyAmount,
    required this.confirmedAt,
    required this.createdAt,
    required this.items,
  });

  /// 공급처는 공급가, 본사는 매장가(본사 매출) 기준. seller_type 미제공 시 0이 아닌 값으로 폴백.
  bool get _useSupply => sellerType == 'supplier';

  /// 판매주문 합계 (역할 기준 금액).
  int get amount {
    if (sellerType != null) return _useSupply ? supplyAmount : storeAmount;
    return supplyAmount != 0 ? supplyAmount : storeAmount;
  }

  /// 품목 금액 (역할 기준).
  int itemAmount(FulfillItem it) {
    if (sellerType != null) return _useSupply ? it.supplyLineAmount : it.storeLineAmount;
    return it.supplyLineAmount != 0 ? it.supplyLineAmount : it.storeLineAmount;
  }

  factory SellerSalesOrder.fromJson(Map<String, dynamic> j) => SellerSalesOrder(
        id: j['id'] as int,
        salesOrderNo: j['sales_order_no'] as String? ?? '',
        status: j['status'] as String? ?? '',
        statusLabel: j['status_label'] as String? ?? '',
        sellerType: j['seller_type'] as String?,
        storeName: j['store_name'] as String?,
        orderNo: j['order_no'] as String?,
        itemCount: _i(j['item_count']),
        storeAmount: _i(j['store_amount']),
        supplyAmount: _i(j['supply_amount']),
        confirmedAt: j['confirmed_at'] as String?,
        createdAt: j['created_at'] as String?,
        items: (j['items'] as List? ?? [])
            .map((e) => FulfillItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class SellerOrder {
  final int id;
  final String orderNo;
  final String status;
  final String statusLabel;
  final String? storeName;
  final int itemCount;
  final int storeAmount;
  final int supplyAmount;
  final String? createdAt;
  final String? note;
  final String? storeEmail;
  final bool isSample;
  final bool taxInvoiced;
  final bool statementEmailed;
  final int statementEmailCount;
  final bool hasPendingPrice;
  final List<FulfillItem> items;

  const SellerOrder({
    required this.id,
    required this.orderNo,
    required this.status,
    required this.statusLabel,
    required this.storeName,
    required this.itemCount,
    required this.storeAmount,
    required this.supplyAmount,
    required this.createdAt,
    required this.note,
    this.storeEmail,
    this.isSample = false,
    this.taxInvoiced = false,
    this.statementEmailed = false,
    this.statementEmailCount = 0,
    this.hasPendingPrice = false,
    required this.items,
  });

  factory SellerOrder.fromJson(Map<String, dynamic> j) => SellerOrder(
        id: j['id'] as int,
        orderNo: j['order_no'] as String? ?? '',
        status: j['status'] as String? ?? '',
        statusLabel: j['status_label'] as String? ?? '',
        storeName: j['store_name'] as String?,
        itemCount: _i(j['item_count']),
        storeAmount: _i(j['store_amount']),
        supplyAmount: _i(j['supply_amount']),
        createdAt: j['created_at'] as String?,
        note: j['note'] as String?,
        storeEmail: j['store_email'] as String?,
        isSample: j['is_sample'] as bool? ?? false,
        taxInvoiced: j['tax_invoiced'] as bool? ?? false,
        statementEmailed: j['statement_emailed'] as bool? ?? false,
        statementEmailCount: _i(j['statement_email_count']),
        hasPendingPrice: j['has_pending_price'] as bool? ?? false,
        items: (j['items'] as List? ?? [])
            .map((e) => FulfillItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class SellerShipment {
  final int id;
  final String shipmentNo;
  final String status;
  final String statusLabel;
  final String? storeName;
  final String? carrier;
  final String? trackingNo;
  final int itemCount;
  final int totalQty;
  final String? confirmedAt;
  final String? createdAt;
  final String? note;
  final List<FulfillItem> items;

  const SellerShipment({
    required this.id,
    required this.shipmentNo,
    required this.status,
    required this.statusLabel,
    required this.storeName,
    required this.carrier,
    required this.trackingNo,
    required this.itemCount,
    required this.totalQty,
    required this.confirmedAt,
    required this.createdAt,
    required this.note,
    required this.items,
  });

  factory SellerShipment.fromJson(Map<String, dynamic> j) => SellerShipment(
        id: j['id'] as int,
        shipmentNo: j['shipment_no'] as String? ?? '',
        status: j['status'] as String? ?? '',
        statusLabel: j['status_label'] as String? ?? '',
        storeName: j['store_name'] as String?,
        carrier: j['carrier'] as String?,
        trackingNo: j['tracking_no'] as String?,
        itemCount: _i(j['item_count']),
        totalQty: _i(j['total_qty']),
        confirmedAt: j['confirmed_at'] as String?,
        createdAt: j['created_at'] as String?,
        note: j['note'] as String?,
        items: (j['items'] as List? ?? [])
            .map((e) => FulfillItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class CandidateItem {
  final int id;
  final String productName;
  final String unit;
  final int qty;
  final String? orderNo;
  final String? salesOrderNo;

  const CandidateItem({
    required this.id,
    required this.productName,
    required this.unit,
    required this.qty,
    required this.orderNo,
    required this.salesOrderNo,
  });

  factory CandidateItem.fromJson(Map<String, dynamic> j) => CandidateItem(
        id: j['id'] as int,
        productName: j['product_name'] as String? ?? '',
        unit: j['unit'] as String? ?? '',
        qty: _i(j['qty']),
        orderNo: j['order_no'] as String?,
        salesOrderNo: j['sales_order_no'] as String?,
      );
}

class ManagedProduct {
  final int id;
  final String code;
  final String name;
  final String category;
  final String? spec;
  final String unit;
  final String supplyType; // hq | supplier
  final int? supplierId;
  final String? supplierName;
  final int supplyPrice;
  final int storePrice;
  final bool isMarketPrice;
  final bool isActive;
  final String approvalStatus; // approved | pending | rejected
  final String? approvalNote;

  const ManagedProduct({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.spec,
    required this.unit,
    required this.supplyType,
    required this.supplierId,
    required this.supplierName,
    required this.supplyPrice,
    required this.storePrice,
    required this.isMarketPrice,
    required this.isActive,
    required this.approvalStatus,
    required this.approvalNote,
  });

  factory ManagedProduct.fromJson(Map<String, dynamic> j) => ManagedProduct(
        id: j['id'] as int,
        code: j['code'] as String? ?? '',
        name: j['name'] as String? ?? '',
        category: j['category'] as String? ?? '',
        spec: j['spec'] as String?,
        unit: j['unit'] as String? ?? '',
        supplyType: j['supply_type'] as String? ?? 'hq',
        supplierId: j['supplier_id'] as int?,
        supplierName: j['supplier_name'] as String?,
        isMarketPrice: j['is_market_price'] as bool? ?? false,
        supplyPrice: _i(j['supply_price']),
        storePrice: _i(j['store_price']),
        isActive: j['is_active'] as bool? ?? true,
        approvalStatus: j['approval_status'] as String? ?? 'approved',
        approvalNote: j['approval_note'] as String?,
      );
}

class SupplierOption {
  final int id;
  final String name;
  const SupplierOption({required this.id, required this.name});
  factory SupplierOption.fromJson(Map<String, dynamic> j) =>
      SupplierOption(id: j['id'] as int, name: j['name'] as String? ?? '');
}

class ProductCategoryItem {
  final int id;
  final String name;
  final String code;
  final int sortOrder;
  final int productCount;
  const ProductCategoryItem({
    required this.id,
    required this.name,
    required this.code,
    required this.sortOrder,
    required this.productCount,
  });
  factory ProductCategoryItem.fromJson(Map<String, dynamic> j) => ProductCategoryItem(
        id: j['id'] as int,
        name: j['name'] as String? ?? '',
        code: j['code'] as String? ?? '',
        sortOrder: _i(j['sort_order']),
        productCount: _i(j['product_count']),
      );
}

class SupplierItem {
  final int id;
  final String name;
  final String? email;
  final String? ceo;
  final String? phone;
  final String? bizNo;
  final int productCount;
  final bool isActive;
  final bool joined;
  const SupplierItem({
    required this.id,
    required this.name,
    required this.email,
    required this.ceo,
    required this.phone,
    required this.bizNo,
    required this.productCount,
    required this.isActive,
    required this.joined,
  });
  factory SupplierItem.fromJson(Map<String, dynamic> j) => SupplierItem(
        id: j['id'] as int,
        name: j['name'] as String? ?? '',
        email: j['email'] as String?,
        ceo: j['ceo'] as String?,
        phone: j['phone'] as String?,
        bizNo: j['biz_no'] as String?,
        productCount: _i(j['product_count']),
        isActive: j['is_active'] as bool? ?? true,
        joined: j['joined'] as bool? ?? false,
      );
}

class StoreItem {
  final int id;
  final String name;
  final String? region;
  final String? email;
  final String? phone;
  final String? address;
  final bool isActive;
  final bool joined;
  const StoreItem({
    required this.id,
    required this.name,
    required this.region,
    required this.email,
    required this.phone,
    required this.address,
    required this.isActive,
    required this.joined,
  });
  factory StoreItem.fromJson(Map<String, dynamic> j) => StoreItem(
        id: j['id'] as int,
        name: j['name'] as String? ?? '',
        region: j['region'] as String?,
        email: j['email'] as String?,
        phone: j['phone'] as String?,
        address: j['address'] as String?,
        isActive: j['is_active'] as bool? ?? true,
        joined: j['joined'] as bool? ?? false,
      );
}

class PortalNoticeItem {
  final int id;
  final String title;
  final String? content;
  final String audience;
  final String audienceLabel;
  final bool isPinned;
  final String? author;
  final String? createdAt;
  const PortalNoticeItem({
    required this.id,
    required this.title,
    required this.content,
    required this.audience,
    required this.audienceLabel,
    required this.isPinned,
    required this.author,
    required this.createdAt,
  });
  factory PortalNoticeItem.fromJson(Map<String, dynamic> j) => PortalNoticeItem(
        id: j['id'] as int,
        title: j['title'] as String? ?? '',
        content: j['content'] as String?,
        audience: j['audience'] as String? ?? 'all',
        audienceLabel: j['audience_label'] as String? ?? '',
        isPinned: j['is_pinned'] as bool? ?? false,
        author: j['author'] as String?,
        createdAt: j['created_at'] as String?,
      );
}

class InquiryItem {
  final int id;
  final String name;
  final String? phone;
  final String? region;
  final String status;
  final String statusLabel;
  final String? createdAt;
  final String? message;
  final String? email;
  final String? budget;
  const InquiryItem({
    required this.id,
    required this.name,
    required this.phone,
    required this.region,
    required this.status,
    required this.statusLabel,
    required this.createdAt,
    required this.message,
    required this.email,
    required this.budget,
  });
  factory InquiryItem.fromJson(Map<String, dynamic> j) => InquiryItem(
        id: j['id'] as int,
        name: j['name'] as String? ?? '',
        phone: j['phone'] as String?,
        region: j['region'] as String?,
        status: j['status'] as String? ?? 'new',
        statusLabel: j['status_label'] as String? ?? '',
        createdAt: j['created_at'] as String?,
        message: j['message'] as String?,
        email: j['email'] as String?,
        budget: j['budget'] as String?,
      );
}

class SalesByStore {
  final String storeName;
  final String region;
  final int amount;
  final int qty;
  const SalesByStore(
      {required this.storeName, required this.region, required this.amount, required this.qty});
  factory SalesByStore.fromJson(Map<String, dynamic> j) => SalesByStore(
        storeName: j['store_name'] as String? ?? '',
        region: j['region'] as String? ?? '',
        amount: _i(j['amount']),
        qty: _i(j['qty']),
      );
}

class SalesReport {
  final String role;
  final String period;
  final String primaryLabel;
  final int primary;
  final String secondaryLabel;
  final int secondary;
  final String countLabel;
  final int count;
  final String qtyLabel;
  final List<SalesByStore> byStore;

  const SalesReport({
    required this.role,
    required this.period,
    required this.primaryLabel,
    required this.primary,
    required this.secondaryLabel,
    required this.secondary,
    required this.countLabel,
    required this.count,
    required this.qtyLabel,
    required this.byStore,
  });

  factory SalesReport.fromJson(Map<String, dynamic> j) => SalesReport(
        role: j['role'] as String? ?? '',
        period: j['period'] as String? ?? 'all',
        primaryLabel: j['primary_label'] as String? ?? '',
        primary: _i(j['primary']),
        secondaryLabel: j['secondary_label'] as String? ?? '',
        secondary: _i(j['secondary']),
        countLabel: j['count_label'] as String? ?? '',
        count: _i(j['count']),
        qtyLabel: j['qty_label'] as String? ?? '',
        byStore: (j['by_store'] as List? ?? [])
            .map((e) => SalesByStore.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class OrderChangeItem {
  final int id;
  final String orderNo;
  final String changeType; // updated | canceled
  final String typeLabel;
  final String? storeName;
  final String? summary;
  final bool acknowledged;
  final String? createdAt;

  const OrderChangeItem({
    required this.id,
    required this.orderNo,
    required this.changeType,
    required this.typeLabel,
    required this.storeName,
    required this.summary,
    required this.acknowledged,
    required this.createdAt,
  });

  factory OrderChangeItem.fromJson(Map<String, dynamic> j) => OrderChangeItem(
        id: j['id'] as int,
        orderNo: j['order_no'] as String? ?? '',
        changeType: j['change_type'] as String? ?? '',
        typeLabel: j['type_label'] as String? ?? '',
        storeName: j['store_name'] as String?,
        summary: j['summary'] as String?,
        acknowledged: j['acknowledged'] as bool? ?? false,
        createdAt: j['created_at'] as String?,
      );
}

class CandidateGroup {
  final int storeId;
  final String? storeName;
  final List<CandidateItem> items;

  const CandidateGroup({
    required this.storeId,
    required this.storeName,
    required this.items,
  });

  factory CandidateGroup.fromJson(Map<String, dynamic> j) => CandidateGroup(
        storeId: _i(j['store_id']),
        storeName: j['store_name'] as String?,
        items: (j['items'] as List? ?? [])
            .map((e) => CandidateItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
