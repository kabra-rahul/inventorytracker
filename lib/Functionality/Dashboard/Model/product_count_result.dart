//product_count_result.dart
class ProductCountResult {
  final List<String> allProductIds;
  final List<String> lowStockProductIds;

  ProductCountResult({
    required this.allProductIds,
    required this.lowStockProductIds,
  });

  int get totalCount => allProductIds.length;
  int get lowStockCount => lowStockProductIds.length;
}