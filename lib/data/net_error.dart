import 'dart:async';
import 'dart:io';

/// 네트워크/통신 예외를 사용자에게 보여줄 **구체적인** 메시지로 변환한다.
///
/// 기존에는 모든 예외를 "연결에 실패했습니다"로 뭉뚱그려 표시해
/// DNS 실패·타임아웃·인증서 오류를 구분할 수 없었다(진단 난이도 ↑).
///
/// http 패키지는 SocketException 등을 `ClientException` 으로 감싸므로
/// 타입 검사와 메시지 문자열 검사를 함께 쓴다.
String describeNetworkError(Object e) {
  final s = e.toString();

  // 1) DNS 이름 해석 실패 — 비공개 DNS/VPN/공유기 설정이 주원인
  if (s.contains('Failed host lookup') ||
      s.contains('No address associated with hostname') ||
      s.contains('nodename nor servname')) {
    return '서버 주소를 찾을 수 없습니다(DNS).\n'
        '기기의 비공개 DNS·VPN·공유기 DNS 설정을 확인해 주세요.';
  }

  // 2) 응답 지연
  if (e is TimeoutException || s.contains('TimeoutException')) {
    return '서버 응답이 지연되고 있습니다.\n잠시 후 다시 시도해 주세요.';
  }

  // 3) TLS/인증서 — 기기 시각 오류나 중간 인증서 문제
  if (e is HandshakeException ||
      e is TlsException ||
      s.contains('HandshakeException') ||
      s.contains('CERTIFICATE')) {
    return '보안 연결(TLS)에 실패했습니다.\n기기 날짜·시간 설정을 확인해 주세요.';
  }

  // 4) 서버까지 도달 못함 (거부/불가/끊김)
  if (e is SocketException ||
      s.contains('SocketException') ||
      s.contains('Connection refused') ||
      s.contains('Network is unreachable') ||
      s.contains('Connection closed')) {
    return '서버에 연결할 수 없습니다.\n네트워크 상태를 확인해 주세요.';
  }

  // 5) 응답 파싱/형식 오류 — 네트워크가 아니라 앱·서버 응답 문제
  if (e is FormatException || e is TypeError || s.contains('FormatException')) {
    return '서버 응답을 처리하지 못했습니다.\n문제가 계속되면 관리자에게 문의해 주세요.';
  }

  return '요청을 처리하지 못했습니다.\n네트워크 상태를 확인해 주세요.';
}
