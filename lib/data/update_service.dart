import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

/// Google Play 인앱 업데이트.
/// 스토어에서 설치된 앱에서만 동작하며, 디버그/스토어 외 설치/iOS 에서는 조용히 무시.
class UpdateService {
  static bool _checked = false;

  /// 앱 시작 시 1회 호출. 새 버전이 있으면 즉시 업데이트(전체화면)를 띄운다.
  /// 즉시 업데이트가 불가하면 유연(백그라운드) 업데이트로 폴백.
  static Future<void> checkAndUpdate() async {
    if (_checked) return;
    _checked = true;

    // Play In-App Update 는 Android 전용
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) return;

      if (info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      } else if (info.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
      }
    } catch (_) {
      // 스토어 외 설치·네트워크 오류·미지원 환경 등은 무시 (업데이트는 선택적 기능)
    }
  }
}
