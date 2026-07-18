import 'package:package_info_plus/package_info_plus.dart';

/// 앱(모바일 소스) 버전 — 빌드된 앱에서 런타임에 읽어 캐시.
/// pubspec `version: x.y.z+build` 이 그대로 반영된다.
class AppVersion {
  AppVersion._();

  static String _version = '';
  static String _build = '';

  /// main 에서 1회 호출. 실패해도 앱 구동엔 영향 없음.
  static Future<void> init() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _version = info.version;
      _build = info.buildNumber;
    } catch (_) {
      // 무시 — display 는 빈 값
    }
  }

  /// 예: "v1.0.6 (21)". 로드 전이면 빈 문자열.
  static String get display => _version.isEmpty ? '' : 'v$_version ($_build)';
}
