import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/paged.dart';
import '../models/store_ops.dart';
import 'api_config.dart';
import 'auth_controller.dart';
import 'order_repository.dart' show OrderException;

/// 매장 운영(매입·입고·재고·알림) API 클라이언트. 토큰 인증 필요.
class StoreOpsRepository {
  StoreOpsRepository({required this.auth, http.Client? client})
      : _client = client ?? http.Client();

  final AuthController auth;
  final http.Client _client;

  // ---- 매장 대시보드 ----
  Future<StoreDashboard> dashboard() async {
    final body = await _get('/store/dashboard');
    return StoreDashboard.fromJson(body['data'] as Map<String, dynamic>);
  }

  // ---- 매장 세금계산서 (조회) ----
  Future<Paged<StoreTaxInvoice>> taxInvoices({int page = 1}) async {
    final body = await _get('/store/tax-invoices?page=$page');
    return Paged(
      items: (body['data'] as List)
          .map((e) => StoreTaxInvoice.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore: Paged.hasMoreFromMeta(body['meta'] as Map<String, dynamic>?),
    );
  }

  Future<StoreTaxInvoice> taxInvoiceDetail(int id) async {
    final body = await _get('/store/tax-invoices/$id');
    return StoreTaxInvoice.fromJson(body['data'] as Map<String, dynamic>);
  }

  // ---- 매입 ----
  Future<PurchaseSummary> purchases({String period = 'all', int page = 1}) async {
    final body = await _get('/purchases?period=$period&page=$page');
    return PurchaseSummary.fromJson(body);
  }

  // ---- 입고 ----
  Future<({List<InboundExpected> expected, List<ShipmentModel> inTransit})>
      inbound() async {
    final body = await _get('/inbound');
    final expected = (body['expected'] as List? ?? [])
        .map((e) => InboundExpected.fromJson(e as Map<String, dynamic>))
        .toList();
    final inTransit = (body['in_transit'] as List? ?? [])
        .map((e) => ShipmentModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return (expected: expected, inTransit: inTransit);
  }

  Future<ShipmentModel> shipmentDetail(int id) async {
    final body = await _get('/shipments/$id');
    return ShipmentModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<ShipmentModel> receive(int shipmentId) async {
    final body = await _post('/shipments/$shipmentId/receive', {});
    return ShipmentModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  // ---- 재고 ----
  Future<List<InventoryItem>> inventory({String? q}) async {
    final path = (q == null || q.isEmpty)
        ? '/inventory'
        : '/inventory?q=${Uri.encodeQueryComponent(q)}';
    final body = await _get(path);
    return (body['data'] as List)
        .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<InventoryMovementItem>> movements({String type = 'all'}) async {
    final body = await _get('/inventory/movements?type=$type');
    return (body['data'] as List)
        .map((e) => InventoryMovementItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 재고 사용(소진). inventoryId 또는 barcode 중 하나.
  Future<String> useStock({
    int? inventoryId,
    String? barcode,
    required int qty,
    String? note,
  }) async {
    final body = await _post('/inventory/usage', {
      'inventory_id': ?inventoryId,
      if (barcode != null && barcode.isNotEmpty) 'barcode': barcode,
      'qty': qty,
      if (note != null && note.isNotEmpty) 'note': note,
    });
    return body['message'] as String? ?? '출고 처리되었습니다.';
  }

  // ---- 알림 ----
  Future<({List<AppNotificationItem> items, int unread, bool hasMore})> notifications(
      {int page = 1}) async {
    final body = await _get('/notifications?page=$page');
    final items = (body['data'] as List)
        .map((e) => AppNotificationItem.fromJson(e as Map<String, dynamic>))
        .toList();
    final unread = (body['meta']?['unread'] as num?)?.toInt() ?? 0;
    return (
      items: items,
      unread: unread,
      hasMore: Paged.hasMoreFromMeta(body['meta'] as Map<String, dynamic>?),
    );
  }

  Future<int> unreadCount() async {
    final body = await _get('/notifications/unread-count');
    return (body['unread'] as num?)?.toInt() ?? 0;
  }

  Future<void> markRead(int id) => _post('/notifications/$id/read', {});
  Future<void> markAllRead() => _post('/notifications/read-all', {});

  // ---- helpers ----
  Future<Map<String, dynamic>> _get(String path) async {
    final res = await _client
        .get(Uri.parse('${ApiConfig.apiUrl}$path'), headers: auth.authHeaders)
        .timeout(ApiConfig.timeout);
    if (res.statusCode != 200) {
      throw OrderException(_error(_decode(res), res.statusCode));
    }
    return _decode(res);
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final res = await _client
        .post(
          Uri.parse('${ApiConfig.apiUrl}$path'),
          headers: {...auth.authHeaders, 'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(ApiConfig.timeout);
    if (res.statusCode != 200 && res.statusCode != 201) {
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
    return '요청을 처리하지 못했습니다 ($status).';
  }
}
