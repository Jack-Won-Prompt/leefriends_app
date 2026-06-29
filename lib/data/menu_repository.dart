import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/menu_item.dart';
import 'api_config.dart';
import 'sample_data.dart';

/// 메뉴 데이터 소스. 서버 API 를 우선 시도하고,
/// 실패(네트워크/타임아웃/오류)하면 번들 샘플 데이터로 자동 폴백합니다.
///
/// → API 가 준비되면 코드 수정 없이 실데이터로 전환되고,
///   오프라인에서도 동일한 화면을 보장합니다.
class MenuRepository {
  MenuRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// 마지막 조회가 실데이터(API)였는지 여부. UI 배지 표시에 사용.
  bool isLive = false;

  Future<List<MenuCategory>> categories() async {
    try {
      final res = await _get('/categories');
      final list = (res['data'] as List)
          .map((e) => MenuCategory.fromJson(e as Map<String, dynamic>))
          .toList();
      if (list.isNotEmpty) return list;
    } catch (_) {
      // fallthrough
    }
    return SampleData.categories;
  }

  /// [category] == null 또는 'all' 이면 전체.
  Future<List<MenuItem>> menus({String? category}) async {
    final cat = (category == null || category.isEmpty) ? 'all' : category;
    try {
      final res = await _get('/menus${cat == 'all' ? '' : '?cat=$cat'}');
      final list = (res['data'] as List)
          .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
          .toList();
      isLive = true;
      return list;
    } catch (_) {
      isLive = false;
      final all = SampleData.menus();
      if (cat == 'all') return all;
      return all.where((m) => m.category == cat).toList();
    }
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final uri = Uri.parse('${ApiConfig.apiUrl}$path');
    final res = await _client.get(uri).timeout(ApiConfig.timeout);
    if (res.statusCode != 200) {
      throw http.ClientException('HTTP ${res.statusCode}', uri);
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  void dispose() => _client.close();
}
