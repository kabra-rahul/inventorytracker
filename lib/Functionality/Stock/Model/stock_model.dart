//stock_model.dart
import 'package:inventorytracker/Functionality/Product/Model/product_model.dart';
import 'package:inventorytracker/Shared/Constants/firestore_constants.dart';

class StockModel {
  final String stockId;
  final String productId;
  final String name;
  final String categoryId;
  final String category;
  final String hsnId;
  final String hsn;
  final String unitId;
  final String unit;
  final double lowStockAlert;
  final double totalQuantity;

  StockModel({
    required this.stockId,
    required this.productId,
    required this.name,
    required this.categoryId,
    required this.category,
    required this.hsnId,
    required this.hsn,
    required this.unitId,
    required this.unit,
    required this.lowStockAlert,
    required this.totalQuantity,
  });

  factory StockModel.fromMap(
      String stockId,
      Map<String, dynamic> stockData,
      Product productData,
      String categoryName,
      String hsnCode,
      String unitSymbol,
      ) {
    return StockModel(
      stockId: stockId,
      productId: stockData[FirestoreConstants.stockProductIdField],
      name: productData.name,
      categoryId: productData.categoryId,
      category: categoryName,
      hsnId: productData.hsnId,
      hsn: hsnCode,
      unitId: productData.unitId,
      unit: unitSymbol,
      lowStockAlert: (productData.lowStockAlert).toDouble(),
      totalQuantity: (stockData[FirestoreConstants.stockTotalQuantityField] ?? 0).toDouble(),
    );
  }

  StockModel copyWithStockDetailName(
    String categoryName,
    String hsnCode,
    String unitSymbol,
  ) {
    return StockModel(
      stockId: stockId,
      productId: productId,
      name: name,
      categoryId: categoryId,
      category: categoryName,
      hsnId: hsnId,
      hsn: hsnCode,      // Use new value if provided, else keep old
      unitId: unitId,
      unit: unitSymbol,
      lowStockAlert: lowStockAlert,
      totalQuantity: totalQuantity
    );
  }
}