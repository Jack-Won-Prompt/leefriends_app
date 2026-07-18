import 'package:flutter/material.dart';

import '../data/app_version.dart';
import '../theme/app_colors.dart';

/// 로그인 후 대시보드 상단 헤더 — 인사말 + 이름 + 액션(메시지/알림/로그아웃).
/// 그라데이션 + 라운드 하단으로 최신 트렌드 톤.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.greeting,
    required this.name,
    required this.tagline,
    required this.unread,
    required this.onNotifications,
    required this.onChat,
    required this.onLogout,
    this.onSchedule,
  });

  final String greeting;
  final String name;
  final String tagline;
  final int unread;
  final VoidCallback onNotifications;
  final VoidCallback onChat;
  final VoidCallback onLogout;
  final VoidCallback? onSchedule;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, top + 14, 12, 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(greeting,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(tagline,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                  if (AppVersion.display.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(AppVersion.display,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 11,
                            fontWeight: FontWeight.w500)),
                  ],
                ],
              ),
            ),
          ),
          if (onSchedule != null)
            _IconBtn(icon: Icons.calendar_month_outlined, onTap: onSchedule!),
          _IconBtn(icon: Icons.forum_outlined, onTap: onChat),
          _NotifBtn(unread: unread, onTap: onNotifications),
          _IconBtn(icon: Icons.logout_rounded, onTap: onLogout),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
      splashRadius: 22,
    );
  }
}

class _NotifBtn extends StatelessWidget {
  const _NotifBtn({required this.unread, required this.onTap});
  final int unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          onPressed: onTap,
          icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
          splashRadius: 22,
        ),
        if (unread > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                unread > 99 ? '99+' : '$unread',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w800),
              ),
            ),
          ),
      ],
    );
  }
}
