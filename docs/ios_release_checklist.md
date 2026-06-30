# iOS App Store 등록 체크리스트 — LEEFRIENDS

> Windows + Codemagic 클라우드 빌드 기준. Mac 없이 진행 가능.
> Bundle ID: `com.leefriends.leefriends` · 앱 이름: 리프렌즈

코드/저장소 준비는 끝났습니다(아래 "완료" 참고). 남은 건 **각 콘솔에서의 계정·키 설정**입니다.
순서대로 진행하세요. 1 → 2 → 3 → 4.

---

## ✅ 이미 완료 (코드·저장소)
- [x] Bundle ID `com.leefriends.leefriends`
- [x] Info.plist 푸시 백그라운드 모드(`remote-notification`, `fetch`)
- [x] 카메라/사진 권한 설명 문구
- [x] `ios/Runner/GoogleService-Info.plist` + `lib/firebase_options.dart`
- [x] `codemagic.yaml` (build-name 자동 = pubspec, build-number 자동 증가)
- [x] 개인정보처리방침/계정삭제 페이지 운영중
  - https://www.leefriends.co.kr/privacy
  - https://www.leefriends.co.kr/account-deletion

---

## 1) Apple Developer (developer.apple.com)
- [ ] **Certificates, Identifiers & Profiles → Identifiers**
  - [ ] App ID `com.leefriends.leefriends` 등록 (이미 있으면 생략)
  - [ ] 해당 App ID 편집 → **Push Notifications** 체크 → Save
- [ ] **Keys → APNs 인증 키(.p8) 생성**
  - [ ] Apple Push Notifications service (APNs) 체크 → 생성 → **.p8 다운로드(1회만 가능)**
  - [ ] **Key ID**, **Team ID** 메모 (Firebase에 입력)
- [ ] **Keys → App Store Connect API 키(.p8) 생성**
  - [ ] Access: App Manager 이상 → 생성 → **.p8 다운로드(1회만 가능)**
  - [ ] **Issuer ID**, **Key ID** 메모 (Codemagic에 입력)

## 2) App Store Connect (appstoreconnect.apple.com)
- [ ] **나의 앱 → + → 신규 앱**
  - [ ] 플랫폼 iOS, 이름 `리프렌즈`, 기본 언어 한국어
  - [ ] Bundle ID `com.leefriends.leefriends` 선택
  - [ ] SKU 입력(임의, 예: `leefriends-ios-001`)
- [ ] 생성 후 URL 의 숫자 = **APP_STORE_APPLE_ID** (예: 6xxxxxxxxx) 메모 → Codemagic에 입력
- [ ] 앱 정보: 카테고리(비즈니스), 개인정보처리방침 URL 입력
- [ ] 심사 제출용 메타정보 입력 → `docs/ios_store_listing.md` 참고

## 3) Firebase 콘솔 (console.firebase.google.com)
- [ ] 프로젝트 → 프로젝트 설정 → **Cloud Messaging** 탭
- [ ] iOS 앱 → **APNs 인증 키 업로드**
  - [ ] 1번의 .p8 파일 + Key ID + Team ID 입력
- [ ] (앱이 없으면) iOS 앱 추가 후 `GoogleService-Info.plist` 최신본 교체

## 4) Codemagic (codemagic.io)
- [ ] **Add application** → GitHub `Jack-Won-Prompt/leefriends_app` 연결
- [ ] **Teams → Integrations → App Store Connect**
  - [ ] 1번의 API 키(.p8) + Issuer ID + Key ID 등록
  - [ ] 통합 이름을 **`CodemagicAppStoreKey`** 로 (codemagic.yaml과 일치해야 함)
- [ ] **Environment variables** → 그룹 **`appstore`** 생성
  - [ ] `APP_STORE_APPLE_ID` = 2번의 숫자 앱 ID (Secure 체크)
- [ ] iOS 코드서명: App Store Connect API 키로 자동 서명(automatic) 선택
- [ ] **Start new build → `ios-release` 워크플로 실행**
  - [ ] 빌드 성공 → TestFlight 자동 업로드 확인
- [ ] TestFlight에서 내부 테스트 → 이상 없으면 App Store 심사 제출

---

## 빌드/제출 후
- [ ] App Store Connect → 앱 → 버전 → "심사를 위해 제출"
- [ ] 심사 보통 24~48시간. 반려 시 Resolution Center 메시지 확인
- [ ] 푸시 알림 동작 확인(TestFlight 빌드에서 실제 단말 테스트)

## 참고 — 자주 막히는 지점
- APNs/AppStoreConnect .p8 키는 **다운로드 1회**만 가능 → 잃어버리면 재발급.
- `CodemagicAppStoreKey` 이름이 codemagic.yaml의 `integrations.app_store_connect` 값과 **정확히 일치**해야 함.
- 첫 빌드는 코드서명 프로파일 자동 생성 때문에 시간이 더 걸릴 수 있음.
