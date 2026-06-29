import 'package:flutter/material.dart';

import '../../data/content_repository.dart';
import '../../models/content.dart';
import '../../theme/app_colors.dart';

class StoreLocatorScreen extends StatefulWidget {
  const StoreLocatorScreen({super.key, required this.repository});

  final ContentRepository repository;

  @override
  State<StoreLocatorScreen> createState() => _StoreLocatorScreenState();
}

class _StoreLocatorScreenState extends State<StoreLocatorScreen> {
  late Future<({List<StoreLocation> stores, List<String> regions})> _future;
  String _region = 'all';
  String _q = '';

  @override
  void initState() {
    super.initState();
    _future = widget.repository.stores();
  }

  void _reload() {
    setState(() { _future = widget.repository.stores(region: _region, q: _q); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('매장 찾기')),
      body: FutureBuilder<({List<StoreLocation> stores, List<String> regions})>(
        future: _future,
        builder: (context, snap) {
          final regions = <String>['all', ...?snap.data?.regions];
          final stores = snap.data?.stores ?? const [];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: TextField(
                  onChanged: (v) => _q = v,
                  onSubmitted: (_) => _reload(),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: '매장명·주소 검색',
                    prefixIcon:
                        const Icon(Icons.search, color: AppColors.inkSoft),
                    filled: true,
                    fillColor: AppColors.surface,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.accent),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: regions.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final r = regions[i];
                    final label = r == 'all' ? '전체' : r;
                    final active = r == _region;
                    return GestureDetector(
                      onTap: () {
                        _region = r;
                        _reload();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: active ? AppColors.accent : AppColors.surface,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                              color: active ? AppColors.accent : AppColors.line),
                        ),
                        child: Text(label,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color:
                                    active ? Colors.white : AppColors.inkSoft)),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: snap.connectionState == ConnectionState.waiting
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.accent))
                    : stores.isEmpty
                        ? const Center(
                            child: Text('매장이 없습니다',
                                style: TextStyle(color: AppColors.inkSoft)))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: stores.length,
                            itemBuilder: (context, i) =>
                                _StoreCard(store: stores[i]),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({required this.store});
  final StoreLocation store;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: AppColors.mango100,
                    borderRadius: BorderRadius.circular(6)),
                child: Text(store.region,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mango800)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(store.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _row(Icons.place_outlined, store.address),
          if (store.hours != null && store.hours!.isNotEmpty)
            _row(Icons.schedule, store.hours!),
          if (store.phone != null && store.phone!.isNotEmpty)
            _row(Icons.call_outlined, store.phone!),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 15, color: AppColors.inkSoft),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.ink, height: 1.4)),
            ),
          ],
        ),
      );
}
