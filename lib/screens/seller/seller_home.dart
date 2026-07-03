import 'package:flutter/material.dart';

import '../../data/seller_repository.dart';
import '../../models/fulfillment.dart';
import '../../models/store_ops.dart' show won;
import '../../theme/app_colors.dart';
import '../../widgets/dashboard_header.dart';
import 'bank_deposit_screen.dart';
import 'categories_screen.dart';
import 'shipment_waiting_screen.dart';
import 'hometax_screen.dart';
import 'hq_inventory_screen.dart';
import 'store_payments_screen.dart';
import 'inquiries_screen.dart';
import 'notices_manage_screen.dart';
import 'order_changes_screen.dart';
import 'products_screen.dart';
import 'sales_screen.dart';
import 'seller_orders_screen.dart';
import 'stores_screen.dart';
import 'suppliers_screen.dart';
import 'seller_sales_orders_screen.dart';
import 'seller_shipments_screen.dart';
import 'seller_statements_screen.dart';
import 'seller_tax_invoices_screen.dart';
import 'seller_widgets.dart';
import 'supplier_orders_screen.dart';

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
  List<_TabDef> get _tabs => [
        _TabDef(
          icon: Icons.assignment_outlined,
          activeIcon: Icons.assignment,
          label: '발주',
          page: _orderTab,
        ),
        _TabDef(
          icon: Icons.local_shipping_outlined,
          activeIcon: Icons.local_shipping,
          label: '출고',
          page: _shipTab,
        ),
        // (탭 클릭 시 바로 출고 화면)
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
            icon: Icons.warehouse_outlined,
            activeIcon: Icons.warehouse,
            label: '재고',
            page: _hqInventoryTab,
          ),
        if (_isHq)
          _TabDef(
            icon: Icons.store_outlined,
            activeIcon: Icons.store,
            label: '거래처',
            page: _partnerTab,
          ),
      ];

  // 본사 재고 탭 — HqInventoryScreen 임베드
  Widget _hqInventoryTab() => HqInventoryScreen(repository: widget.repository, embedded: true);

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

  // ── 발주: 요약 KPI + 발주 처리 + 최근 발주 ──
  Widget _orderTab() => _tabBody([
        FutureBuilder<SellerDashboard>(
          future: _future,
          builder: (context, snap) {
            final d = snap.data;
            return Column(
              children: [
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
        const SizedBox(height: 14),
        _NavCard(
          icon: Icons.inbox_outlined,
          title: '받은 발주',
          sub: '매장 발주 확인(발주확인) · 품목·정산·문서',
          onTap: () => _go(SellerOrdersScreen(
              repository: widget.repository, isHq: _isHq, onChanged: widget.onChanged)),
        ),
        FutureBuilder<SellerDashboard>(
          future: _future,
          builder: (context, snap) => _NavCard(
            icon: Icons.published_with_changes_outlined,
            title: '주문 변경 반영',
            sub: '매장 발주 수정/취소 확인',
            badge: snap.data?.pendingChanges ?? 0,
            onTap: () => _go(OrderChangesScreen(
                repository: widget.repository, onChanged: _reload)),
          ),
        ),
        if (_isHq)
          _NavCard(
            icon: Icons.inventory_outlined,
            title: '공급사 발주 현황',
            sub: '공급사별 발주 모아보기',
            onTap: () => _go(SupplierOrdersScreen(repository: widget.repository)),
          ),
        if (widget.onAttendance != null)
          _NavCard(
            icon: Icons.how_to_reg_outlined,
            title: '근태관리',
            sub: '출퇴근·휴무 승인 / 급여',
            onTap: widget.onAttendance!,
          ),
        const SizedBox(height: 8),
        FutureBuilder<SellerDashboard>(
          future: _future,
          builder: (context, snap) {
            final recent = snap.data?.recentOrders ?? const [];
            if (recent.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 6, 4, 10),
                  child: Text('최근 발주 현황',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ),
                for (final o in recent)
                  GestureDetector(
                    onTap: () => _go(SellerOrderDetailScreen(
                        repository: widget.repository, id: o.id)),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Expanded(
                                    child: Text(o.orderNo,
                                        style: const TextStyle(
                                            fontSize: 13, fontWeight: FontWeight.w800)),
                                  ),
                                  FulfillStatusChip(status: o.status, label: o.statusLabel),
                                ]),
                                const SizedBox(height: 4),
                                Text('${o.storeName ?? ''} · ${o.itemCount}품목 · ${o.createdAt ?? ''}',
                                    style: const TextStyle(
                                        fontSize: 12, color: AppColors.inkSoft)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(won(o.storeAmount),
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.accent)),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ]);

  // ── 출고·배송 — 탭 클릭 시 주문 단위 출고 대기(임베드) ──
  Widget _shipTab() => ShipmentWaitingScreen(
        repository: widget.repository,
        onChanged: widget.onChanged,
        embedded: true,
      );

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

class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.icon,
    required this.title,
    required this.sub,
    required this.onTap,
    this.badge = 0,
  });
  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback onTap;
  final int badge;

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
              if (badge > 0)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: AppColors.accent, borderRadius: BorderRadius.circular(100)),
                  child: Text('$badge',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                ),
              const Icon(Icons.chevron_right, color: AppColors.inkSoft),
            ]),
          ),
        ),
      ),
    );
  }
}
