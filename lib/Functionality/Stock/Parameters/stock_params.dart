// For fetching a list of stocks
class StockListParams {
  final String warehouseId;
  final List<String> productIds; // Used for Firestore `whereIn` clause

  StockListParams({required this.warehouseId, required this.productIds});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is StockListParams &&
              runtimeType == other.runtimeType &&
              warehouseId == other.warehouseId &&
              productIds.toSet().containsAll(other.productIds.toSet()) &&
              other.productIds.toSet().containsAll(productIds.toSet());

  @override
  int get hashCode => Object.hash(warehouseId, Object.hashAll(productIds.toSet()));
}



// For fetching batches of a specific stock
class StockBatchesQuery {
  final String warehouseId;
  final String stockId;

  StockBatchesQuery({required this.warehouseId, required this.stockId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is StockBatchesQuery &&
              runtimeType == other.runtimeType &&
              warehouseId == other.warehouseId &&
              stockId == other.stockId;

  @override
  int get hashCode => warehouseId.hashCode ^ stockId.hashCode;
}




class StockSummaryParams {
  final String warehouseId;
  final String? productId;
  final String? categoryId;
  final bool showLowStock;

  StockSummaryParams({required this.warehouseId, required this.productId, required this.categoryId, required this.showLowStock});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is StockSummaryParams &&
              runtimeType  == other.runtimeType &&
              warehouseId  == other.warehouseId &&
              productId    == other.productId &&
              categoryId   == other.categoryId &&
              showLowStock == other.showLowStock;

  @override
  int get hashCode => Object.hash(warehouseId, productId, categoryId, showLowStock);
}