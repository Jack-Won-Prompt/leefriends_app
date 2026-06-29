/// 발주용 물품 단위 (예: BOX / EA).
class ProductUnit {
  final int? id;
  final String name;
  final int storePrice;
  final bool isDefault;

  const ProductUnit({
    required this.id,
    required this.name,
    required this.storePrice,
    required this.isDefault,
  });

  factory ProductUnit.fromJson(Map<String, dynamic> j) => ProductUnit(
        id: j['id'] as int?,
        name: j['name'] as String? ?? '',
        storePrice: (j['store_price'] as num?)?.toInt() ?? 0,
        isDefault: j['is_default'] as bool? ?? false,
      );
}

/// 발주용 물품(supply_product).
class SupplyProduct {
  final int id;
  final String code;
  final String name;
  final String category;
  final String? categoryCode;
  final String? spec;
  final String unit;
  final String supplyTypeLabel;
  final String? supplierName;
  final int storePrice;
  final bool isMarketPrice;
  final String? imageUrl;
  final List<ProductUnit> units;

  const SupplyProduct({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.categoryCode,
    required this.spec,
    required this.unit,
    required this.supplyTypeLabel,
    required this.supplierName,
    required this.storePrice,
    required this.isMarketPrice,
    required this.imageUrl,
    required this.units,
  });

  ProductUnit get defaultUnit =>
      units.firstWhere((u) => u.isDefault, orElse: () => units.first);

  factory SupplyProduct.fromJson(Map<String, dynamic> j) => SupplyProduct(
        id: j['id'] as int,
        code: j['code'] as String? ?? '',
        name: j['name'] as String? ?? '',
        category: j['category'] as String? ?? '',
        categoryCode: j['category_code'] as String?,
        spec: j['spec'] as String?,
        unit: j['unit'] as String? ?? '',
        supplyTypeLabel: j['supply_type_label'] as String? ?? '',
        supplierName: j['supplier_name'] as String?,
        storePrice: (j['store_price'] as num?)?.toInt() ?? 0,
        isMarketPrice: j['is_market_price'] as bool? ?? false,
        imageUrl: j['image'] as String?,
        units: (j['units'] as List? ?? [])
            .map((e) => ProductUnit.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// 대분류 그룹 (마카롱/쿠키/재료 …).
class ProductGroup {
  final String category;
  final String? categoryCode;
  final List<SupplyProduct> products;

  const ProductGroup({
    required this.category,
    required this.categoryCode,
    required this.products,
  });

  factory ProductGroup.fromJson(Map<String, dynamic> j) => ProductGroup(
        category: j['category'] as String? ?? '',
        categoryCode: j['category_code'] as String?,
        products: (j['products'] as List? ?? [])
            .map((e) => SupplyProduct.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
