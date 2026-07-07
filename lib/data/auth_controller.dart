import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_user.dart';
import 'api_config.dart';

/// 로그인 상태 + 토큰을 관리하는 전역 컨트롤러.
/// 토큰은 SharedPreferences 에 저장되어 앱 재시작 시 자동 로그인됩니다.
class AuthController extends ChangeNotifier {
  AuthController({http.Client? client}) : _client = client ?? http.Client();

  static const _tokenKey = 'auth_token';
  final http.Client _client;

  String? _token;
  AuthUser? _user;
  bool _initializing = true;

  /// 로그아웃 직전(토큰이 아직 유효할 때) 호출되는 훅. PushService 가
  /// 기기 토큰을 서버에서 해제하는 데 사용.
  Future<void> Function()? beforeLogout;

  AuthUser? get user => _user;
  bool get isLoggedIn => _token != null && _user != null;
  bool get initializing => _initializing;
  Map<String, String> get authHeaders => {
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  /// 앱 시작 시 호출 — 저장된 토큰으로 세션 복구.
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    if (_token != null) {
      try {
        await _fetchMe();
      } catch (_) {
        await _clearToken();
      }
    }
    _initializing = false;
    notifyListeners();
  }

  /// 로그인. 실패 시 사용자에게 보여줄 메시지를 던집니다.
  Future<void> login(String email, String password) async {
    final uri = Uri.parse('${ApiConfig.apiUrl}/auth/login');
    final res = await _client
        .post(
          uri,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'email': email,
            'password': password,
            'device_name': 'flutter',
          }),
        )
        .timeout(ApiConfig.timeout);

    final body = _decode(res);
    if (res.statusCode == 200) {
      _token = body['token'] as String;
      _user = AuthUser.fromJson(body['user'] as Map<String, dynamic>);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, _token!);
      notifyListeners();
      return;
    }
    throw AuthException(_extractError(body, res.statusCode));
  }

  /// 비밀번호 재설정 링크 이메일 발송. 성공 시 안내 메시지 반환.
  Future<String> forgotPassword(String email) async {
    final res = await _client
        .post(
          Uri.parse('${ApiConfig.apiUrl}/auth/forgot-password'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'email': email}),
        )
        .timeout(ApiConfig.timeout);
    final body = _decode(res);
    if (res.statusCode == 200) {
      return body['message'] as String? ?? '재설정 링크를 보냈습니다.';
    }
    throw AuthException(_extractError(body, res.statusCode));
  }

  Future<void> logout() async {
    // 토큰이 유효할 때 기기 푸시 토큰부터 해제
    try {
      await beforeLogout?.call();
    } catch (_) {
      // 무시
    }
    try {
      await _client
          .post(Uri.parse('${ApiConfig.apiUrl}/auth/logout'),
              headers: authHeaders)
          .timeout(ApiConfig.timeout);
    } catch (_) {
      // 네트워크 실패해도 로컬 토큰은 제거
    }
    await _clearToken();
    notifyListeners();
  }

  Future<void> _fetchMe() async {
    final res = await _client
        .get(Uri.parse('${ApiConfig.apiUrl}/me'), headers: authHeaders)
        .timeout(ApiConfig.timeout);
    if (res.statusCode != 200) {
      throw AuthException('세션이 만료되었습니다.');
    }
    final body = _decode(res);
    _user = AuthUser.fromJson(body['user'] as Map<String, dynamic>);
  }

  Future<void> _clearToken() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Map<String, dynamic> _decode(http.Response res) {
    try {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  String _extractError(Map<String, dynamic> body, int status) {
    final errors = body['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
    }
    if (body['message'] is String) return body['message'] as String;
    return '로그인에 실패했습니다 ($status).';
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}
