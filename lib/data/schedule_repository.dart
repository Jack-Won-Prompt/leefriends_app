import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/schedule.dart';
import 'api_config.dart';
import 'auth_controller.dart';
import 'order_repository.dart' show OrderException;

/// 일정(캘린더) API 클라이언트 — 본사/매장/공급처 공용. 토큰 인증 필요.
class ScheduleRepository {
  ScheduleRepository({required this.auth, http.Client? client})
      : _client = client ?? http.Client();

  final AuthController auth;
  final http.Client _client;

  Future<List<ScheduleItem>> list() async {
    final body = await _send('GET', '/schedules');
    return (body['data'] as List? ?? [])
        .map((e) => ScheduleItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ScheduleItem> create({
    required String date,
    required String title,
    String? content,
    String color = 'mango',
  }) async {
    final body = await _send('POST', '/schedules', {
      'schedule_date': date,
      'title': title,
      if (content != null && content.isNotEmpty) 'content': content,
      'color': color,
    });
    return ScheduleItem.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<ScheduleItem> update(
    int id, {
    required String date,
    required String title,
    String? content,
    String color = 'mango',
  }) async {
    final body = await _send('PUT', '/schedules/$id', {
      'schedule_date': date,
      'title': title,
      if (content != null && content.isNotEmpty) 'content': content,
      'color': color,
    });
    return ScheduleItem.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    await _send('DELETE', '/schedules/$id');
  }

  // ---- helper ----
  Future<Map<String, dynamic>> _send(String method, String path,
      [Map<String, dynamic>? body]) async {
    final uri = Uri.parse('${ApiConfig.apiUrl}$path');
    final headers = {...auth.authHeaders, 'Content-Type': 'application/json'};
    final req = http.Request(method, uri)..headers.addAll(headers);
    if (body != null) req.body = jsonEncode(body);
    final streamed = await _client.send(req).timeout(ApiConfig.timeout);
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode < 200 || res.statusCode >= 300) {
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
