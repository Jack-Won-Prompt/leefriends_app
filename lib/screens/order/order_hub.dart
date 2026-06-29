import 'package:flutter/material.dart';

import '../../data/auth_controller.dart';
import '../../data/cart_controller.dart';
import '../../data/chat_repository.dart';
import '../../data/order_repository.dart';
import '../../data/seller_repository.dart';
import '../../data/store_ops_repository.dart';
import '../../theme/app_colors.dart';
import '../chat/chat_list_screen.dart';
import '../seller/seller_home.dart';
import '../store/notifications_screen.dart';
import '../store/store_home.dart';
import 'login_screen.dart';

/// 발주 탭의 진입점.
/// - 초기화 중: 로더
/// - 비로그인: 로그인 화면
/// - 매장 / 본사 / 공급처: 로그인 후 카드형 홈 대시보드
class OrderHub extends StatefulWidget {
  const OrderHub({super.key, required this.auth, required this.cart});

  final AuthController auth;
  final CartController cart;

  @override
  State<OrderHub> createState() => _OrderHubState();
}

class _OrderHubState extends State<OrderHub> {
  late final OrderRepository _repository = OrderRepository(auth: widget.auth);
  late final StoreOpsRepository _ops = StoreOpsRepository(auth: widget.auth);
  late final SellerRepository _seller = SellerRepository(auth: widget.auth);
  late final ChatRepository _chat = ChatRepository(auth: widget.auth);

  int _unread = 0;
  bool _unreadRequested = false;

  Future<void> _refreshUnread() async {
    try {
      final n = await _ops.unreadCount();
      if (mounted) setState(() => _unread = n);
    } catch (_) {}
  }

  void _openNotifications() => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            NotificationsScreen(repository: _ops, onChanged: _refreshUnread),
      ));

  void _openChat() => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChatListScreen(repository: _chat),
      ));

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.auth,
      builder: (context, _) {
        final auth = widget.auth;
        if (auth.initializing) {
          return const Scaffold(
            backgroundColor: AppColors.cream,
            body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
          );
        }
        if (!auth.isLoggedIn) {
          _unreadRequested = false;
          return LoginScreen(auth: auth);
        }

        // 로그인 후 1회 안읽음 개수 로드
        if (!_unreadRequested) {
          _unreadRequested = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => _refreshUnread());
        }

        final user = auth.user!;
        return Scaffold(
          backgroundColor: AppColors.cream,
          body: user.isStore
              ? StoreHome(
                  storeName: user.storeName ?? '매장',
                  order: _repository,
                  ops: _ops,
                  cart: widget.cart,
                  unread: _unread,
                  onNotifications: _openNotifications,
                  onChat: _openChat,
                  onLogout: () => _confirmLogout(auth),
                )
              : SellerHome(
                  repository: _seller,
                  name: user.name,
                  roleLabel: user.roleLabel,
                  unread: _unread,
                  onNotifications: _openNotifications,
                  onChat: _openChat,
                  onLogout: () => _confirmLogout(auth),
                  onChanged: _refreshUnread,
                ),
        );
      },
    );
  }

  Future<void> _confirmLogout(AuthController auth) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('로그아웃')),
        ],
      ),
    );
    if (ok == true) {
      widget.cart.clear();
      setState(() => _unread = 0);
      await auth.logout();
    }
  }
}
