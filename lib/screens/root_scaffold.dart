import 'package:flutter/material.dart';

import '../data/auth_controller.dart';
import '../data/cart_controller.dart';
import '../data/content_repository.dart';
import '../data/menu_repository.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';
import 'menu_screen.dart';
import 'order/order_hub.dart';

/// 하단 탭(홈 · 메뉴 · 발주)을 가진 루트 화면.
class RootScaffold extends StatefulWidget {
  const RootScaffold({
    super.key,
    required this.repository,
    required this.auth,
  });

  final MenuRepository repository;
  final AuthController auth;

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  int _index = 0;
  final _cart = CartController();
  final _content = ContentRepository();

  void _goMenu() => setState(() => _index = 1);

  @override
  void dispose() {
    _cart.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        repository: widget.repository,
        content: _content,
        onSeeMenu: _goMenu,
      ),
      MenuScreen(repository: widget.repository),
      OrderHub(auth: widget.auth, cart: _cart),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: SafeArea(
          top: false,
          // 로그인 상태에 따라 3번째 탭(로그인 ↔ 발주/발주처리)을 갱신
          child: ListenableBuilder(
            listenable: widget.auth,
            builder: (context, _) {
              final third = _thirdTab(widget.auth);
              return BottomNavigationBar(
                currentIndex: _index,
                onTap: (i) => setState(() => _index = i),
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home_rounded),
                    label: '홈',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.icecream_outlined),
                    activeIcon: Icon(Icons.icecream_rounded),
                    label: '메뉴',
                  ),
                  third,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _thirdTab(AuthController auth) {
    if (!auth.isLoggedIn) {
      return const BottomNavigationBarItem(
        icon: Icon(Icons.login_outlined),
        activeIcon: Icon(Icons.login_rounded),
        label: '로그인',
      );
    }
    final isStore = auth.user?.isStore ?? false;
    return BottomNavigationBarItem(
      icon: Icon(isStore ? Icons.inventory_2_outlined : Icons.assignment_outlined),
      activeIcon: Icon(isStore ? Icons.inventory_2_rounded : Icons.assignment_rounded),
      label: isStore ? '발주' : '발주처리',
    );
  }
}
