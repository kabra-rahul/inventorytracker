//transaction_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventorytracker/Functionality/StockMovement/Model/stock_movement_model.dart';
import 'package:inventorytracker/Shared/Constants/firestore_constants.dart';
import 'package:inventorytracker/Shared/Constants/movement_constants.dart';
import 'package:inventorytracker/Shared/Constants/transaction_details_constants.dart';


class TransactionService {
  final FirebaseFirestore _db; // Now an instance member
  final String _companyId;
  final String _userId;

  TransactionService({
    required String companyId,
    required String userId,
    FirebaseFirestore? firestore,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _companyId = companyId,
        _userId = userId;


  CollectionReference<Map<String, dynamic>> _transactionCollectionRef() {
    return _db
        .collection(FirestoreConstants.companyCollection)
        .doc(_companyId)
        .collection(FirestoreConstants.transactionCollection);
  }

  CollectionReference<Map<String, dynamic>> _undoTransactionCollectionRef() {
    return _db
        .collection(FirestoreConstants.companyCollection)
        .doc(_companyId)
        .collection(FirestoreConstants.undoneTransactionCollection);
  }

// Helper to get product collection reference scoped by company
  CollectionReference<Map<String, dynamic>> _productCollectionRef() {
    return _db
        .collection(FirestoreConstants.companyCollection)
        .doc(_companyId)
        .collection(FirestoreConstants.productCollection); // Changed: Using constant
  }

  // Helper to get supplier collection reference scoped by company
  CollectionReference<Map<String, dynamic>> _supplierCollectionRef() {
    return _db
        .collection(FirestoreConstants.companyCollection)
        .doc(_companyId)
        .collection(FirestoreConstants.supplierCollection); // Changed: Using constant
  }

  CollectionReference<Map<String, dynamic>> _clientCollectionRef() {
    return _db
        .collection(FirestoreConstants.companyCollection)
        .doc(_companyId)
        .collection(FirestoreConstants.clientCollection); // Changed: Using constant
  }


  // Load recent 5 movements for a type (inward or outward)
  Future<Map<String, dynamic>> getRecentMovements({
    required String warehouseId,
    required String type, // inward or outward
  }) async {

    if (_companyId.isEmpty || warehouseId.isEmpty) {
    // Return an empty map gracefully if essential IDs are missing
    return {
            TransactionDetailsConstants.transactionDocuments: <StockMovementModel>[],
            TransactionDetailsConstants.productNames : {},
            TransactionDetailsConstants.unitSymbols  : {},
            TransactionDetailsConstants.supplierNames: {},
            TransactionDetailsConstants.clientNames  : {},
            TransactionDetailsConstants.batchNumber  : {},
            TransactionDetailsConstants.batchToSupplierId: {},
          };
    }

    // 1️⃣ Load recent 5 stockMovements
    final movementSnap = await _transactionCollectionRef()
        .where(FirestoreConstants.transactionWarehouseIdField, isEqualTo: warehouseId)
        .where(FirestoreConstants.transactionTypeField, isEqualTo: type)
        .orderBy(FirestoreConstants.transactionDateField, descending: true)
        .limit(5)
        .get();

    if (movementSnap.docs.isEmpty) {
      // Return an empty map gracefully if essential IDs are missing
      return {
        TransactionDetailsConstants.transactionDocuments: <StockMovementModel>[],
        TransactionDetailsConstants.productNames : {},
        TransactionDetailsConstants.unitSymbols  : {},
        TransactionDetailsConstants.supplierNames: {},
        TransactionDetailsConstants.clientNames  : {},
        TransactionDetailsConstants.batchNumber  : {},
        TransactionDetailsConstants.batchToSupplierId: {},
      };
    }

    final movements = movementSnap.docs.map((d) {
      return StockMovementModel.fromMap(d.id, d.data());
    }).toList();

    // 2️⃣ Get product names
    final List<String> productIdsInMovements = movements
        .map((m) => m.productId)
        .toSet()
        .where((id) => id.isNotEmpty)
        .toList();

    Map<String, String> productNames = {};
    Map<String, String> productUnitSymbols  = {};

    if (productIdsInMovements.isNotEmpty) {
      final productSnap = await _productCollectionRef()
          .where(FieldPath.documentId, whereIn: productIdsInMovements)
          .get();
      productNames = {
        for (var doc in productSnap.docs) doc.id: doc.data()[FirestoreConstants.nameField] ?? ''
      };

      final Map<String, String> productUnitIds = {
        for (var doc in productSnap.docs) doc.id: doc.data()[FirestoreConstants.productUnitIdField] ?? ''
      };

      final unitSnap = await _db
          .collection(FirestoreConstants.companyCollection)
          .doc(_companyId)
          .collection(FirestoreConstants.unitCollection).get();

      final Map<String, String> unitSymbols = {
        for (var doc in unitSnap.docs)
          doc.id: doc.data()[FirestoreConstants.symbolField] ?? ''
      };

      productUnitSymbols = {
        for (var entry in productUnitIds.entries)
          entry.key: unitSymbols[entry.value] ?? ''
      };
    }

    Map<String, String> clientNames = {};

    if(type == MovementConstants.outwardMovement) {
      final List<String> clientIdsInMovements = movements
          .map((m) => m.clientId)
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      if(clientIdsInMovements.isNotEmpty) {
        final clientSnap  = await _clientCollectionRef()
            .where(FieldPath.documentId, whereIn: clientIdsInMovements)
            .get();
        clientNames = {
          for (var doc in clientSnap.docs) doc.id: doc.data()[FirestoreConstants.companyNameField] ?? ''
        };
      }
    }

    final List<String> uniqueStockIds = movements.map((m) => m.stockId).toSet().toList();
    // 4️⃣ Parallel load all batch collections
    final batchFutures = uniqueStockIds.map((stockId) async {
      final batchSnap = await _db
          .collection(FirestoreConstants.companyCollection)
          .doc(_companyId)
          .collection(FirestoreConstants.warehouseCollection)
          .doc(warehouseId)
          .collection(FirestoreConstants.stockCollection)
          .doc(stockId)
          .collection(FirestoreConstants.batchCollection)
          .get();
      return batchSnap.docs;
    }).toList();

    final allBatchDocsLists = await Future.wait(batchFutures);

    // Flatten batch docs
    final allBatchDocs = allBatchDocsLists.expand((list) => list).toList();

    final batchNumber =  {
      for (var doc in allBatchDocs) doc.id: doc.data()[FirestoreConstants.batchNumberField]?.toString() ?? ''
    };

// Create map: batchId → supplierId
    final batchToSupplierId = {
      for (var doc in allBatchDocs)
        doc.id: (doc.data())[FirestoreConstants.batchSupplierIdField] ?? ''
    };

    final allSupplierIds = batchToSupplierId.values.where((id) => id.isNotEmpty).toSet().toList();

    // 6️⃣ Load supplier names in one query (if <= 10 suppliers)
    Map<String, String> supplierNames = {};

    if (allSupplierIds.isNotEmpty) {
      final supplierSnap = await _supplierCollectionRef()
          .where(FieldPath.documentId, whereIn: allSupplierIds)
          .get();

      supplierNames = {
        for (var doc in supplierSnap.docs) doc.id: doc.data()[FirestoreConstants.companyNameField] ?? ''
      };
    }

    return {
      TransactionDetailsConstants.transactionDocuments: movements,
      TransactionDetailsConstants.productNames        : productNames,
      TransactionDetailsConstants.unitSymbols         : productUnitSymbols,
      TransactionDetailsConstants.supplierNames       : supplierNames,
      TransactionDetailsConstants.clientNames         : clientNames,
      TransactionDetailsConstants.batchNumber         : batchNumber,
      TransactionDetailsConstants.batchToSupplierId   : batchToSupplierId,
    };
  }



  Future<void> undoMovement({
    required StockMovementModel movement,
    required String undoMovementReason,
  }) async {
    final stockCol = _db.collection(FirestoreConstants.companyCollection)
        .doc(_companyId)
        .collection(FirestoreConstants.warehouseCollection)
        .doc(movement.warehouseId)
        .collection(FirestoreConstants.stockCollection);

    final batchCol = stockCol.doc(movement.stockId).collection(FirestoreConstants.batchCollection);

    await _db.runTransaction((txn) async {
      // Update batches
      final List<DocumentSnapshot<Map<String, dynamic>>> batchSnapshots = [];
      final List<DocumentReference<Map<String, dynamic>>> batchRefs = [];

      for (var batch in movement.batchesAffected) {
        final batchRef = batchCol.doc(batch.batchId);
        final batchSnap = await txn.get(batchRef);
        batchSnapshots.add(batchSnap);
        batchRefs.add(batchRef);
      }

      // Update stock total
      final stockDoc = await txn.get(stockCol.doc(movement.stockId));

      for (int i = 0; i < movement.batchesAffected.length; i++) {
        final batch = movement.batchesAffected[i];
        final batchSnap = batchSnapshots[i];
        final batchRef = batchRefs[i];

        double currentQty = (batchSnap[FirestoreConstants.batchQuantityField] as num).toDouble();

        if (movement.type == MovementConstants.inwardMovement) {
          txn.update(batchRef, {FirestoreConstants.batchQuantityField: double.parse((currentQty - batch.quantity).toStringAsFixed(2))});
        } else {
          txn.update(batchRef, {FirestoreConstants.batchQuantityField: double.parse((currentQty + batch.quantity).toStringAsFixed(2))});
        }
      }

      double currentQty = (stockDoc[FirestoreConstants.stockTotalQuantityField] as num).toDouble();

      double newStockQty;
      if (movement.type == MovementConstants.inwardMovement) {
        // Inward movement undone -> decrease total stock
        newStockQty = currentQty - movement.totalQuantity;
      } else {
        // Outward movement undone -> increase total stock
        newStockQty = currentQty + movement.totalQuantity;
      }

      txn.update(stockCol.doc(movement.stockId), {FirestoreConstants.stockTotalQuantityField: double.parse(newStockQty.toStringAsFixed(2))});

      // Add undo transaction
      final undoRef = _db.collection(FirestoreConstants.companyCollection)
          .doc(_companyId)
          .collection(FirestoreConstants.undoneTransactionCollection) // Changed: Using constant
          .doc();

      txn.set(undoRef, {
        FirestoreConstants.transactionTypeField: movement.type,
        FirestoreConstants.transactionProductIdField: movement.productId,
        FirestoreConstants.transactionWarehouseIdField: movement.warehouseId,
        FirestoreConstants.transactionStockIdField: movement.stockId,
        FirestoreConstants.transactionClientIdField: movement.clientId,
        FirestoreConstants.transactionSupplierIdField: movement.supplierId,
        FirestoreConstants.transactionBatchAffectedField: movement.batchesAffected.map((b) => b.toMap()).toList(),
        FirestoreConstants.transactionTotalQuantityField: movement.totalQuantity,
        FirestoreConstants.transactionPricePerUnitField: movement.pricePerUnit,
        FirestoreConstants.transactionDateField: movement.date,
        FirestoreConstants.transactionDoneByField: movement.performedBy,
        FirestoreConstants.undoTransactionDateField: DateTime.now(),
        FirestoreConstants.undoTransactionDoneByField: _userId,
        FirestoreConstants.undoTransactionReasonField: undoMovementReason
      });

      // Delete stockMovement
      txn.delete(_transactionCollectionRef().doc(movement.id));
    });
  }



  Future<List<StockMovementModel>> getSupplierSellTransactions({
    String? supplierId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {

    final QuerySnapshot<Map<String, dynamic>> snapshot =  await _transactionCollectionRef()
        .where(FirestoreConstants.transactionSupplierIdField, isEqualTo: supplierId)
        .where(FirestoreConstants.transactionTypeField, isEqualTo: MovementConstants.inwardMovement)
        .where(FirestoreConstants.transactionDateField, isGreaterThanOrEqualTo: fromDate)
        .where(FirestoreConstants.transactionDateField, isLessThanOrEqualTo: toDate)
        .orderBy(FirestoreConstants.transactionDateField, descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return StockMovementModel.fromMap(doc.id, doc.data());
    }).toList();
  }



  Future<List<StockMovementModel>> getClientBuyTransactions({
    String? clientId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {

    final QuerySnapshot<Map<String, dynamic>> snapshot =  await _transactionCollectionRef()
        .where(FirestoreConstants.transactionClientIdField, isEqualTo: clientId)
        .where(FirestoreConstants.transactionTypeField, isEqualTo: MovementConstants.outwardMovement)
        .where(FirestoreConstants.transactionDateField, isGreaterThanOrEqualTo: fromDate)
        .where(FirestoreConstants.transactionDateField, isLessThanOrEqualTo: toDate)
        .orderBy(FirestoreConstants.transactionDateField, descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return StockMovementModel.fromMap(doc.id, doc.data());
    }).toList();
  }



  Future<List<StockMovementModel>> getTransactions({
    required DateTime fromDate,
    required DateTime toDate,
    required String transactionType,
    String? userId,
  }) async {

    Query query = _transactionCollectionRef();

    query = query.where(FirestoreConstants.transactionDateField, isGreaterThanOrEqualTo: fromDate);
    query = query.where(FirestoreConstants.transactionDateField, isLessThanOrEqualTo: toDate.add(const Duration(days: 1, microseconds: -1)));

    if (transactionType == 'Inward') {
      query = query.where(FirestoreConstants.transactionTypeField, isEqualTo: MovementConstants.inwardMovement);
    } else if (transactionType == 'Outward') {
      query = query.where(FirestoreConstants.transactionTypeField, isEqualTo: MovementConstants.outwardMovement);
    }

    // Filter by user (if provided)
    if (userId != null && userId.isNotEmpty) {
      query = query.where(FirestoreConstants.transactionDoneByField, isEqualTo: userId); // Assuming transactionUserIdField
    }

    query = query.orderBy(FirestoreConstants.transactionDateField, descending: true);


    final QuerySnapshot<Object?> rawSnapshot = await query.get();
    final QuerySnapshot<Map<String, dynamic>> snapshot = rawSnapshot as QuerySnapshot<Map<String, dynamic>>;

    return snapshot.docs.map((doc) {
      return StockMovementModel.fromMap(doc.id, doc.data());
    }).toList();
  }



  Future<List<StockMovementModel>> getUndoTransactions({
    required DateTime fromDate,
    required DateTime toDate,
    String? userId,
  }) async {

    Query query = _undoTransactionCollectionRef();

    query = query.where(FirestoreConstants.transactionDateField, isGreaterThanOrEqualTo: fromDate);
    query = query.where(FirestoreConstants.transactionDateField, isLessThanOrEqualTo: toDate.add(const Duration(days: 1, microseconds: -1)));


    // Filter by user (if provided)
    if (userId != null && userId.isNotEmpty) {
      query = query.where(FirestoreConstants.transactionDoneByField, isEqualTo: userId); // Assuming transactionUserIdField
    }

    query = query.orderBy(FirestoreConstants.transactionDateField, descending: true);


    final QuerySnapshot<Object?> rawSnapshot = await query.get();
    final QuerySnapshot<Map<String, dynamic>> snapshot = rawSnapshot as QuerySnapshot<Map<String, dynamic>>;

    return snapshot.docs.map((doc) {
      return StockMovementModel.fromMap(doc.id, doc.data());
    }).toList();
  }
}
