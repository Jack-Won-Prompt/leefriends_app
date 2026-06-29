import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/order.dart';
import '../models/paged.dart';
import '../models/store_ops.dart' show OrderStatement;
import '../models/supply_product.dart';
import 'api_config.dart';
import 'auth_controller.dart';

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
  Future<OrderModel> createOrder({
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
      return OrderModel.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw OrderException(_error(body, res.statusCode));
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
