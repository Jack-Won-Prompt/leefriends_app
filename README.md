# LEEFRIENDS · 리프렌즈 모바일 앱

프리미엄 망고빙수 전문점 **LEEFRIENDS** 의 Flutter 모바일 앱입니다.
리프렌즈 웹 서버(`E:\xampp\htdocs\leefriends`)의 브랜드 색상·폰트·톤을 그대로 옮겨 구현했습니다.

## 디자인

- **컬러**: 서버의 `mango` 팔레트 동일 (primary `#FF9F1C`, accent `#F2784B`, 배경 `#FFF9ED`)
- **폰트**: Pretendard (서버와 동일, `assets/fonts/`에 번들)
- **테마**: Material 3, 둥근 카드 / 부드러운 그림자 / 따뜻한 톤
- **메뉴 이미지**: 서버 `public/images/menu/*.svg` 를 그대로 사용 (`flutter_svg`)

## 화면

| 화면 | 내용 |
|------|------|
| 홈 | 히어로, 시그니처·베스트 가로 스크롤, 신메뉴, 브랜드 스토리 |
| 메뉴 | 카테고리 탭(전체/시그니처/빙수/음료/디저트) + 2열 그리드 + 상세 |
| 발주 | 매장 로그인 → 물품 카탈로그 → 장바구니 → 발주 접수/수정/취소 → **매입 내역·입고 예정·입고 처리·재고·알림** |

### 홈 바로가기 (소비자)
- **공지사항**(카테고리별 목록·상세), **매장 찾기**(지역·검색) — 홈 상단 바로가기 카드.

### 매장 운영 (발주 탭, 로그인 후)
- 앱바 **알림 배지** + 메뉴(발주 내역 / 매입 내역 / 입고 예정 / 재고 / 로그아웃)
- **입고**: 배송중 출고 → 입고 처리 시 매장 재고 자동 반영(웹 `InventoryService` 재사용)
- **재고**: 현황(검색)·이동 내역(입고/출고/조정)·사용(소진) 등록
- **매입 내역**: 기간별(전체/이번 달) 합계·건수

### 발주(B2B) 흐름
- 매장 계정으로 로그인(Sanctum 토큰, 자동 로그인 유지). 매장 외 역할은 안내 화면 표시.
- 물품은 서버 `supply_products`(대분류 `category_code`, 규격 `spec`, 단위별 출고가)를 사용.
- 발주 접수는 웹 포털과 **동일한 주문 생성 규칙**(품목코드/판매주문 생성/공급처 라우팅)을 재사용.
- 테스트 계정: `store@leefriends.kr` / `1234`

## 데이터 연동

소비자 메뉴는 서버 API 를 우선 호출하고, 실패 시 **번들 샘플 데이터**로 자동 폴백합니다.
발주(B2B)는 토큰 인증이 필요해 실시간 API 만 사용합니다.

- 공개 엔드포인트 (Laravel, `routes/api.php`):
  - `GET /api/v1/menus?cat=signature|bingsu|drink|dessert`
  - `GET /api/v1/menus/{id}`
  - `GET /api/v1/categories`
  - `GET /api/v1/health`
- 인증/발주 엔드포인트 (Sanctum 토큰):
  - `POST /api/v1/auth/login` · `GET /api/v1/me` · `POST /api/v1/auth/logout`
  - `GET /api/v1/supply-products` (대분류별 그룹)
  - `GET /api/v1/orders` · `POST /api/v1/orders` · `GET /api/v1/orders/{id}`
  - `PUT /api/v1/orders/{id}` (수정) · `DELETE /api/v1/orders/{id}` (취소)
    - 출고 전(미취소·미완료)에만 허용, 위반 시 **409**. 수정/취소 시 본사·공급처에 변경 알림 전송(웹 `OrderChangeService` 재사용).
  - `GET /api/v1/purchases?period=all|month` (매입 합계+목록)
  - `GET /api/v1/inbound` · `GET /api/v1/shipments/{id}` · `POST /api/v1/shipments/{id}/receive` (입고 처리 → 재고 반영)
  - `GET /api/v1/inventory?q=` · `GET /api/v1/inventory/movements?type=` · `POST /api/v1/inventory/usage` (소진)
  - `GET /api/v1/notifications` (+`unread`) · `POST /api/v1/notifications/{id}/read` · `POST /api/v1/notifications/read-all`
- 공개 추가:
  - `GET /api/v1/notices?cat=` · `GET /api/v1/notices/{id}`
  - `GET /api/v1/stores?region=&q=`
- 베이스 URL 기본값: **운영 도메인** `https://www.leefriends.co.kr` (모든 빌드 공통, 배포·SSL 적용 완료)
- 로컬 XAMPP 로 붙이려면 (Android 에뮬레이터는 `10.0.2.2`):
  ```bash
  flutter run --dart-define=API_BASE=http://10.0.2.2/leefriends/public
  ```

## 실행

```bash
flutter pub get
flutter run                       # 연결된 디바이스/에뮬레이터
flutter build apk --debug         # Android 디버그 APK
```

## 구조

```
lib/
  main.dart                 앱 진입점
  theme/                    색상 · 테마
  models/menu_item.dart     메뉴 모델 (API 스키마 매핑)
  data/
    api_config.dart         API 베이스 URL (dart-define 오버라이드)
    menu_repository.dart    API 호출 + 샘플 폴백
    sample_data.dart        오프라인 샘플(서버 DB 13개 메뉴와 동일)
  screens/                  홈 · 메뉴 · 상세 · 루트(탭)
  widgets/                  메뉴 카드 · 배지 · 이미지
```

## 참고

- 로컬 개발 편의를 위해 Android `usesCleartextTraffic`, iOS ATS 예외가 켜져 있습니다.
  운영 배포 시 API 를 **https** 로 전환하고 해당 예외를 제거하세요.
