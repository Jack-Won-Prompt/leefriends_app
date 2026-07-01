import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/edocs.dart';
import '../models/fulfillment.dart';
import '../models/paged.dart';
import 'api_config.dart';
import 'auth_controller.dart';
import 'order_repository.dart' show OrderException;

/// 본사/공급처(판매자) 발주처리·출고 API 클라이언트.
class SellerRepository {
  SellerRepository({required this.auth, http.Client? client})
      : _client = client ?? http.Client();

  final AuthController auth;
  final http.Client _client;

  Future<SellerDashboard> dashboard() async {
    final body = await _get('/seller/dashboard');
    return SellerDashboard.fromJson(body['data'] as Map<String, dynamic>);
  }

  // 받은 발주
  Future<({List<SellerOrder> orders, List<StatusOption> statuses, bool hasMore})> orders(
      {String status = 'all', int page = 1}) async {
    final body = await _get('/seller/orders?status=$status&page=$page');
    return (
      orders: (body['data'] as List)
          .map((e) => SellerOrder.fromJson(e as Map<String, dynamic>))
          .toList(),
      statuses: _statuses(body),
      hasMore: Paged.hasMoreFromMeta(body['meta'] as Map<String, dynamic>?),
    );
  }

  Future<SellerOrder> orderDetail(int id) async {
    final body = await _get('/seller/orders/$id');
    return SellerOrder.fromJson(body['data'] as Map<String, dynamic>);
  }

  // 판매주문
  Future<({List<SellerSalesOrder> orders, List<StatusOption> statuses, bool hasMore})>
      salesOrders({String status = 'all', int page = 1}) async {
    final body = await _get('/seller/sales-orders?status=$status&page=$page');
    return (
      orders: (body['data'] as List)
          .map((e) => SellerSalesOrder.fromJson(e as Map<String, dynamic>))
          .toList(),
      statuses: _statuses(body),
      hasMore: Paged.hasMoreFromMeta(body['meta'] as Map<String, dynamic>?),
    );
  }

