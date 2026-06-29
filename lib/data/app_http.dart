import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// 운영 서버(nginx)가 중간 인증서(GoGetSSL RSA DV CA)를 TLS 체인에 포함하지
/// 않아 Android 의 Flutter TLS 가 핸드셰이크에 실패하는 문제를 우회한다.
///
/// 번들된 중간 인증서를 신뢰 앵커로 추가한 SecurityContext 를 전역
/// HttpOverrides 로 설치해, API 호출뿐 아니라 서버 이미지(SvgPicture.network)
/// 등 모든 dart:io 네트워킹이 정상 검증되도록 한다.
/// (badCertificateCallback 로 전부 허용하는 방식보다 안전 — 특정 중간 인증서만 신뢰)
///
/// 서버가 풀체인으로 교체되어도 무해하게 유지된다.
class _AppHttpOverrides extends HttpOverrides {
  _AppHttpOverrides(this._context);
  final SecurityContext _context;

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      super.createHttpClient(_context);
}

class AppHttp {
  AppHttp._();

  /// main() 에서 runApp 전에 1회 호출.
  static Future<void> init() async {
    if (kIsWeb) return; // 웹은 dart:io 미지원 (브라우저가 체인 보완)
    try {
      final data = await rootBundle.load('assets/certs/gogetssl_rsa_dv_ca.pem');
      final context = SecurityContext(withTrustedRoots: true)
        ..setTrustedCertificatesBytes(data.buffer.asUint8List());
      HttpOverrides.global = _AppHttpOverrides(context);
    } catch (e) {
      debugPrint('[AppHttp] 인증서 컨텍스트 초기화 실패: $e');
    }
  }
}
