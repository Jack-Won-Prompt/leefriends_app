import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../firebase_options.dart';
import 'api_config.dart';
import 'auth_controller.dart';

/// 백그라운드/종료 상태 메시지 핸들러.
/// notification 페이로드는 시스템이 알림 트레이에 자동 표시하므로 별도 처리 불필요.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  // no-op (트레이 표시는 OS 담당)
}

/// FCM 푸시: 권한 요청 → 토큰 등록/해제 → 포그라운드 인앱 배너.
/// Firebase 미설정(예: iOS 설정 전) 환경에서도 앱이 죽지 않도록 전부 방어.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final _client = http.Client();
  AuthController? _auth;
  GlobalKey<ScaffoldMessengerState>? _messengerKey;
  String? _token;
  bool _available = false;

  /// 알림 탭/수신 시 안읽음 배지 갱신용 콜백 (선택).
  VoidCallback? onNotification;

  Future<void> init(
    AuthController auth, {
    GlobalKey<ScaffoldMessengerState>? messengerKey,
  }) async {
    _auth = auth;
    _messengerKey = messengerKey;

    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      _available = true;
    } catch (e) {
      // Firebase 설정 파일 부재 등 → 푸시 비활성, 앱은 정상 동작
      _available = false;
      debugPrint('[Push] Firebase 미초기화 — 푸시 비활성: $e');
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
    final fm = FirebaseMessaging.instance;

    await fm.requestPermission(alert: true, badge: true, sound: true);
    await fm.setForegroundNotificationPresentationOptions(
        alert: true, badge: true, sound: true);

    _token = await fm.getToken();
    fm.onTokenRefresh.listen((t) {
      _token = t;
      _register();
    });

    FirebaseMessaging.onMessage.listen(_onForeground);
    FirebaseMessaging.onMessageOpenedApp.listen((_) => onNotification?.call());

    // 로그인 상태 변화에 따라 토큰 등록, 로그아웃 직전 해제
    auth.addListener(_register);
    auth.beforeLogout = _unregister;
    _register();
  }

  Future<void> _register() async {
    final auth = _auth;
    if (!_available || auth == null || !auth.isLoggedIn || _token == null) {
      return;
    }
    try {
      await _client
          .post(
            Uri.parse('${ApiConfig.apiUrl}/device-tokens'),
            headers: {...auth.authHeaders, 'Content-Type': 'application/json'},
            body: jsonEncode({'token': _token, 'platform': _platform()}),
          )
          .timeout(ApiConfig.timeout);
    } catch (_) {
      // 무시 (다음 변화/갱신 시 재시도)
    }
  }

  Future<void> _unregister() async {
    final auth = _auth;
    if (!_available || auth == null || _token == null) return;
    try {
      await _client
          .delete(
            Uri.parse('${ApiConfig.apiUrl}/device-tokens'),
            headers: {...auth.authHeaders, 'Content-Type': 'application/json'},
            body: jsonEncode({'token': _token}),
          )
          .timeout(ApiConfig.timeout);
    } catch (_) {
      // 무시
    }
  }

  void _onForeground(RemoteMessage m) {
    onNotification?.call();
    final n = m.notification;
    final title = n?.title ?? m.data['title']?.toString() ?? '새 알림';
    final body = n?.body ?? m.data['body']?.toString() ?? '';
    final messenger = _messengerKey?.currentState;
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFA8430F),
        duration: const Duration(seconds: 4),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: Colors.white)),
            if (body.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(body,
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
              ),
          ],
        ),
      ),
    );
  }

  String _platform() {
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    return 'android';
  }
}
