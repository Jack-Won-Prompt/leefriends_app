import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/content_repository.dart';
import '../data/menu_repository.dart';
import '../models/content.dart';
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
  late Future<List<BlogPostItem>> _blog;
  late Future<List<NaverClipItem>> _clips;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = widget.repository.menus();
    _blog = widget.content.blogPosts();
    _clips = widget.content.clips();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () async {
          setState(_load);
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
                  // 서버 홈과 동일: 리프렌즈 시그니처(category=signature) + 베스트 인기 메뉴
                  final signatures =
                      all.where((m) => m.category == 'signature').take(6).toList();
                  final sigIds = signatures.map((m) => m.id).toSet();
                  // 인기 메뉴는 시그니처와 중복 제외(Hero 태그 중복 방지) 후 상위 8
                  final populars =
                      all.where((m) => !sigIds.contains(m.id)).take(8).toList();

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
                      if (signatures.isNotEmpty) ...[
                        _SectionHeader(
                          title: '리프렌즈 시그니처',
                          subtitle: '가장 사랑받는 대표 메뉴',
                          onMore: widget.onSeeMenu,
                        ),
                        _HighlightList(items: signatures),
                        const SizedBox(height: 8),
                      ],
                      if (populars.isNotEmpty) ...[
                        _SectionHeader(
                          title: '베스트 인기 메뉴',
                          subtitle: '지금 가장 인기 있는 메뉴',
                          onMore: widget.onSeeMenu,
                        ),
                        _HighlightList(items: populars),
                      ],
                      _BlogSection(future: _blog),
                      _ClipSection(future: _clips),
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
          // 한 줄 고정 — 좁은 화면에선 축소되어 잘리지 않음
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                _HeroTag('🍧 100% 생망고'),
                SizedBox(width: 8),
                _HeroTag('❄️ 우유 눈꽃빙수'),
                SizedBox(width: 8),
                _HeroTag('🌿 사계절 운영'),
              ],
            ),
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
    // 세로로 전체 표시 (가로 스크롤 X)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [for (final it in items) _MenuRow(item: it)],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item});
  final MenuItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => MenuDetailScreen(item: item, heroTag: 'menu-home-${item.id}')),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line),
          boxShadow: const [
            BoxShadow(color: Color(0x0F000000), blurRadius: 14, offset: Offset(0, 6)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            SizedBox(
              width: 116,
              height: 100,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: AppColors.mango50,
                    child: Hero(
                      tag: 'menu-home-${item.id}',
                      child: MenuImage(item: item),
                    ),
                  ),
                  if (item.badge != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: BadgeChip(badge: item.badge!),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        height: 1.3,
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
            ),
            const Padding(
              padding: EdgeInsets.only(right: 10),
              child: Icon(Icons.chevron_right, color: AppColors.inkSoft),
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

Future<void> _openUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('링크를 열 수 없습니다.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFFB02A2A)));
    }
  }
}

/// 네이버 블로그 가로 카드 섹션 (없으면 렌더 안 함).
class _BlogSection extends StatelessWidget {
  const _BlogSection({required this.future});
  final Future<List<BlogPostItem>> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BlogPostItem>>(
      future: future,
      builder: (context, snap) {
        final items = snap.data ?? const <BlogPostItem>[];
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _SectionHeader(
              title: '망고정 블로그',
              subtitle: '네이버 블로그 소식',
              onMore: () => _openUrl(context, items.first.url),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  for (final b in items)
                    _FeedRow(
                      title: b.title,
                      thumbnail: b.thumbnail,
                      caption: b.postedAt,
                      onTap: () => _openUrl(context, b.url),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 네이버 클립 가로 카드 섹션 (없으면 렌더 안 함).
class _ClipSection extends StatelessWidget {
  const _ClipSection({required this.future});
  final Future<List<NaverClipItem>> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NaverClipItem>>(
      future: future,
      builder: (context, snap) {
        final items = snap.data ?? const <NaverClipItem>[];
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const _SectionHeader(title: '망고정 클립', subtitle: '짧은 영상으로 만나요'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  for (final c in items)
                    _FeedRow(
                      title: c.title,
                      thumbnail: c.thumbnail,
                      playIcon: true,
                      onTap: () => _openUrl(context, c.url),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 블로그/클립 공용 세로 행(썸네일 좌 + 제목/캡션 우).
class _FeedRow extends StatelessWidget {
  const _FeedRow({
    required this.title,
    required this.onTap,
    this.thumbnail,
    this.caption,
    this.playIcon = false,
  });
  final String title;
  final VoidCallback onTap;
  final String? thumbnail;
  final String? caption;
  final bool playIcon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            SizedBox(
              width: 128,
              height: 92,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  (thumbnail != null && thumbnail!.isNotEmpty)
                      ? Image.network(thumbnail!, fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                                color: AppColors.cream,
                                child: const Icon(Icons.image_outlined,
                                    color: AppColors.inkSoft),
                              ))
                      : Container(
                          color: AppColors.cream,
                          child: const Icon(Icons.article_outlined,
                              color: AppColors.inkSoft)),
                  if (playIcon)
                    const Center(
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.black45,
                        child: Icon(Icons.play_arrow, color: Colors.white, size: 20),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700, height: 1.35)),
                    if (caption != null && caption!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(caption!,
                          style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                    ],
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 10),
              child: Icon(Icons.chevron_right, color: AppColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}
