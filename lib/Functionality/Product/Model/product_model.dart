//product_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventorytracker/Shared/Constants/firestore_constants.dart';

class Product {
  final String id;
  final String name;
  final String categoryId;
  final String hsnId;
  final String unitId;
  final double lowStockAlert;
  final bool active;

  Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.hsnId,
    required this.unitId,
    required this.lowStockAlert,
    required this.active
  });

  factory Product.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Product(
      id           : doc.id,
      name         : data[FirestoreConstants.nameField] ?? '',
      categoryId   : data[FirestoreConstants.productCategoryIdField] ?? '',
      hsnId        : data[FirestoreConstants.productHsnIdField] ?? '',
      unitId       : data[FirestoreConstants.productUnitIdField] ?? '',
      lowStockAlert: (data[FirestoreConstants.productLowStockAlertField] ?? 0).toDouble(),
      active       : data[FirestoreConstants.activeField] ?? true,
    );
  }

  factory Product.fromMap(String id, Map<String, dynamic> map) {
    return Product(
      id           : id, // The ID is passed separately as it's typically the document ID
      name         : map[FirestoreConstants.nameField] as String? ?? '',
      categoryId   : map[FirestoreConstants.productCategoryIdField] as String? ?? '',
      hsnId        : map[FirestoreConstants.productHsnIdField] as String? ?? '',
      unitId       : map[FirestoreConstants.productUnitIdField] as String? ?? '',
      lowStockAlert: (map[FirestoreConstants.productLowStockAlertField] as num?)?.toDouble() ?? 0.0,
      active       : map[FirestoreConstants.activeField] as bool? ?? true,
    );
  }

  /// Converts the Product object to a Map for Firestore operations.
  Map<String, dynamic> toMap() {
    return {
      FirestoreConstants.nameField: name.toUpperCase(),
      FirestoreConstants.productCategoryIdField: categoryId,
      FirestoreConstants.productHsnIdField: hsnId,
      FirestoreConstants.productUnitIdField: unitId,
      FirestoreConstants.productLowStockAlertField: lowStockAlert,
      FirestoreConstants.activeField: active
    };
  }


  Product copyWith({
    String? id,
    String? name,
    String? categoryId,
    String? hsnId,
    String? unitId,
    double? lowStockAlert,
    bool? active,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      hsnId: hsnId ?? this.hsnId,
      unitId: unitId ?? this.unitId,
      lowStockAlert: lowStockAlert ?? this.lowStockAlert,
      active: active ?? this.active,
    );
  }
}