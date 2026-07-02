// 본사/공급처 전자문서 모델 — 세금계산서·거래명세서.

int _int(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}') ?? 0;
String? _str(dynamic v) => v == null ? null : '$v';

/// 세금계산서 한 줄 품목.
class EDocLine {
  EDocLine({
    required this.name,
    required this.unit,
    required this.qty,
    required this.unitPrice,
    required this.amount,
  });
  final String name;
  final String unit;
  final int qty;
  final int unitPrice;
  final int amount;

  factory EDocLine.fromJson(Map<String, dynamic> j) => EDocLine(
        name: j['name']?.toString() ?? '-',
        unit: (j['spec'] ?? j['unit'])?.toString() ?? '',
        qty: _int(j['qty']),
        unitPrice: _int(j['unit_price']),
        amount: _int(j['amount']),
      );
}

/// 세금계산서 (요약 + 상세 공용).
class SellerTaxInvoice {
  SellerTaxInvoice({
    required this.id,
    required this.invoiceNo,
    required this.direction,
    required this.directionLabel,
    required this.counterpartyName,
    required this.invoicerName,
    required this.supplyAmount,
    required this.vat,
    required this.totalAmount,
    required this.status,
    required this.statusLabel,
    required this.note,
    this.ntsConfirmNum,
    this.issueDate,
    this.invoicerCorpNum,
    this.invoiceeCorpNum,
    this.invoiceeCorpName,
    this.invoiceeEmail,
    this.canCancel = false,
    this.lineItems = const [],
  });

  final int id;
  final String invoiceNo;
  final String direction;
  final String directionLabel;
  final String? counterpartyName;
  final String? invoicerName;
  final int supplyAmount;
  final int vat;
  final int totalAmount;
  final String status;
  final String statusLabel;
  final String? note;
  final String? ntsConfirmNum;
  final String? issueDate;
  final String? invoicerCorpNum;
  final String? invoiceeCorpNum;
  final String? invoiceeCorpName;
  final String? invoiceeEmail;
  final bool canCancel;
  final List<EDocLine> lineItems;

  bool get isCanceled => status == 'canceled';

