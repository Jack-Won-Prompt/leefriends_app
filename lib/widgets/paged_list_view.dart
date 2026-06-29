import 'package:flutter/material.dart';

import '../models/paged.dart';
import '../theme/app_colors.dart';

/// 페이지네이션 + 당겨서 새로고침을 처리하는 재사용 리스트.
/// [fetch] 는 1부터 시작하는 페이지 번호를 받아 [Paged] 를 반환한다.
/// 필터가 바뀌면 부모에서 `key: ValueKey(filter)` 로 새로 생성하면 초기화된다.
class PagedListView<T> extends StatefulWidget {
  const PagedListView({
    super.key,
    required this.fetch,
    required this.itemBuilder,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 24),
    this.emptyText = '내역이 없습니다',
    this.emptyIcon = Icons.inbox_outlined,
    this.onLoaded,
  });

  final Future<Paged<T>> Function(int page) fetch;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final EdgeInsets padding;
  final String emptyText;
  final IconData emptyIcon;

  /// 첫 페이지 로드 후 전체 아이템 콜백(상태바·메타 갱신용, 선택).
  final void Function(List<T> items)? onLoaded;

  @override
  State<PagedListView<T>> createState() => _PagedListViewState<T>();
}

class _PagedListViewState<T> extends State<PagedListView<T>> {
  final _scroll = ScrollController();
  final List<T> _items = [];
  int _page = 1;
  bool _hasMore = true;
  bool _loading = false;
  bool _initialLoading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadFirst();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _loadFirst() async {
    setState(() {
      _initialLoading = true;
      _error = null;
    });
    try {
      final res = await widget.fetch(1);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(res.items);
        _page = 1;
        _hasMore = res.hasMore;
        _initialLoading = false;
      });
      widget.onLoaded?.call(List.unmodifiable(_items));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _initialLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    try {
      final res = await widget.fetch(1);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(res.items);
        _page = 1;
        _hasMore = res.hasMore;
        _error = null;
      });
      widget.onLoaded?.call(List.unmodifiable(_items));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore || _initialLoading) return;
    setState(() => _loading = true);
    try {
      final next = _page + 1;
      final res = await widget.fetch(next);
      if (!mounted) return;
      setState(() {
        _items.addAll(res.items);
        _page = next;
        _hasMore = res.hasMore;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false); // 다음 스크롤/탭에서 재시도
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initialLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }
    if (_error != null && _items.isEmpty) {
      return RefreshIndicator(
        color: AppColors.accent,
        onRefresh: _refresh,
        child: ListView(children: [
          const SizedBox(height: 140),
          Center(
            child: Text('불러오지 못했습니다\n${_error.toString().replaceFirst('OrderException: ', '')}',
                textAlign: TextAlign.center, style: const TextStyle(color: AppColors.inkSoft)),
          ),
        ]),
      );
    }
    if (_items.isEmpty) {
      return RefreshIndicator(
        color: AppColors.accent,
        onRefresh: _refresh,
        child: ListView(children: [
          const SizedBox(height: 140),
          Icon(widget.emptyIcon, size: 48, color: AppColors.inkSoft),
          const SizedBox(height: 12),
          Center(child: Text(widget.emptyText, style: const TextStyle(color: AppColors.inkSoft))),
        ]),
      );
    }

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scroll,
        padding: widget.padding,
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= _items.length) return _footer();
          return widget.itemBuilder(context, _items[i]);
        },
      ),
    );
  }

  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: _loading
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.accent))
            : OutlinedButton(
                onPressed: _loadMore,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.mango300),
                ),
                child: const Text('더 보기'),
              ),
      ),
    );
  }
}
