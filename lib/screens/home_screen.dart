import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/content_repository.dart';
import '../data/menu_repository.dart';
import '../models/menu_item.dart';
import '../theme/app_colors.dart';
import '../widgets/badge_chip.dart';
import '../widgets/menu_image.dart';
import 'consumer/notices_screen.dart';
import 'consumer/store_locator_screen.dart';
import 'menu_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.repository,
    required this.content,
    this.onSeeMenu,
  });

  final MenuRepository repository;
  final ContentRepository content;
  final VoidCallback? onSeeMenu;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<MenuItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.menus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () async {
          setState(() { _future = widget.repository.menus(); });
          await _future;
        },
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _Hero()),
            SliverToBoxAdapter(child: _QuickLinks(content: widget.content)),
            SliverToBoxAdapter(
              child: FutureBuilder<List<MenuItem>>(
                future: _future,
                builder: (context, snap) {
                  final all = snap.data ?? const <MenuItem>[];
                  final best = all
                      .where((m) => m.badge == 'best' || m.category == 'signature')
                      .take(6)
                      .toList();
                  final bestIds = best.map((m) => m.id).toSet();
                  // 베스트에 이미 포함된 항목은 신메뉴 목록에서 제외 (Hero 태그 중복 방지)
                  final fresh = all
                      .where((m) => m.badge == 'new' && !bestIds.contains(m.id))
                      .take(4)
                      .toList();

                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child:
                            CircularProgressIndicator(color: AppColors.accent),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(
                        title: '시그니처 & 베스트',
                        subtitle: '리프렌즈가 자신있게 추천하는 메뉴',
                        onMore: widget.onSeeMenu,
                      ),
                      _HighlightList(items: best),
                      if (fresh.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _SectionHeader(
                          title: '새로 나왔어요',
                          subtitle: '이번 시즌 신메뉴',
                          onMore: widget.onSeeMenu,
                        ),
                        _HighlightList(items: fresh),
                      ],
                      const SizedBox(height: 8),
                      const _BrandStory(),
                      const SizedBox(height: 32),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      padding: EdgeInsets.fromLTRB(24, top + 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text('🥭', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 10),
              const Text(
                'LEEFRIENDS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            '농익은 애플망고로\n만드는 프리미엄 빙수',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              height: 1.3,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '사계절 디저트 카페의 새로운 기준,\n리프렌즈에서 가장 신선한 망고를 만나보세요.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 14,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _HeroTag('🍧 100% 생망고'),
              _HeroTag('❄️ 우유 눈꽃빙수'),
              _HeroTag('🌿 사계절 운영'),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickLinks extends StatelessWidget {
  const _QuickLinks({required this.content});
  final ContentRepository content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _LinkCard(
              icon: Icons.campaign_outlined,
              label: '공지사항',
              sub: '소식·이벤트',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => NoticesScreen(repository: content)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _LinkCard(
              icon: Icons.place_outlined,
              label: '매장 찾기',
              sub: '가까운 매장',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => StoreLocatorScreen(repository: content)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({
    required this.icon,
    required this.label,
    required this.sub,
    required this.onTap,
  });
  final IconData icon;
  final String label;
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.mango100,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: AppColors.mango700, size: 22),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink)),
                  Text(sub,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.inkSoft)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  const _HeroTag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.onMore,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
          if (onMore != null)
            TextButton(
              onPressed: onMore,
              style: TextButton.styleFrom(foregroundColor: AppColors.accent),
              child: const Text('전체보기',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

class _HighlightList extends StatelessWidget {
  const _HighlightList({required this.items});
  final List<MenuItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 230,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, i) => _HighlightCard(item: items[i]),
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({required this.item});
  final MenuItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => MenuDetailScreen(item: item, heroTag: 'menu-home-${item.id}')),
      ),
      child: Container(
        width: 168,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.line),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.4,
                  child: Container(
                    color: AppColors.mango50,
                    child: Hero(
                      tag: 'menu-home-${item.id}',
                      child: MenuImage(item: item),
                    ),
                  ),
                ),
                if (item.badge != null)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: BadgeChip(badge: item.badge!),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.priceLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandStory extends StatelessWidget {
  const _BrandStory();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.mango900,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                'assets/images/brand/quality.svg',
                width: 40,
                height: 40,
                placeholderBuilder: (_) => const SizedBox(width: 40, height: 40),
              ),
              const SizedBox(width: 12),
              const Text(
                'LEEFRIENDS STORY',
                style: TextStyle(
                  color: AppColors.mango300,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '가장 좋은 망고만,\n가장 정직하게',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              height: 1.35,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '리프렌즈는 매일 엄선한 애플망고와 직접 만든 우유 눈꽃빙수로 '
            '사계절 변치 않는 맛을 전합니다. 신선함을 위한 타협 없는 기준이 '
            '우리의 자존심입니다.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