  factory SellerTaxInvoice.fromJson(Map<String, dynamic> j) => SellerTaxInvoice(
        id: _int(j['id']),
        invoiceNo: j['invoice_no']?.toString() ?? '',
        direction: j['direction']?.toString() ?? '',
        directionLabel: j['direction_label']?.toString() ?? '',
        counterpartyName: _str(j['counterparty_name']),
        invoicerName: _str(j['invoicer_name']),
        supplyAmount: _int(j['supply_amount']),
        vat: _int(j['vat']),
        totalAmount: _int(j['total_amount']),
        status: j['status']?.toString() ?? 'issued',
        statusLabel: j['status_label']?.toString() ?? '',
        note: _str(j['note']),
        ntsConfirmNum: _str(j['nts_confirm_num']),
        issueDate: _str(j['issue_date']),
        invoicerCorpNum: _str(j['invoicer_corp_num']),
        invoiceeCorpNum: _str(j['invoicee_corp_num']),
        invoiceeCorpName: _str(j['invoicee_corp_name']),
        invoiceeEmail: _str(j['invoicee_email']),
        canCancel: j['can_cancel'] == true,
        lineItems: (j['line_items'] as List? ?? [])
            .map((e) => EDocLine.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// 발행 대상 매장 (본사).
class IssuableStore {
  IssuableStore({required this.id, required this.name, required this.hasBizNo, this.bizNo});
  final int id;
  final String name;
  final bool hasBizNo;
  final String? bizNo;

  factory IssuableStore.fromJson(Map<String, dynamic> j) => IssuableStore(
        id: _int(j['id']),
        name: j['name']?.toString() ?? '',
        hasBizNo: j['has_biz_no'] == true,
        bizNo: _str(j['biz_no']),
      );
}

/// 발행 대상 발주 (본사).
class IssuableOrder {
  IssuableOrder({
    required this.id,
    required this.orderNo,
    required this.itemCount,
    required this.amount,
    this.createdAt,
  });
  final int id;
  final String orderNo;
  final int itemCount;
  final int amount;
  final String? createdAt;

  factory IssuableOrder.fromJson(Map<String, dynamic> j) => IssuableOrder(
        id: _int(j['id']),
        orderNo: j['order_no']?.toString() ?? '',
        itemCount: _int(j['item_count']),
        amount: _int(j['amount']),
        createdAt: _str(j['created_at']),
      );
}

/// 발행 대상 품목 (공급처).
class IssuableItem {
  IssuableItem({
    required this.id,
    required this.productName,
    required this.unit,
    required this.qty,
    required this.amount,
    this.orderNo,
    this.storeName,
  });
  final int id;
  final String productName;
  final String unit;
  final int qty;
  final int amount;
  final String? orderNo;
  final String? storeName;

  factory IssuableItem.fromJson(Map<String, dynamic> j) => IssuableItem(
        id: _int(j['id']),
        productName: j['product_name']?.toString() ?? '',
        unit: j['unit']?.toString() ?? '',
        qty: _int(j['qty']),
        amount: _int(j['amount']),
        orderNo: _str(j['order_no']),
        storeName: _str(j['store_name']),
      );
}

/// 발행 대상 묶음 (본사: orders / 공급처: items).
class IssuableData {
  IssuableData({required this.mode, this.store, this.orders = const [], this.items = const []});
  final String mode; // 'orders' | 'items'
  final IssuableStore? store;
  final List<IssuableOrder> orders;
  final List<IssuableItem> items;

  factory IssuableData.fromJson(Map<String, dynamic> j) => IssuableData(
        mode: j['mode']?.toString() ?? 'orders',
        store: j['store'] == null ? null : IssuableStore.fromJson(j['store'] as Map<String, dynamic>),
        orders: (j['orders'] as List? ?? [])
            .map((e) => IssuableOrder.fromJson(e as Map<String, dynamic>))
            .toList(),
        items: (j['items'] as List? ?? [])
            .map((e) => IssuableItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// 거래명세서 이력 항목.
class StatementListItem {
  StatementListItem({
    required this.id,
    required this.title,
    required this.sub,
    required this.itemCount,
    required this.total,
    required this.invoiced,
    this.date,
    this.emailed = false,
    this.resendCount = 0,
  });
  final int id;
  final String title;
  final String? sub;
  final int itemCount;
  final int total;
  final bool invoiced;
  final String? date;
  final bool emailed;
  final int resendCount;

  factory StatementListItem.fromJson(Map<String, dynamic> j) => StatementListItem(
        id: _int(j['id']),
        title: j['title']?.toString() ?? '',
        sub: _str(j['sub']),
        itemCount: _int(j['item_count']),
        total: _int(j['total']),
        invoiced: j['invoiced'] == true,
        date: _str(j['date']),
        emailed: j['emailed'] == true,
        resendCount: _int(j['resend_count']),
      );
}

/// 거래명세서 상세.
class StatementDetail {
  StatementDetail({
    required this.role,
    required this.id,
    required this.title,
    required this.total,
    required this.invoiced,
    required this.canResend,
    required this.canIssue,
    required this.items,
    this.email,
    this.date,
    this.supplyTotal,
    this.vat,
    this.emailed = false,
  });
  final String role;
  final int id;
  final String title;
  final int total;
  final bool invoiced;
  final bool canResend;
  final bool canIssue;
  final List<EDocLine> items;
  final String? email;
  final String? date;
  final int? supplyTotal;
  final int? vat;
  final bool emailed;

  factory StatementDetail.fromJson(Map<String, dynamic> j) => StatementDetail(
        role: j['role']?.toString() ?? 'hq',
        id: _int(j['id']),
        title: j['title']?.toString() ?? '',
        total: _int(j['total']),
        invoiced: j['invoiced'] == true,
        canResend: j['can_resend'] == true,
        canIssue: j['can_issue'] == true,
        items: (j['items'] as List? ?? [])
            .map((e) => EDocLine.fromJson(e as Map<String, dynamic>))
            .toList(),
        email: _str(j['email']),
        date: _str(j['date']),
        supplyTotal: j['supply_total'] == null ? null : _int(j['supply_total']),
        vat: j['vat'] == null ? null : _int(j['vat']),
        emailed: j['emailed'] == true,
      );
}

/// 거래명세서 작성용 매장 (본사).
class CatalogStore {
  CatalogStore({required this.id, required this.name, required this.hasEmail, this.email});
  final int id;
  final String name;
  final bool hasEmail;
  final String? email;

  factory CatalogStore.fromJson(Map<String, dynamic> j) => CatalogStore(
        id: _int(j['id']),
        name: j['name']?.toString() ?? '',
        hasEmail: j['has_email'] == true,
        email: _str(j['email']),
      );
}

/// 거래명세서 작성용 품목.
class CatalogProduct {
  CatalogProduct({
    required this.id,
    required this.name,
    required this.unit,
    required this.price,
    this.code,
    this.category,
  });
  final int id;
  final String name;
  final String unit;
  final int price;
  final String? code;
  final String? category;

  factory CatalogProduct.fromJson(Map<String, dynamic> j) => CatalogProduct(
        id: _int(j['id']),
        name: j['name']?.toString() ?? '',
        unit: j['unit']?.toString() ?? '',
        price: _int(j['price']),
        code: _str(j['code']),
        category: _str(j['category']),
      );
}

/// 공급사 판매주문 (본사 — 공급사 발주 현황).
class SupplierSalesOrder {
  SupplierSalesOrder({
    required this.id,
    required this.salesOrderNo,
    required this.status,
    required this.statusLabel,
    required this.supplierName,
    required this.itemCount,
    required this.storeAmount,
    required this.supplyAmount,
    this.storeName,
    this.orderNo,
    this.createdAt,
    this.confirmedAt,
    this.items = const [],
  });
  final int id;
  final String salesOrderNo;
  final String status;
  final String statusLabel;
  final String supplierName;
  final int itemCount;
  final int storeAmount;
  final int supplyAmount;
  final String? storeName;
  final String? orderNo;
  final String? createdAt;
  final String? confirmedAt;
  final List<SupplierSalesItem> items;

  factory SupplierSalesOrder.fromJson(Map<String, dynamic> j) => SupplierSalesOrder(
        id: _int(j['id']),
        salesOrderNo: j['sales_order_no']?.toString() ?? '',
        status: j['status']?.toString() ?? '',
        statusLabel: j['status_label']?.toString() ?? '',
        supplierName: j['supplier_name']?.toString() ?? '공급처',
        itemCount: _int(j['item_count']),
        storeAmount: _int(j['store_amount']),
        supplyAmount: _int(j['supply_amount']),
        storeName: _str(j['store_name']),
        orderNo: _str(j['order_no']),
        createdAt: _str(j['created_at']),
        confirmedAt: _str(j['confirmed_at']),
        items: (j['items'] as List? ?? [])
            .map((e) => SupplierSalesItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// 공급사 판매주문 품목.
class SupplierSalesItem {
  SupplierSalesItem({
    required this.id,
    required this.productName,
    required this.unit,
    required this.qty,
    required this.supplyLineAmount,
    required this.fulfillmentStatus,
    this.imageUrl,
  });
  final int id;
  final String productName;
  final String unit;
  final int qty;
  final int supplyLineAmount;
  final String fulfillmentStatus;
  final String? imageUrl;

  factory SupplierSalesItem.fromJson(Map<String, dynamic> j) => SupplierSalesItem(
        id: _int(j['id']),
        productName: j['product_name']?.toString() ?? '',
        unit: j['unit']?.toString() ?? '',
        qty: _int(j['qty']),
        supplyLineAmount: _int(j['supply_line_amount']),
        fulfillmentStatus: j['fulfillment_status']?.toString() ?? '',
        imageUrl: j['image']?.toString(),
      );
}

/// 옵션(공급처/상태 필터).
class EDocFilterOption {
  EDocFilterOption({required this.key, required this.label});
  final String key;
  final String label;

  factory EDocFilterOption.fromJson(Map<String, dynamic> j) => EDocFilterOption(
        key: (j['key'] ?? j['id']).toString(),
        label: j['label']?.toString() ?? j['name']?.toString() ?? '',
      );
}

/// 공급사 발주 현황 묶음 (목록 + 필터 + 합계).
class SupplierOrdersResult {
  SupplierOrdersResult({
    required this.orders,
    required this.suppliers,
    required this.statuses,
    required this.totalSupply,
    required this.supplier,
    required this.status,
    this.hasMore = false,
  });
  final List<SupplierSalesOrder> orders;
  final List<EDocFilterOption> suppliers;
  final List<EDocFilterOption> statuses;
  final int totalSupply;
  final String supplier;
  final String status;
  final bool hasMore;
}

/// 거래명세서 작성용 카탈로그 묶음.
class StatementCatalog {
  StatementCatalog({required this.role, required this.stores, required this.catalog});
  final String role;
  final List<CatalogStore> stores;
  final List<CatalogProduct> catalog;

  factory StatementCatalog.fromJson(Map<String, dynamic> j) => StatementCatalog(
        role: j['role']?.toString() ?? 'hq',
        stores: (j['stores'] as List? ?? [])
            .map((e) => CatalogStore.fromJson(e as Map<String, dynamic>))
            .toList(),
        catalog: (j['catalog'] as List? ?? [])
            .map((e) => CatalogProduct.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
