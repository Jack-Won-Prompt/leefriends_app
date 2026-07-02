import 'package:flutter/material.dart';

import '../../data/cart_controller.dart';
import '../../data/order_repository.dart';
import '../../models/supply_product.dart';
import '../../theme/app_colors.dart';
import 'cart_screen.dart';

/// 물품 카탈로그 — 대분류별 목록 + 장바구니 담기.
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({
    super.key,
    required this.repository,
    required this.cart,
  });

  final OrderRepository repository;
  final CartController cart;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late Future<List<ProductGroup>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.supplyProducts();
  }

  Future<void> _reload() async {
    setState(() { _future = widget.repository.supplyProducts(); });
    await _future;
  }

  void _openCart() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            CartScreen(repository: widget.repository, cart: widget.cart),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('물품 발주')),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
            color: AppColors.accent,
            onRefresh: _reload,
            child: FutureBuilder<List<ProductGroup>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  );
                }
                if (snap.hasError) {
                  return _ErrorView(
                    message: snap.error.toString(),
                    onRetry: _reload,
                  );
                }
                final groups = snap.data ?? const [];
                if (groups.isEmpty) {
                  return const Center(
                    child: Text('등록된 물품이 없습니다',
                        style: TextStyle(color: AppColors.inkSoft)),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  children: [
                    for (final g in groups) ...[
                      _GroupHeader(group: g),
                      for (final p in g.products)
                        _ProductTile(product: p, cart: widget.cart),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
        _CartBar(cart: widget.cart, onTap: _openCart),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group});
  final ProductGroup group;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
      child: Row(
        children: [
          Text(
            group.category,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          if (group.categoryCode != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.mango100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                group.categoryCode!,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mango800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
          const Spacer(),
          Text(
            '${group.products.length}개',
            style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

/// 품목 썸네일 (56x56, 라운드). 이미지 없거나 로드 실패 시 플레이스홀더.
class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 56,
        height: 56,
        color: AppColors.mango50,
        child: (url == null || url!.isEmpty)
            ? _placeholder()
            : Image.network(
                url!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : _placeholder(),
                errorBuilder: (context, _, _) => _placeholder(),
              ),
      ),
    );
  }

  Widget _placeholder() => const Center(
        child: Icon(Icons.inventory_2_outlined, color: AppColors.mango300, size: 24),
      );
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.cart});
  final SupplyProduct product;
  final CartController cart;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) {
        final line = cart.lineOf(product.id);
        final qty = line?.qty ?? 0;
        final unit = line?.unit ?? product.defaultUnit;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: qty > 0 ? AppColors.mango300 : AppColors.line,
              width: qty > 0 ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProductThumb(url: product.imageUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                product.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            if (product.spec != null &&
                                product.spec!.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text(
                                product.spec!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${product.code} · ${product.supplierName ?? product.supplyTypeLabel}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.inkSoft),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    product.isMarketPrice ? '싯가' : '${_won(unit.storePrice)}원',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (product.units.length > 1)
                    _UnitSelector(product: product, cart: cart, current: unit),
                  if (product.units.length > 1) const Spacer(),
                  if (product.units.length <= 1) const Spacer(),
                  if (qty == 0)
                    FilledButton.tonalIcon(
                      onPressed: () => cart.add(product, unit: unit),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.mango100,
                        foregroundColor: AppColors.mango800,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('담기',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    )
                  else
                    _QtyStepper(
                      qty: qty,
                      onMinus: () => cart.setQty(product.id, qty - 1),
                      onPlus: () => cart.setQty(product.id, qty + 1),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UnitSelector extends StatelessWidget {
  const _UnitSelector({
    required this.product,
    required this.cart,
    required this.current,
  });
  final SupplyProduct product;
  final CartController cart;
  final ProductUnit current;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: product.units.indexOf(current),
          isDense: true,
          borderRadius: BorderRadius.circular(12),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          items: [
            for (var i = 0; i < product.units.length; i++)
              DropdownMenuItem(
                value: i,
                child: Text(product.units[i].name),
              ),
          ],
          onChanged: (i) {
            if (i == null) return;
            final u = product.units[i];
            if (cart.qtyOf(product.id) > 0) {
              cart.setUnit(product.id, u);
            } else {
              cart.add(product, unit: u);
            }
          },
        ),
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.qty,
    required this.onMinus,
    required this.onPlus,
  });
  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.mango50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.mango300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepBtn(icon: Icons.remove, onTap: onMinus),
          SizedBox(
            width: 36,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
          _StepBtn(icon: Icons.add, onTap: onPlus),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 18, color: AppColors.mango800),
      ),
    );
  }
}

class _CartBar extends StatelessWidget {
  const _CartBar({required this.cart, required this.onTap});
  final CartController cart;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) {
        if (cart.isEmpty) return const SizedBox.shrink();
        return Container(
          color: AppColors.cream,
          padding: EdgeInsets.fromLTRB(
              16, 8, 16, 12 + MediaQuery.of(context).padding.bottom),
          child: FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text('${cart.count}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, color: Colors.white)),
                ),
                const SizedBox(width: 10),
                const Text('장바구니 보기'),
                const Spacer(),
                Text('${_won(cart.totalAmount)}원'),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.cloud_off, size: 48, color: AppColors.inkSoft),
        const SizedBox(height: 12),
        Center(
          child: Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.inkSoft)),
        ),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
        ),
      ],
    );
  }
}

String _won(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}
