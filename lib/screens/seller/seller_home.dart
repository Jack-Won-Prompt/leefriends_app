import 'package:flutter/material.dart';

import '../../data/seller_repository.dart';
import '../../models/fulfillment.dart';
import '../../theme/app_colors.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/new_product_banner.dart';
import 'bank_deposit_screen.dart';
import 'categories_screen.dart';
import 'delivery_work_screen.dart';
import 'fruit_storage_screen.dart';
import 'purchase_orders_screen.dart';
import 'shipment_waiting_screen.dart';
import 'hometax_screen.dart';
import 'hq_inventory_screen.dart';
import 'store_payments_screen.dart';
import 'inquiries_screen.dart';
import 'notices_manage_screen.dart';
import 'notification_logs_screen.dart';
import 'products_screen.dart';
import 'sales_screen.dart';
import 'seller_orders_screen.dart';
import 'stores_screen.dart';
import 'suppliers_screen.dart';
import 'seller_sales_orders_screen.dart';
import 'seller_shipments_screen.dart';
import 'seller_statements_screen.dart';
import 'seller_tax_invoices_screen.dart';

/// 본사/공급처 로그인 후 카드형 홈 대시보드 — 처리 대기 요약 + 메뉴.
class SellerHome extends StatefulWidget {
  const SellerHome({
    super.key,
    required this.repository,
    this.name = '',
    this.roleLabel = '',
    this.unread = 0,
    this.onNotifications,
    this.onChat,
    this.onLogout,
    this.onChanged,
    this.onSchedule,
    this.onAttendance,
  });

  final SellerRepository repository;
  final String name;
  final String roleLabel;
  final int unread;
  final VoidCallback? onNotifications;
  final VoidCallback? onChat;
  final VoidCallback? onLogout;
  final VoidCallback? onChanged;
  final VoidCallback? onSchedule;
  final VoidCallback? onAttendance;

  @override
  State<SellerHome> createState() => _SellerHomeState();
}

