import 'package:flutter/material.dart';

import '../models/menu_item.dart';
import '../theme/app_colors.dart';
import '../widgets/badge_chip.dart';
import '../widgets/menu_image.dart';

class MenuDetailScreen extends StatelessWidget {
  const MenuDetailScreen({super.key, required this.item, this.heroTag});

  final MenuItem item;

  /// 호출 화면별로 고유한 Hero 태그 (홈/메뉴 탭이 IndexedStack 으로 동시 마운트되어
  /// 같은 태그가 충돌하는 것을 방지). 없으면 기본값 사용.
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppColors.cream,
            leading: const _RoundBackButton(),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: heroTag ?? 'menu-${item.id}',
                child: Container(
                  decoration: const BoxDecoration(gradient: AppColors.warmGradient),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                    child: MenuImage(item: item, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              transform: Matrix4.translationValues(0, -24, 0),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Pill(text: item.categoryLabel),
                      const SizedBox(width: 8),
                      if (item.badge != null) BadgeChip(badge: item.badge!),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  if (item.nameEn != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.nameEn!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.inkSoft,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (item.description != null && item.description!.isNotEmpty)
                    Text(
                      item.description!,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: AppColors.ink,
                      ),
                    ),
                  const SizedBox(height: 28),
                  const Divider(),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        '가격',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.inkSoft,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        item.priceLabel,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: AppColors.cream,
        padding: EdgeInsets.fromLTRB(
            24, 12, 24, 16 + MediaQuery.of(context).padding.bottom),
        child: FilledButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${item.name} · 매장에서 만나보세요 🥭'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.mango800,
              ),
            );
          },
          icon: const Icon(Icons.storefront_outlined),
          label: const Text('가까운 매장에서 즐기기'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.mango100,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.mango800,
        ),
      ),
    );
  }
}

class _RoundBackButton extends StatelessWidget {
  const _RoundBackButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 1,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => Navigator.of(context).maybePop(),
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.ink),
          ),
        ),
      ),
    );
  }
}
