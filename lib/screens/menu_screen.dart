import 'package:flutter/material.dart';

import '../data/menu_repository.dart';
import '../models/menu_item.dart';
import '../theme/app_colors.dart';
import '../widgets/menu_card.dart';
import 'menu_detail_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key, required this.repository});

  final MenuRepository repository;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late Future<List<MenuItem>> _future;
  List<MenuCategory> _categories = const [];
  String _selected = 'all';

  @override
  void initState() {
    super.initState();
    _future = widget.repository.menus();
    widget.repository.categories().then((c) {
      if (mounted) setState(() => _categories = c);
    });
  }

  void _select(String key) {
    setState(() {
      _selected = key;
      _future = widget.repository.menus(category: key);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <MenuCategory>[
      const MenuCategory(key: 'all', label: '전체'),
      ..._categories,
    ];

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                '메뉴',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                '사계절 즐기는 프리미엄 망고 디저트',
                style: TextStyle(fontSize: 14, color: AppColors.inkSoft),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: tabs.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final t = tabs[i];
                  final active = t.key == _selected;
                  return _CategoryTab(
                    label: t.label,
                    active: active,
                    onTap: () => _select(t.key),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<MenuItem>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    );
                  }
                  final items = snap.data ?? const [];
                  if (items.isEmpty) {
                    return const Center(
                      child: Text('메뉴가 없습니다',
                          style: TextStyle(color: AppColors.inkSoft)),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.66,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, i) => MenuCard(
                      item: items[i],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MenuDetailScreen(
                            item: items[i],
                            heroTag: 'menu-grid-${items[i].id}',
                          ),
                        ),
                      ),
                    ),
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

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          gradient: active ? AppColors.heroGradient : null,
          color: active ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: active ? Colors.transparent : AppColors.line,
          ),
          boxShadow: active
              ? const [
                  BoxShadow(
                    color: Color(0x33F2784B),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }
}
