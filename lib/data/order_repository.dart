import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/order.dart';
import '../models/paged.dart';
import '../models/store_ops.dart' show OrderStatement;
import '../models/supply_product.dart';
import 'api_config.dart';
import 'auth_controller.dart';
import '../models/order_payment.dart';

/// 발주 도메인 API 클라이언트. 인증 헤더는 [AuthController] 에서 가져옵니다.
class OrderRepository {
  OrderRepository({required this.auth, http.Client? client})
      : _client = client ?? http.Client();

  final AuthController auth;
  final http.Client _client;

  Future<List<ProductGroup>> supplyProducts() async {
    final body = await _get('/supply-products');
    return (body['data'] as List)
        .map((e) => ProductGroup.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Paged<OrderModel>> orders({String type = 'all', int page = 1}) async {
    final body = await _get('/orders?type=$type&page=$page');
    return Paged(
      items: (body['data'] as List)
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore: Paged.hasMoreFromMeta(body['meta'] as Map<String, dynamic>?),
    );
  }

  Future<OrderModel> orderDetail(int id) async {
    final body = await _get('/orders/$id');
    return OrderModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// 발주 거래명세서
  Future<OrderStatement> orderStatement(int id) async {
    final body = await _get('/orders/$id/statement');
    return OrderStatement.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// 발주 접수. items: [{product_id, unit_id?, qty}]. orderType: normal|sample
  ///
  /// 결제 매장(토스)이면 발주가 바로 생성되지 않고 결제 정보가 돌아온다.
  /// 결제를 마쳐야 본사에 접수되므로, 호출한 쪽에서 결제창을 띄우고 결과를 확인해야 한다.
  Future<OrderSubmitResult> createOrder({
    required List<Map<String, dynamic>> items,
    String? note,
    String orderType = 'normal',
  }) async {
    final res = await _client
        .post(
          Uri.parse('${ApiConfig.apiUrl}/orders'),
          headers: {...auth.authHeaders, 'Content-Type': 'application/json'},
          body: jsonEncode({'items': items, 'note': ?note, 'order_type': orderType}),
        )
        .timeout(ApiConfig.timeout);
    final body = _decodeMap(res);
    if (res.statusCode == 201) {
      return OrderSubmitResult(
          order: OrderModel.fromJson(body['data'] as Map<String, dynamic>));
    }
    if (res.statusCode == 200) {
      final pay = PaymentCheckout.fromJson(body['payment'] as Map<String, dynamic>?);
      if (pay != null) return OrderSubmitResult(payment: pay);
    }
    throw OrderException(_error(body, res.statusCode));
  }

  /// 결제 결과 확인 — 결제창이 닫힌 뒤 서버에 다시 물어본다.
  Future<CheckoutStatus> checkoutStatus(String checkoutId) async {
    final body = await _get('/orders/checkout/$checkoutId');
    return CheckoutStatus.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// 발주 수정 (출고 전). items: [{product_id, unit_id?, qty}]
  Future<OrderModel> updateOrder({
    required int id,
    required List<Map<String, dynamic>> items,
    String? note,
  }) async {
    final res = await _client
        .put(
          Uri.parse('${ApiConfig.apiUrl}/orders/$id'),
          headers: {...auth.authHeaders, 'Content-Type': 'application/json'},
          body: jsonEncode({'items': items, 'note': ?note}),
        )
        .timeout(ApiConfig.timeout);
    final body = _decodeMap(res);
    if (res.statusCode == 200) {
      return OrderModel.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw OrderException(_error(body, res.statusCode));
  }

  /// 발주(거래명세서)에 품목 추가 (출고 전). 성공 메시지 반환.
  Future<String> addOrderItem(int orderId, int productId, int qty) async {
    final res = await _client
        .post(
          Uri.parse('${ApiConfig.apiUrl}/orders/$orderId/items'),
          headers: {...auth.authHeaders, 'Content-Type': 'application/json'},
          body: jsonEncode({'product_id': productId, 'qty': qty}),
        )
        .timeout(ApiConfig.timeout);
    final body = _decodeMap(res);
    if (res.statusCode == 201 || res.statusCode == 200) {
      return body['message'] as String? ?? '품목을 추가했습니다.';
    }
    throw OrderException(_error(body, res.statusCode));
  }

  /// 발주(거래명세서)에서 품목 삭제 (출고 전). 갱신된 발주 반환.
  Future<OrderModel> deleteOrderItem(int orderId, int itemId) async {
    final res = await _client
        .delete(Uri.parse('${ApiConfig.apiUrl}/orders/$orderId/items/$itemId'),
            headers: auth.authHeaders)
        .timeout(ApiConfig.timeout);
    final body = _decodeMap(res);
    if (res.statusCode == 200) {
      return OrderModel.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw OrderException(_error(body, res.statusCode));
  }

  /// 발주 취소 (출고 전).
  Future<OrderModel> cancelOrder(int id) async {
    final res = await _client
        .delete(Uri.parse('${ApiConfig.apiUrl}/orders/$id'),
            headers: auth.authHeaders)
        .timeout(ApiConfig.timeout);
    final body = _decodeMap(res);
    if (res.statusCode == 200) {
      return OrderModel.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw OrderException(_error(body, res.statusCode));
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final res = await _client
        .get(Uri.parse('${ApiConfig.apiUrl}$path'), headers: auth.authHeaders)
        .timeout(ApiConfig.timeout);
    if (res.statusCode != 200) {
      throw OrderException(_error(_decodeMap(res), res.statusCode));
    }
    return _decodeMap(res);
  }

  Map<String, dynamic> _decodeMap(http.Response res) {
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

class OrderException implements Exception {
  final String message;
  OrderException(this.message);
  @override
  String toString() => message;
}

/// 발주 전송 결과 — 바로 접수됐거나([order]), 결제가 필요하거나([payment]).
class OrderSubmitResult {
  const OrderSubmitResult({this.order, this.payment});
  final OrderModel? order;
  final PaymentCheckout? payment;
}
