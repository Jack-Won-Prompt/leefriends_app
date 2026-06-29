/// API 베이스 URL 설정.
///
/// 기본 엔드포인트는 운영 도메인(https://www.leefriends.co.kr)입니다.
/// 로컬 개발 시에만 --dart-define 으로 덮어씁니다.
///
/// 우선순위:
///  1) --dart-define=API_BASE=... (항상 우선)
///  2) 그 외 모든 빌드 → 운영 도메인
///
/// 로컬 XAMPP 로 붙이려면 (에뮬레이터는 10.0.2.2):
///   flutter run --dart-define=API_BASE=http://10.0.2.2/leefriends/public
class ApiConfig {
  ApiConfig._();

  /// 운영 도메인. 도메인 루트가 곧 Laravel public/ 이므로 경로 접미사 없음.
  static const prodBaseUrl = 'https://www.leefriends.co.kr';

  static const _override = String.fromEnvironment('API_BASE');

  static String get baseUrl => _override.isNotEmpty ? _override : prodBaseUrl;

  static String get apiUrl => '$baseUrl/api/v1';

  static const timeout = Duration(seconds: 8);
}
