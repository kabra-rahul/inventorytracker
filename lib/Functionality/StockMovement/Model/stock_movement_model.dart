//stock_movement_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventorytracker/Shared/Constants/firestore_constants.dart';

class StockMovementModel {
  final String id;
  final String type;
  final String productId;
  final String warehouseId;
  final String stockId;
  final String clientId;
  final String supplierId;
  final List<BatchAffected> batchesAffected;
  final double totalQuantity;
  final double pricePerUnit;
  final DateTime date;
  final String performedBy;
  final DateTime? undoneDate;
  final String? undoneByUserId;
  final String? undoneReason;

  StockMovementModel({
    required this.id,
    required this.type,
    required this.productId,
    required this.warehouseId,
    required this.stockId,
    required this.clientId,
    required this.supplierId,
    required this.batchesAffected,
    required this.totalQuantity,
    required this.pricePerUnit,
    required this.date,
    required this.performedBy,
    this.undoneDate,
    this.undoneByUserId,
    this.undoneReason
  });

  factory StockMovementModel.fromMap(String id, Map<String, dynamic> map) {
    final batchList = (map[FirestoreConstants.transactionBatchAffectedField] as List<dynamic>? ?? [])
        .map((e) => BatchAffected.fromMap(e as Map<String, dynamic>))
        .toList();
    return StockMovementModel(
      id: id,
      type: map[FirestoreConstants.transactionTypeField] ?? '',
      productId: map[FirestoreConstants.transactionProductIdField] ?? '',
      warehouseId: map[FirestoreConstants.transactionWarehouseIdField] ?? '',
      stockId: map[FirestoreConstants.transactionStockIdField] ?? '',
      clientId: map[FirestoreConstants.transactionClientIdField] ?? '',
      supplierId: map[FirestoreConstants.transactionSupplierIdField] ?? '',
      batchesAffected: batchList,
      totalQuantity: (map[FirestoreConstants.transactionTotalQuantityField] as num?)?.toDouble() ?? 0.0,
      pricePerUnit: (map[FirestoreConstants.transactionPricePerUnitField] as num?)?.toDouble() ?? 0.0, // Safely cast to double
      date: (map[FirestoreConstants.transactionDateField] as Timestamp?)?.toDate() ?? DateTime.now(),
      performedBy: map[FirestoreConstants.transactionDoneByField] ?? '', // Use performedBy
      undoneDate   : (map[FirestoreConstants.undoTransactionDateField] as Timestamp?)?.toDate(),
      undoneByUserId: map[FirestoreConstants.undoTransactionDoneByField] as String?,
      undoneReason: map[FirestoreConstants.undoTransactionReasonField] as String?
    );
  }



  factory StockMovementModel.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return StockMovementModel(
      id: doc.id,
      type: map[FirestoreConstants.transactionTypeField] ?? '',
      productId: map[FirestoreConstants.transactionProductIdField] ?? '',
      warehouseId: map[FirestoreConstants.transactionWarehouseIdField] ?? '',
      stockId: map[FirestoreConstants.transactionStockIdField] ?? '',
      clientId: map[FirestoreConstants.transactionClientIdField] ?? '',
      supplierId: map[FirestoreConstants.transactionSupplierIdField] ?? '',
      batchesAffected: (map[FirestoreConstants.transactionBatchAffectedField] as List<dynamic>? ?? [])
          .map((e) => BatchAffected.fromMap(e as Map<String, dynamic>))
          .toList(),
      // Ensure safe casting for totalQuantity and pricePerUnit
      totalQuantity: (map[FirestoreConstants.transactionTotalQuantityField] as num?)?.toDouble() ?? 0,
      pricePerUnit: (map[FirestoreConstants.transactionPricePerUnitField] as num?)?.toDouble() ?? 0.0,
      date: (map[FirestoreConstants.transactionDateField] as Timestamp?)?.toDate() ?? DateTime.now(), // Handle potential null Timestamp
      performedBy: map[FirestoreConstants.transactionDoneByField] ?? '',
    );
  }


  Map<String, dynamic> toMap() => {
    FirestoreConstants.transactionTypeField: type,
    FirestoreConstants.transactionProductIdField: productId,
    FirestoreConstants.transactionWarehouseIdField: warehouseId,
    FirestoreConstants.transactionStockIdField: stockId,
    FirestoreConstants.transactionClientIdField: clientId,
    FirestoreConstants.transactionSupplierIdField: supplierId,
    FirestoreConstants.transactionBatchAffectedField: batchesAffected.map((b) => b.toMap()).toList(),
    FirestoreConstants.transactionTotalQuantityField: totalQuantity,
    FirestoreConstants.transactionPricePerUnitField: pricePerUnit,
    FirestoreConstants.transactionDateField: Timestamp.fromDate(date),
    FirestoreConstants.transactionDoneByField: performedBy,
  };
}

class BatchAffected {
  final String batchId;
  final double quantity;

  BatchAffected({
    required this.batchId,
    required this.quantity,
  });

  factory BatchAffected.fromMap(Map<String, dynamic> map) => BatchAffected(
    batchId: map[FirestoreConstants.transactionBatchIdField] ?? '',
    quantity: map[FirestoreConstants.batchQuantityField] ?? 0,
  );

  Map<String, dynamic> toMap() => {
    FirestoreConstants.transactionBatchIdField: batchId,
    FirestoreConstants.batchQuantityField: quantity,
  };
}