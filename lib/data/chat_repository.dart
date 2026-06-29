import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/chat.dart';
import 'api_config.dart';
import 'auth_controller.dart';
import 'order_repository.dart' show OrderException;

/// 채팅 API 클라이언트. 토큰 인증 필요.
class ChatRepository {
  ChatRepository({required this.auth, http.Client? client})
      : _client = client ?? http.Client();

  final AuthController auth;
  final http.Client _client;

  Future<({String mode, List<ChatConversation> conversations})> conversations() async {
    final body = await _get('/chat/conversations');
    final mode = body['meta']?['mode'] as String? ?? 'single';
    final list = (body['data'] as List)
        .map((e) => ChatConversation.fromJson(e as Map<String, dynamic>))
        .toList();
    return (mode: mode, conversations: list);
  }

  /// 본사: 매장/공급처 대화방 생성·조회 → conversation id
  Future<int> open(String type, int id) async {
    final body = await _get('/chat/open?type=$type&id=$id');
    return (body['data']?['id'] as num).toInt();
  }

  Future<({List<ChatMessage> messages, int me})> messages(int convId, {int? after}) async {
    final path = after == null
        ? '/chat/conversations/$convId/messages'
        : '/chat/conversations/$convId/messages?after=$after';
    final body = await _get(path);
    final list = (body['data'] as List)
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
    final me = (body['meta']?['me'] as num?)?.toInt() ?? -1;
    return (messages: list, me: me);
  }

  Future<ChatMessage> send(int convId, String body) async {
    final res = await _client
        .post(
          Uri.parse('${ApiConfig.apiUrl}/chat/conversations/$convId/messages'),
          headers: {...auth.authHeaders, 'Content-Type': 'application/json'},
          body: jsonEncode({'body': body}),
        )
        .timeout(ApiConfig.timeout);
    final map = _decode(res);
    if (res.statusCode == 201 || res.statusCode == 200) {
      return ChatMessage.fromJson(map['data'] as Map<String, dynamic>);
    }
    throw OrderException(_error(map, res.statusCode));
  }

  /// 첨부(이미지/파일) 전송 — 멀티파트. body 는 선택.
  Future<ChatMessage> sendAttachment(int convId,
      {String? body, required String filePath}) async {
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.apiUrl}/chat/conversations/$convId/messages'),
    );
    req.headers.addAll(auth.authHeaders); // Accept + Authorization
    if (body != null && body.trim().isNotEmpty) req.fields['body'] = body.trim();
    req.files.add(await http.MultipartFile.fromPath('attachment', filePath));

    final streamed = await _client.send(req).timeout(const Duration(seconds: 60));
    final res = await http.Response.fromStream(streamed);
    final map = _decode(res);
    if (res.statusCode == 201 || res.statusCode == 200) {
      return ChatMessage.fromJson(map['data'] as Map<String, dynamic>);
    }
    throw OrderException(_error(map, res.statusCode));
  }

  Future<int> unread() async {
    final body = await _get('/chat/unread');
    return (body['unread'] as num?)?.toInt() ?? 0;
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final res = await _client
        .get(Uri.parse('${ApiConfig.apiUrl}$path'), headers: auth.authHeaders)
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
    if (body['message'] is String) return body['message'] as String;
    if (status == 403) return '채팅 권한이 없습니다.';
    return '채팅 요청 실패 ($status).';
  }
}
