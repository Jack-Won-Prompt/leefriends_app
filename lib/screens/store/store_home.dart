import 'package:flutter/material.dart';

import '../../data/cart_controller.dart';
import '../../data/order_repository.dart';
import '../../data/store_ops_repository.dart';
import '../../models/store_ops.dart' show StoreDashboard, won;
import '../../theme/app_colors.dart';
import '../../widgets/dashboard_header.dart';
import '../order/catalog_screen.dart';
import '../order/orders_screen.dart';
import 'inbound_screen.dart';
import 'inventory_screen.dart';
import 'purchases_screen.dart';
import 'tax_invoices_screen.dart';

/// 매장 로그인 후 홈 — 업무 대분류 하단 네비게이션 셸.
/// 탭: 홈(요약) · 발주·매입 · 입고·재고 · 전자문서
class StoreHome extends StatefulWidget {
  const StoreHome({
    super.key,
    required this.storeName,
    required this.order,
    required this.ops,
    required this.cart,
    required this.unread,
    required this.onNotifications,
    required this.onChat,
    required this.onLogout,
  });

  final String storeName;
  final OrderRepository order;
  final StoreOpsRepository ops;
  final CartController cart;
  final int unread;
  final VoidCallback onNotifications;
  final VoidCallback onChat;
  final VoidCallback onLogout;

  @override
  State<StoreHome> createState() => _StoreHomeState();
}

class _StoreHomeState extends State<StoreHome> {
  late Future<StoreDashboard> _dash;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _dash = widget.ops.dashboard();
  }

  Future<void> _refresh() async {
    setState(() => _dash = widget.ops.dashboard());
    await _dash;
  }

  void _push(BuildContext context, Widget screen) =>
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => screen))
          .then((_) => _refresh());

  Widget _grid(List<Widget> cards) => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.25,
        children: cards,
      );

  /// 각 탭은 동일한 헤더·새로고침·하단 여백 패턴을 공유.
  Widget _tabBody(List<Widget> children) {
    final bottom = 28 + MediaQuery.of(context).padding.bottom;
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _refresh,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottom),
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          DashboardHeader(
            greeting: '안녕하세요 👋',
            name: widget.storeName,
            tagline: '물품 발주 · 매장',
            unread: widget.unread,
            onNotifications: widget.onNotifications,
            onChat: widget.onChat,
            onLogout: widget.onLogout,
          ),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: [
                _homeTab(),
                _orderPurchaseTab(),
                _inboundStockTab(),
                _docsTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _bottomNav() => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.surface,
            currentIndex: _tab,
            selectedItemColor: AppColors.accent,
            unselectedItemColor: AppColors.inkSoft,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            onTap: (i) => setState(() => _tab = i),
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard_rounded),
                  label: '홈'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_outlined),
                  activeIcon: Icon(Icons.receipt_long),
                  label: '발주·매입'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.inventory_2_outlined),
                  activeIcon: Icon(Icons.inventory_2),
                  label: '입고·재고'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.description_outlined),
                  activeIcon: Icon(Icons.description),
                  label: '전자문서'),
            ],
          ),
        ),
      );

  // ── 홈(요약) ──
  Widget _homeTab() => _tabBody([
        FutureBuilder<StoreDashboard>(
          future: _dash,
          builder: (context, snap) {
            final d = snap.data;
            return Column(children: [
              Row(children: [
                _StoreStat(
                    label: '진행중 발주',
                    value: d?.activeOrders,
                    hint: '처리중',
                    color: AppColors.mango600,
                    onTap: () => _push(context,
                        OrdersScreen(repository: widget.order, activeOnly: true))),
                const SizedBox(width: 12),
                _StoreStat(
                    label: '입고 대기',
                    value: d?.inTransit,
                    hint: '배송중',
                    color: const Color(0xFF1E8E4E),
                    onTap: () => _push(context, InboundScreen(repository: widget.ops))),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                _StoreStat(
                    label: '재고 품목',
                    value: d?.inventoryItems,
                    hint: '부족 ${d?.lowStock ?? '-'}',
                    color: const Color(0xFF1B6CC4),
                    onTap: () => _push(context, InventoryScreen(repository: widget.ops))),
                const SizedBox(width: 12),
                _StoreStat(
                    label: '이번 달 매입',
                    valueText: d == null ? null : won(d.monthAmount),
                    hint: '합계',
                    color: AppColors.mango700,
                    onTap: () => _push(
                        context,
                        PurchasesScreen(
                            repository: widget.ops,
                            orderRepository: widget.order,
                            initialPeriod: 'month'))),
              ]),
            ]);
          },
        ),
        const SizedBox(height: 20),
        _PrimaryCta(
          onTap: () => _push(
              context, CatalogScreen(repository: widget.order, cart: widget.cart)),
        ),
      ]);

  // ── 발주·매입 ──
  Widget _orderPurchaseTab() => _tabBody([
        _PrimaryCta(
          onTap: () => _push(
              context, CatalogScreen(repository: widget.order, cart: widget.cart)),
        ),
        const SizedBox(height: 16),
        _grid([
          _FeatureCard(
            icon: Icons.receipt_long_outlined,
            title: '발주 내역',
            sub: '주문·수정·취소',
            onTap: () => _push(context, OrdersScreen(repository: widget.order)),
          ),
          _FeatureCard(
            icon: Icons.payments_outlined,
            title: '매입 내역',
            sub: '기간별 합계',
            onTap: () => _push(context,
                PurchasesScreen(repository: widget.ops, orderRepository: widget.order)),
          ),
        ]),
      ]);

  // ── 입고·재고 ──
  Widget _inboundStockTab() => _tabBody([
        _grid([
          _FeatureCard(
            icon: Icons.local_shipping_outlined,
            title: '입고 예정',
            sub: '배송중·입고처리',
            onTap: () => _push(context, InboundScreen(repository: widget.ops)),
          ),
          _FeatureCard(
            icon: Icons.inventory_2_outlined,
            title: '재고',
            sub: '현황·사용',
            onTap: () => _push(context, InventoryScreen(repository: widget.ops)),
          ),
        ]),
      ]);

  // ── 전자문서 ──
  Widget _docsTab() => _tabBody([
        _grid([
          _FeatureCard(
            icon: Icons.description_outlined,
            title: '세금계산서',
            sub: '본사 발행분',
            onTap: () => _push(context, TaxInvoicesScreen(repository: widget.ops)),
          ),
        ]),
      ]);
}

class _StoreStat extends StatelessWidget {
  const _StoreStat({
    required this.label,
    required this.hint,
    required this.color,
    this.value,
    this.valueText,
    this.onTap,
  });
  final String label;
  final String hint;
  final Color color;
  final int? value;
  final String? valueText;
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
            padding: const EdgeInsets.all(14),
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
                              fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
                    ),
                    if (onTap != null)
                      const Icon(Icons.chevron_right, size: 16, color: AppColors.inkSoft),
                  ],
                ),
                const SizedBox(height: 6),
                Text(valueText ?? (value?.toString() ?? '–'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: valueText != null ? 18 : 26,
                        fontWeight: FontWeight.w800,
                        color: color,
                        height: 1)),
                const SizedBox(height: 3),
                Text(hint, style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.mango600, AppColors.mango700],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33F2784B),
                blurRadius: 22,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Text('🛒', style: TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('물품 발주하기',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    SizedBox(height: 4),
                    Text('카탈로그에서 담아 발주 접수',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
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
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
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
                  color: AppColors.mango100,
                  borderRadius: BorderRadius.circular(12),
                ),
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