  Future<SellerSalesOrder> salesOrderDetail(int id) async {
    final body = await _get('/seller/sales-orders/$id');
    return SellerSalesOrder.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<String> confirmSalesOrder(int id) async {
    final body = await _patch('/seller/sales-orders/$id/confirm', {});
    return body['message'] as String? ?? '확인되었습니다.';
  }

  // 본사 직공급 품목 배송상태 처리 (본사 전용)
  Future<String> updateOrderItem(int orderId, int itemId, String status) async {
    final body = await _patch(
        '/seller/orders/$orderId/items/$itemId', {'fulfillment_status': status});
    return body['message'] as String? ?? '변경되었습니다.';
  }

  // 싯가 품목 단가 확정 (본사 전용)
  Future<String> setItemPrice(int orderId, int itemId, int storeUnitPrice) async {
    final body = await _patch(
        '/seller/orders/$orderId/items/$itemId/price', {'store_unit_price': storeUnitPrice});
    return body['message'] as String? ?? '단가를 확정했습니다.';
  }

  // 이 발주로 세금계산서 발행 (본사 → 매장)
  Future<String> issueOrderTaxInvoice(int orderId) async {
    final body = await _post('/seller/orders/$orderId/tax-invoice', {}, expect: 201);
    return body['message'] as String? ?? '세금계산서를 발행했습니다.';
  }

  // 발주 거래명세서 PDF를 매장 이메일로 전송 (본사)
  Future<String> emailOrderStatement(int orderId) async {
    final body = await _post('/seller/orders/$orderId/statement-email', {});
    return body['message'] as String? ?? '거래명세서를 전송했습니다.';
  }

  // 매장에 입금요청 SMS 전송 + 주문 접수 처리 (본사)
  Future<String> sendPaymentRequestSms(int orderId) async {
    final body = await _post('/seller/orders/$orderId/payment-request', {});
    return body['message'] as String? ?? '입금요청 SMS를 전송했습니다.';
  }

  // 품목 공급가/출고가/수량 수정 (본사)
  Future<String> editOrderItem(
      int orderId, int itemId, int supplyUnitPrice, int storeUnitPrice, int qty) async {
    final body = await _patch('/seller/orders/$orderId/items/$itemId/edit', {
      'supply_unit_price': supplyUnitPrice,
      'store_unit_price': storeUnitPrice,
      'qty': qty,
    });
    return body['message'] as String? ?? '품목을 수정했습니다.';
  }

  // 택배비(박스·단가) 등록/수정 (본사)
  Future<String> updateOrderShipping(int orderId, int boxCount, int unitPrice) async {
    final body = await _patch('/seller/orders/$orderId/shipping',
        {'shipping_box_count': boxCount, 'shipping_unit_price': unitPrice});
    return body['message'] as String? ?? '택배비를 저장했습니다.';
  }

  // 매장 주문 변경 확인(반영)
  Future<({List<OrderChangeItem> changes, int pending})> orderChanges() async {
    final body = await _get('/seller/order-changes');
    final list = (body['data'] as List)
        .map((e) => OrderChangeItem.fromJson(e as Map<String, dynamic>))
        .toList();
    final pending = (body['meta']?['pending'] as num?)?.toInt() ?? 0;
    return (changes: list, pending: pending);
  }

  Future<void> ackChange(int id) => _post('/seller/order-changes/$id/ack', {});
  Future<void> ackAllChanges() => _post('/seller/order-changes/ack-all', {});

  // 매출 현황
  Future<SalesReport> sales({String period = 'all'}) async {
    final body = await _get('/seller/sales?period=$period');
    return SalesReport.fromJson(body['data'] as Map<String, dynamic>);
  }

  // 상품 관리
  Future<({List<ManagedProduct> products, List<String> categories, List<SupplierOption> suppliers, String role})>
      products({String q = '', String approval = 'all'}) async {
    final body = await _get('/seller/products?q=${Uri.encodeQueryComponent(q)}&approval=$approval');
    return (
      products: (body['data'] as List).map((e) => ManagedProduct.fromJson(e as Map<String, dynamic>)).toList(),
      categories: (body['meta']?['categories'] as List? ?? []).map((e) => e.toString()).toList(),
      suppliers: (body['meta']?['suppliers'] as List? ?? [])
          .map((e) => SupplierOption.fromJson(e as Map<String, dynamic>)).toList(),
      role: body['meta']?['role'] as String? ?? 'hq',
    );
  }

  Future<String> saveProduct(Map<String, dynamic> data, {int? id}) async {
    final body = id == null
        ? await _post('/seller/products', data, expect: 201)
        : await _put('/seller/products/$id', data);
    return body['message'] as String? ?? '저장되었습니다.';
  }

  Future<String> deleteProduct(int id) async {
    final body = await _delete('/seller/products/$id');
    return body['message'] as String? ?? '삭제되었습니다.';
  }

  Future<String> approveProduct(int id, int storePrice) async {
    final body = await _patch('/seller/products/$id/approve', {'store_price': storePrice});
    return body['message'] as String? ?? '승인되었습니다.';
  }

  Future<String> rejectProduct(int id, String? note) async {
    final body = await _patch('/seller/products/$id/reject', {'approval_note': ?note});
    return body['message'] as String? ?? '반려되었습니다.';
  }

  // 카테고리 관리
  Future<List<ProductCategoryItem>> categories() async {
    final body = await _get('/seller/categories');
    return (body['data'] as List).map((e) => ProductCategoryItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<String> saveCategory(Map<String, dynamic> data, {int? id}) async {
    final body = id == null
        ? await _post('/seller/categories', data, expect: 201)
        : await _put('/seller/categories/$id', data);
    return body['message'] as String? ?? '저장되었습니다.';
  }

  Future<String> deleteCategory(int id) async {
    final body = await _delete('/seller/categories/$id');
    return body['message'] as String? ?? '삭제되었습니다.';
  }

  // 공급처 관리
  Future<List<SupplierItem>> suppliers() async {
    final body = await _get('/seller/suppliers');
    return (body['data'] as List).map((e) => SupplierItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<String> inviteSupplier(Map<String, dynamic> data) async =>
      (await _post('/seller/suppliers/invite', data, expect: 201))['message'] as String? ?? '초대했습니다.';
  Future<String> updateSupplier(int id, Map<String, dynamic> data) async =>
      (await _put('/seller/suppliers/$id', data))['message'] as String? ?? '수정되었습니다.';
  Future<String> deleteSupplier(int id) async =>
      (await _delete('/seller/suppliers/$id'))['message'] as String? ?? '삭제되었습니다.';
  Future<String> reinviteSupplier(int id) async =>
      (await _post('/seller/suppliers/$id/reinvite', {}))['message'] as String? ?? '재발송했습니다.';

  // 매장 관리
  Future<List<StoreItem>> stores() async {
    final body = await _get('/seller/stores');
    return (body['data'] as List).map((e) => StoreItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<String> inviteStore(Map<String, dynamic> data) async =>
      (await _post('/seller/stores/invite', data, expect: 201))['message'] as String? ?? '초대했습니다.';
  Future<String> updateStore(int id, Map<String, dynamic> data) async =>
      (await _put('/seller/stores/$id', data))['message'] as String? ?? '수정되었습니다.';
  Future<String> reinviteStore(int id) async =>
      (await _post('/seller/stores/$id/reinvite', {}))['message'] as String? ?? '재발송했습니다.';

  // 공지 관리
  Future<({List<PortalNoticeItem> notices, List<({String key, String label})> audiences})> portalNotices() async {
    final body = await _get('/seller/notices');
    final list = (body['data'] as List).map((e) => PortalNoticeItem.fromJson(e as Map<String, dynamic>)).toList();
    final aud = (body['meta']?['audiences'] as List? ?? [])
        .map((e) => (key: e['key'] as String, label: e['label'] as String)).toList();
    return (notices: list, audiences: aud);
  }

  Future<String> createNotice(Map<String, dynamic> data) async =>
      (await _post('/seller/notices', data, expect: 201))['message'] as String? ?? '발송했습니다.';
  Future<String> deleteNotice(int id) async =>
      (await _delete('/seller/notices/$id'))['message'] as String? ?? '삭제되었습니다.';

  // 가맹문의
  Future<({List<InquiryItem> inquiries, int newCount})> inquiries({String status = 'all'}) async {
    final body = await _get('/seller/inquiries?status=$status');
    final list = (body['data'] as List).map((e) => InquiryItem.fromJson(e as Map<String, dynamic>)).toList();
    return (inquiries: list, newCount: (body['meta']?['new_count'] as num?)?.toInt() ?? 0);
  }

  Future<InquiryItem> inquiryDetail(int id) async {
    final body = await _get('/seller/inquiries/$id');
    return InquiryItem.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<String> updateInquiry(int id, String status) async =>
      (await _patch('/seller/inquiries/$id', {'status': status}))['message'] as String? ?? '변경되었습니다.';
  Future<String> deleteInquiry(int id) async =>
      (await _delete('/seller/inquiries/$id'))['message'] as String? ?? '삭제되었습니다.';

  // 출고
  Future<({List<SellerShipment> shipments, List<StatusOption> statuses, bool hasMore})>
      shipments({String status = 'all', int page = 1}) async {
    final body = await _get('/seller/shipments?status=$status&page=$page');
    return (
      shipments: (body['data'] as List)
          .map((e) => SellerShipment.fromJson(e as Map<String, dynamic>))
          .toList(),
      statuses: _statuses(body),
      hasMore: Paged.hasMoreFromMeta(body['meta'] as Map<String, dynamic>?),
    );
  }

  Future<SellerShipment> shipmentDetail(int id) async {
    final body = await _get('/seller/shipments/$id');
    return SellerShipment.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<List<CandidateGroup>> shipmentCandidates() async {
    final body = await _get('/seller/shipments/candidates');
    return (body['data'] as List)
        .map((e) => CandidateGroup.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SellerShipment> createShipment({
    required int storeId,
    required List<int> itemIds,
    String? note,
  }) async {
    final body = await _post('/seller/shipments', {
      'store_id': storeId,
      'items': itemIds,
      'note': ?note,
    }, expect: 201);
    return SellerShipment.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// 택배사 목록 (출고 확정 드롭다운용, 직접 배송 포함).
  Future<List<CarrierOption>> couriers() async {
    final body = await _get('/seller/couriers');
    return (body['data'] as List)
        .map((e) => CarrierOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SellerShipment> confirmShipment(
      int id, String carrier, String trackingNo) async {
    final body = await _patch('/seller/shipments/$id/confirm', {
      'carrier': carrier,
      'tracking_no': trackingNo,
    });
    return SellerShipment.fromJson(body['data'] as Map<String, dynamic>);
  }

  // ============ 전자세금계산서 ============
  Future<Paged<SellerTaxInvoice>> taxInvoices({int page = 1}) async {
    final body = await _get('/seller/tax-invoices?page=$page');
    return Paged(
      items: (body['data'] as List)
          .map((e) => SellerTaxInvoice.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore: Paged.hasMoreFromMeta(body['meta'] as Map<String, dynamic>?),
    );
  }

  Future<SellerTaxInvoice> taxInvoiceDetail(int id) async {
    final body = await _get('/seller/tax-invoices/$id');
    return SellerTaxInvoice.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// (본사) 발행 대상 매장 목록.
  Future<List<IssuableStore>> issuableStores() async {
    final body = await _get('/seller/tax-invoices/stores');
    return (body['data'] as List)
        .map((e) => IssuableStore.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 발행 대상 — 본사: storeId 필수(미발행 발주), 공급처: 배송완료·미청구 품목.
  Future<IssuableData> taxInvoiceIssuable({int? storeId, String? from, String? to}) async {
    final qp = <String, String>{};
    if (storeId != null) qp['store_id'] = '$storeId';
    if (from != null && from.isNotEmpty) qp['from'] = from;
    if (to != null && to.isNotEmpty) qp['to'] = to;
    final query = qp.isEmpty
        ? ''
        : '?${qp.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&')}';
    final body = await _get('/seller/tax-invoices/issuable$query');
    return IssuableData.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// 발행 — 본사: {store_id, order_ids}, 공급처: {item_ids}.
  Future<String> issueTaxInvoice({
    int? storeId,
    List<int>? orderIds,
    List<int>? itemIds,
  }) async {
    final payload = <String, dynamic>{};
    if (storeId != null) payload['store_id'] = storeId;
    if (orderIds != null) payload['order_ids'] = orderIds;
    if (itemIds != null) payload['item_ids'] = itemIds;
    final body = await _post('/seller/tax-invoices/issue', payload, expect: 201);
    return body['message'] as String? ?? '발행되었습니다.';
  }

  Future<String> cancelTaxInvoice(int id, {String? memo}) async {
    final body = await _post('/seller/tax-invoices/$id/cancel', {'memo': ?memo});
    return body['message'] as String? ?? '발행취소되었습니다.';
  }

  // ============ 거래명세서 ============
  Future<({String role, List<StatementListItem> statements, bool hasMore})> statements(
      {int page = 1}) async {
    final body = await _get('/seller/statements?page=$page');
    final data = body['data'] as Map<String, dynamic>;
    return (
      role: data['role'] as String? ?? 'hq',
      statements: (data['statements'] as List)
          .map((e) => StatementListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore: Paged.hasMoreFromMeta(body['meta'] as Map<String, dynamic>?),
    );
  }

  Future<StatementDetail> statementDetail(int id) async {
    final body = await _get('/seller/statements/$id');
    return StatementDetail.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<StatementCatalog> statementCatalog() async {
    final body = await _get('/seller/statements/catalog');
    return StatementCatalog.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// 작성/전송 — 본사: {store_id, items}, 공급처: {items, send}.
  Future<String> createStatement({
    int? storeId,
    required List<Map<String, int>> items,
    bool send = false,
  }) async {
    final payload = <String, dynamic>{'items': items};
    if (storeId != null) payload['store_id'] = storeId;
    if (send) payload['send'] = true;
    final body = await _post('/seller/statements', payload, expect: 201);
    return body['message'] as String? ?? '처리되었습니다.';
  }

  Future<String> sendStatement(int id) async {
    final body = await _post('/seller/statements/$id/send', {});
    return body['message'] as String? ?? '전송되었습니다.';
  }

  Future<String> issueStatement(int id) async {
    final body = await _post('/seller/statements/$id/issue', {}, expect: 201);
    return body['message'] as String? ?? '발행되었습니다.';
  }

  // ============ 공급사 발주 현황 (본사) ============
  Future<SupplierOrdersResult> supplierOrders(
      {String supplier = 'all', String status = 'all', int page = 1}) async {
    final body = await _get('/seller/supplier-orders?supplier=$supplier&status=$status&page=$page');
    final meta = body['meta'] as Map<String, dynamic>? ?? {};
    return SupplierOrdersResult(
      orders: (body['data'] as List)
          .map((e) => SupplierSalesOrder.fromJson(e as Map<String, dynamic>))
          .toList(),
      suppliers: (meta['suppliers'] as List? ?? [])
          .map((e) => EDocFilterOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      statuses: (meta['statuses'] as List? ?? [])
          .map((e) => EDocFilterOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalSupply: (meta['total_supply'] as num?)?.toInt() ?? 0,
      supplier: meta['supplier']?.toString() ?? 'all',
      status: meta['status']?.toString() ?? 'all',
      hasMore: Paged.hasMoreFromMeta(meta),
    );
  }

  Future<SupplierSalesOrder> supplierOrderDetail(int id) async {
    final body = await _get('/seller/supplier-orders/$id');
    return SupplierSalesOrder.fromJson(body['data'] as Map<String, dynamic>);
  }

  // ---- helpers ----
  List<StatusOption> _statuses(Map<String, dynamic> body) =>
      (body['meta']?['statuses'] as List? ?? [])
          .map((e) => StatusOption.fromJson(e as Map<String, dynamic>))
          .toList();

  Future<Map<String, dynamic>> _get(String path) async {
    final res = await _client
        .get(Uri.parse('${ApiConfig.apiUrl}$path'), headers: auth.authHeaders)
        .timeout(ApiConfig.timeout);
    if (res.statusCode != 200) {
      throw OrderException(_error(_decode(res), res.statusCode));
    }
    return _decode(res);
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body,
      {int expect = 200}) async {
    final res = await _client
        .post(Uri.parse('${ApiConfig.apiUrl}$path'),
            headers: {...auth.authHeaders, 'Content-Type': 'application/json'},
            body: jsonEncode(body))
        .timeout(ApiConfig.timeout);
    if (res.statusCode != expect && res.statusCode != 200) {
      throw OrderException(_error(_decode(res), res.statusCode));
    }
    return _decode(res);
  }

  Future<Map<String, dynamic>> _patch(String path, Map<String, dynamic> body) async {
    final res = await _client
        .patch(Uri.parse('${ApiConfig.apiUrl}$path'),
            headers: {...auth.authHeaders, 'Content-Type': 'application/json'},
            body: jsonEncode(body))
        .timeout(ApiConfig.timeout);
    if (res.statusCode != 200) {
      throw OrderException(_error(_decode(res), res.statusCode));
    }
    return _decode(res);
  }

  Future<Map<String, dynamic>> _put(String path, Map<String, dynamic> body) async {
    final res = await _client
        .put(Uri.parse('${ApiConfig.apiUrl}$path'),
            headers: {...auth.authHeaders, 'Content-Type': 'application/json'},
            body: jsonEncode(body))
        .timeout(ApiConfig.timeout);
    if (res.statusCode != 200) {
      throw OrderException(_error(_decode(res), res.statusCode));
    }
    return _decode(res);
  }

  Future<Map<String, dynamic>> _delete(String path) async {
    final res = await _client
        .delete(Uri.parse('${ApiConfig.apiUrl}$path'), headers: auth.authHeaders)
        .timeout(ApiConfig.timeout);
    if (res.statusCode != 200) {
      throw OrderException(_error(_decode(res), res.statusCode));
    }
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    try {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  String _error(Map<String, dynamic> body, int status) {
    final errors = body['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
    }
    if (body['message'] is String) return body['message'] as String;
    if (status == 401) return '로그인이 필요합니다.';
    if (status == 403) return '접근 권한이 없습니다.';
    return '요청을 처리하지 못했습니다 ($status).';
  }
}