class _SellerHomeState extends State<SellerHome> {
  late Future<SellerDashboard> _future;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.dashboard();
  }

  Future<void> _reload() async {
    setState(() { _future = widget.repository.dashboard(); });
    await _future;
  }

  void _go(Widget screen) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => screen))
        .then((_) => _reload());
  }

  bool get _isHq => widget.roleLabel == '본사';

  /// 각 탭 공통 — 새로고침 + 하단 안전여백.
  Widget _tabBody(List<Widget> children) {
    final bottom = 32 + MediaQuery.of(context).padding.bottom;
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _reload,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, 18, 16, bottom),
        children: children,
      ),
    );
  }

  /// 업무 대분류 탭 정의 (역할에 따라 동적).
  /// 본사 재고는 홈 «바로가기»로 이동해 탭 과다를 해소(7→6).
  List<_TabDef> get _tabs => [
        _TabDef(
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard_rounded,
          label: '홈',
          page: _homeTab,
        ),
        _TabDef(
          icon: Icons.local_shipping_outlined,
          activeIcon: Icons.local_shipping,
          label: '출고',
          page: _shipTab,
        ),
        if (_isHq)
          _TabDef(
            icon: Icons.assignment_turned_in_outlined,
            activeIcon: Icons.assignment_turned_in,
            label: '배송',
            page: _deliveryTab,
          ),
        _TabDef(
          icon: Icons.payments_outlined,
          activeIcon: Icons.payments,
          label: '정산',
          page: _settleTab,
        ),
        _TabDef(
          icon: Icons.category_outlined,
          activeIcon: Icons.category,
          label: '상품',
          page: _productTab,
        ),
        if (_isHq)
          _TabDef(
            icon: Icons.store_outlined,
            activeIcon: Icons.store,
            label: '거래처',
            page: _partnerTab,
          ),
      ];

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
        child: Text(text,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
      );

  // 2칸 박스 그리드 (처리 현황과 동일 톤의 바로가기 타일용)
  Widget _grid(List<Widget> cards) => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero, // 중첩 그리드가 MediaQuery 여백을 상속해 상단 간격이 벌어지는 것 방지
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
        children: cards,
      );

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs;
    final index = _tab.clamp(0, tabs.length - 1);
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          DashboardHeader(
            greeting: '안녕하세요 👋',
            name: widget.name,
            tagline: '${widget.roleLabel} · 발주 처리',
            unread: widget.unread,
            onNotifications: widget.onNotifications ?? () {},
            onChat: widget.onChat ?? () {},
            onSchedule: widget.onSchedule,
            onLogout: widget.onLogout ?? () {},
          ),
          Expanded(
            child: IndexedStack(
              index: index,
              children: [for (final t in tabs) t.page()],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.surface,
            currentIndex: index,
            selectedItemColor: AppColors.accent,
            unselectedItemColor: AppColors.inkSoft,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            onTap: (i) => setState(() => _tab = i),
            items: [
              for (final t in tabs)
                BottomNavigationBarItem(
                  icon: Icon(t.icon),
                  activeIcon: Icon(t.activeIcon),
                  label: t.label,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 홈: 처리 현황 + 바로가기 + 최근 발주 ──
  Widget _homeTab() => _tabBody([
        _sectionTitle('처리 현황'),
        FutureBuilder<SellerDashboard>(
          future: _future,
          builder: (context, snap) {
            final d = snap.data;
            return Column(
              children: [
                // 본사: 당일 신규 품목 배너 — 탭하면 품목 관리
                if (d?.newProducts case final n? when _isHq) ...[
                  NewProductBanner(
                    item: n,
                    onTap: () => _go(ProductsScreen(repository: widget.repository)),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(children: [
                  _Stat(
                    label: '확인 대기',
                    value: d?.pendingSalesOrders,
                    hint: '판매주문',
                    color: AppColors.mango600,
                    onTap: () => _go(SellerSalesOrdersScreen(
                        repository: widget.repository,
                        onChanged: widget.onChanged,
                        initialStatus: 'created',
                        inlineConfirm: true)),
                  ),
                  const SizedBox(width: 12),
                  _Stat(
                    label: '출고 대기',
                    value: d?.confirmedSalesOrders,
                    hint: '미출고 주문',
                    color: const Color(0xFF1B6CC4),
                    onTap: () => _go(ShipmentWaitingScreen(
                        repository: widget.repository, onChanged: widget.onChanged)),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  _Stat(
                    label: '송장 대기',
                    value: d?.shipmentsToConfirm,
                    hint: '출고 생성됨',
                    color: AppColors.mango700,
                    onTap: () => _go(SellerShipmentsScreen(
                        repository: widget.repository,
                        onChanged: widget.onChanged,
                        initialStatus: 'created')),
                  ),
                  const SizedBox(width: 12),
                  _Stat(
                    label: '배송중',
                    value: d?.inTransit,
                    hint: '오늘 발주 ${d?.todayOrders ?? '-'}건',
                    color: const Color(0xFF1E8E4E),
                    onTap: () => _go(SellerShipmentsScreen(
                        repository: widget.repository,
                        onChanged: widget.onChanged,
                        initialStatus: 'confirmed')),
                  ),
                ]),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        _sectionTitle('바로가기'),
        _grid([
          _MenuTile(
            icon: Icons.inbox_outlined,
            title: '받은 발주',
            sub: '발주확인·정산·문서',
            onTap: () => _go(SellerOrdersScreen(
                repository: widget.repository, isHq: _isHq, onChanged: widget.onChanged)),
          ),
          if (_isHq)
            _MenuTile(
              icon: Icons.warehouse_outlined,
              title: '본사 재고',
              sub: '재고 현황·조정',
              onTap: () => _go(HqInventoryScreen(repository: widget.repository)),
            ),
          _MenuTile(
            icon: Icons.shopping_cart_outlined,
            title: '구매발주',
            sub: _isHq ? '공급사 발주·입고' : '본사 구매발주 확인',
            onTap: () => _go(PurchaseOrdersScreen(
                repository: widget.repository, isHq: _isHq, onChanged: widget.onChanged)),
          ),
          if (widget.onAttendance != null)
            _MenuTile(
              icon: Icons.how_to_reg_outlined,
              title: '출근관리',
              sub: '출퇴근·휴무·급여',
              onTap: widget.onAttendance!,
            ),
        ]),
      ]);

  // ── 출고·배송 — 탭 클릭 시 주문 단위 출고 대기(임베드) ──
  Widget _shipTab() => ShipmentWaitingScreen(
        repository: widget.repository,
        onChanged: widget.onChanged,
        embedded: true,
      );

  // ── 배송업무(본사) — 출고지시서 QR 스캔 → 사진·서명 → 배송완료 ──
  Widget _deliveryTab() => DeliveryWorkScreen(repository: widget.repository, embedded: true);

  // ── 정산·전자문서 ──
  Widget _settleTab() => _tabBody([
        _NavCard(
          icon: Icons.bar_chart_outlined,
          title: '매출 현황',
          sub: '기간별·매장별 매출',
          onTap: () => _go(SalesScreen(repository: widget.repository)),
        ),
        _NavCard(
          icon: Icons.description_outlined,
          title: '세금계산서',
          sub: _isHq ? '매장 발행·취소·이력' : '본사 청구 발행·취소',
          onTap: () => _go(SellerTaxInvoicesScreen(
              repository: widget.repository, roleLabel: widget.roleLabel)),
        ),
        _NavCard(
          icon: Icons.receipt_long_outlined,
          title: '거래명세서',
          sub: _isHq ? '매장 작성·전송' : '본사 작성·전송·발행',
          onTap: () => _go(SellerStatementsScreen(
              repository: widget.repository, roleLabel: widget.roleLabel)),
        ),
        if (_isHq)
          _NavCard(
            icon: Icons.account_balance_wallet_outlined,
            title: '매출/매입 (홈택스)',
            sub: '홈택스 세금계산서 수집·조회',
            onTap: () => _go(HometaxScreen(repository: widget.repository)),
          ),
        if (_isHq)
          _NavCard(
            icon: Icons.account_balance_outlined,
            title: '계좌 입금확인',
            sub: '계좌내역 수집·입금 대사',
            onTap: () => _go(BankDepositScreen(repository: widget.repository)),
          ),
        if (_isHq)
          _NavCard(
            icon: Icons.savings_outlined,
            title: '매장별 입금현황',
            sub: '입금완료·미입금 집계·안내',
            onTap: () => _go(StorePaymentsScreen(repository: widget.repository)),
          ),
      ]);

  // ── 상품·기준정보 ──
  Widget _productTab() => _tabBody([
        _NavCard(
          icon: Icons.category_outlined,
          title: '상품 관리',
          sub: _isHq ? '품목 등록·수정·승인' : '자사 물품 등록·수정',
          onTap: () => _go(ProductsScreen(repository: widget.repository)),
        ),
        if (_isHq)
          _NavCard(
            icon: Icons.folder_outlined,
            title: '카테고리 관리',
            sub: '품목 대분류 관리',
            onTap: () => _go(CategoriesScreen(repository: widget.repository)),
          ),
        if (_isHq)
          _NavCard(
            icon: Icons.ac_unit_outlined,
            title: '과일 보관 관리',
            sub: '보관 조건 등록 · 매장 공유',
            onTap: () => _go(FruitStorageScreen.manage(repository: widget.repository)),
          ),
      ]);

  // ── 거래처·운영 (본사 전용) ──
  Widget _partnerTab() => _tabBody([
        _NavCard(
          icon: Icons.handshake_outlined,
          title: '공급처 관리',
          sub: '공급처 초대·수정',
          onTap: () => _go(SuppliersScreen(repository: widget.repository)),
        ),
        _NavCard(
          icon: Icons.store_mall_directory_outlined,
          title: '매장 관리',
          sub: '매장 초대·수정',
          onTap: () => _go(StoresManageScreen(repository: widget.repository)),
        ),
        _NavCard(
          icon: Icons.campaign_outlined,
          title: '공지 관리',
          sub: '포털 공지 발송',
          onTap: () => _go(NoticesManageScreen(repository: widget.repository)),
        ),
        _NavCard(
          icon: Icons.notifications_active_outlined,
          title: 'FCM 알림 이력',
          sub: '본사·매장 알림 발송 내역',
          onTap: () => _go(NotificationLogsScreen(repository: widget.repository)),
        ),
        _NavCard(
          icon: Icons.contact_mail_outlined,
          title: '가맹문의',
          sub: '문의 상담·처리',
          onTap: () => _go(InquiriesScreen(repository: widget.repository)),
        ),
      ]);
}

/// 업무 대분류 탭 정의.
class _TabDef {
  const _TabDef({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.page,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget Function() page;
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.hint,
    required this.color,
    this.onTap,
  });
  final String label;
  final int? value;
  final String hint;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(label,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
                    ),
                    if (onTap != null)
                      const Icon(Icons.chevron_right, size: 16, color: AppColors.inkSoft),
                  ],
                ),
                const SizedBox(height: 8),
                Text(value?.toString() ?? '–',
                    style: TextStyle(
                        fontSize: 30, fontWeight: FontWeight.w800, color: color, height: 1)),
                const SizedBox(height: 4),
                Text(hint, style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 바로가기 박스 타일 (2칸 그리드용) — 아이콘 + 제목 + 부제.
class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.sub,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: AppColors.mango100, borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: Icon(icon, color: AppColors.mango700, size: 21),
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  const SizedBox(height: 1),
                  Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.icon,
    required this.title,
    required this.sub,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: AppColors.mango100, borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: Icon(icon, color: AppColors.mango700, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
                    const SizedBox(height: 2),
                    Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.inkSoft),
            ]),
          ),
        ),
      ),
    );
  }
}
