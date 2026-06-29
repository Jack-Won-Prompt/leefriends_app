import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/content.dart';
import 'api_config.dart';
import 'order_repository.dart' show OrderException;

/// 소비자 공지/매장찾기 (공개 API, 인증 불필요).
class ContentRepository {
  ContentRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<({List<NoticeItem> notices, List<NoticeCategory> categories})> notices(
      {String cat = 'all'}) async {
    final body = await _get('/notices?cat=$cat');
    final notices = (body['data'] as List)
        .map((e) => NoticeItem.fromJson(e as Map<String, dynamic>))
        .toList();
    final cats = (body['meta']?['categories'] as List? ?? [])
        .map((e) => NoticeCategory.fromJson(e as Map<String, dynamic>))
        .toList();
    return (notices: notices, categories: cats);
  }

  Future<NoticeItem> noticeDetail(int id) async {
    final body = await _get('/notices/$id');
    return NoticeItem.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<({List<StoreLocation> stores, List<String> regions})> stores({
    String region = 'all',
    String? q,
  }) async {
    final qs = StringBuffer('?region=$region');
    if (q != null && q.isNotEmpty) {
      qs.write('&q=${Uri.encodeQueryComponent(q)}');
    }
    final body = await _get('/stores$qs');
    final stores = (body['data'] as List)
        .map((e) => StoreLocation.fromJson(e as Map<String, dynamic>))
        .toList();
    final regions = (body['meta']?['regions'] as List? ?? [])
        .map((e) => e.toString())
        .toList();
    return (stores: stores, regions: regions);
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final res = await _client
        .get(Uri.parse('${ApiConfig.apiUrl}$path'),
            headers: {'Accept': 'application/json'})
        .timeout(ApiConfig.timeout);
    if (res.statusCode != 200) {
      throw OrderException('불러오지 못했습니다 (${res.statusCode}).');
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }
}
