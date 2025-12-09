//batch_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventorytracker/Shared/Constants/firestore_constants.dart';

class BatchModel {
  final String batchId;
  final String supplierId;
  final String supplierName;
  final String batchNumber;
  final double quantity;
  final double pricePerUnit;
  final DateTime purchaseDate;

  BatchModel({
    required this.batchId,
    required this.supplierId,
    required this.supplierName,
    required this.batchNumber,
    required this.quantity,
    required this.pricePerUnit,
    required this.purchaseDate,
  });

  /// Ensures value is rounded to 2 decimal places
  static double _roundToTwoDecimals(double value) =>
      double.parse(value.toStringAsFixed(2));

  factory BatchModel.fromMap(String batchId, Map<String, dynamic> map, String supplierName) {
    return BatchModel(
      batchId: batchId,
      supplierId: map[FirestoreConstants.batchSupplierIdField] ?? '',
      supplierName: supplierName,
      batchNumber: map[FirestoreConstants.batchNumberField] ?? '',
      quantity: _roundToTwoDecimals((map[FirestoreConstants.batchQuantityField] ?? 0).toDouble()),
      pricePerUnit: _roundToTwoDecimals((map[FirestoreConstants.batchPricePerUnitField] ?? 0).toDouble()),
      purchaseDate: (map[FirestoreConstants.batchPurchaseDateField] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      FirestoreConstants.batchSupplierIdField: supplierId,
      FirestoreConstants.batchNumberField: batchNumber,
      FirestoreConstants.batchQuantityField: _roundToTwoDecimals(quantity),
      FirestoreConstants.batchPricePerUnitField: _roundToTwoDecimals(pricePerUnit),
      FirestoreConstants.batchPurchaseDateField: purchaseDate,
    };
  }


  BatchModel copyWithSupplierName(String newSupplierName) {
    return BatchModel(
      batchId: batchId,
      supplierId: supplierId,
      supplierName: newSupplierName, // This is the field being updated
      batchNumber: batchNumber,
      quantity: quantity,
      pricePerUnit: pricePerUnit,
      purchaseDate: purchaseDate,
    );
  }
}
