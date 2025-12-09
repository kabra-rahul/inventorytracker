// stock_movement_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventorytracker/Functionality/Stock/Model/batch_model.dart';
import 'package:inventorytracker/Shared/Constants/firestore_constants.dart';
import 'package:inventorytracker/Shared/Constants/movement_constants.dart';
import '../../Stock/Parameters/stock_params.dart';
import '../../Stock/Provider/stock_provider.dart';
import '../../Transaction/Provider/transaction_provider.dart';
import '../Model/stock_movement_model.dart';
import '../Provider/stock_movement_provider.dart';

class StockMovementService {
  final FirebaseFirestore _db;
  final String _companyId; // Company ID for this service instance

  // Constructor now requires companyId
  StockMovementService({
    required String companyId,
    FirebaseFirestore? firestore, // Allows injecting Firestore for testing
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _companyId = companyId;


  // Helper getter for the company document reference
  DocumentReference get _companyDocRef => _db
      .collection(FirestoreConstants.companyCollection)
      .doc(_companyId);


  // Helper getter for the base path to warehouses under this company
  CollectionReference<Map<String, dynamic>> _warehousesCollectionRef(String warehouseId) =>
      _companyDocRef
          .collection(FirestoreConstants.warehouseCollection)
          .doc(warehouseId)
          .collection(FirestoreConstants.stockCollection);


  // Get batches for product
  Future<List<BatchModel>> getBatches(
      String warehouseId,
      String productId,
      Map<String, String> supplierMap) async {

    final stockColRef = _warehousesCollectionRef(warehouseId);

    final stockSnap = await stockColRef
        .where(FirestoreConstants.stockProductIdField, isEqualTo: productId)
        .get();

    if (stockSnap.docs.isEmpty) return [];

    final stockId = stockSnap.docs.first.id;

    final batchSnap = await stockColRef.doc(stockId).collection(FirestoreConstants.batchCollection)
        .where(FirestoreConstants.batchQuantityField, isGreaterThan: 0)
        .get();

    // Return batches
    return batchSnap.docs.map((d) {
      final data = d.data();
      final supplierId = data[FirestoreConstants.batchSupplierIdField] ?? '';
      final supplierName = supplierMap[supplierId] ?? '';

      return BatchModel.fromMap(
        d.id,
        data,
        supplierName,
      );
    }).toList();
  }


  // INWARD movement
  Future<void> inwardStock({
    required String warehouseId,
    required String productId,
    required String supplierId,
    required double quantity,
    required String batchNumber,
    required double pricePerUnit,
    required WidgetRef ref
  }) async {
    final User? currentUser = FirebaseAuth.instance.currentUser; // Get the nullable User object

    if (currentUser == null) {
      throw Exception('User Not Logged In. Cannot perform inward stock operation.');
    }

    // Now that currentUser is guaranteed non-null, you can safely access its uid
    final userId = currentUser.uid;

    final stockColRef = _warehousesCollectionRef(warehouseId);

    final stockSnap = await stockColRef.where(FirestoreConstants.stockProductIdField, isEqualTo: productId).get();

    String stockId;
    if (stockSnap.docs.isEmpty) {
      final newStockDoc = stockColRef.doc();
      stockId = newStockDoc.id;
      await newStockDoc.set({
        FirestoreConstants.stockProductIdField: productId,
        FirestoreConstants.stockTotalQuantityField: 0.0,
      });
    } else {
      stockId = stockSnap.docs.first.id;
    }

    final batchCol = stockColRef.doc(stockId).collection(FirestoreConstants.batchCollection);

    final batchSnap = await batchCol
        .where(FirestoreConstants.batchSupplierIdField, isEqualTo: supplierId)
        .where(FirestoreConstants.batchNumberField, isEqualTo: batchNumber)
        .where(FirestoreConstants.batchPricePerUnitField, isEqualTo: pricePerUnit)
        .limit(1)
        .get();

    final now = DateTime.now();
    final batchId = batchSnap.docs.isEmpty ? batchCol.doc().id : batchSnap.docs.first.id;
    final batchRef = batchCol.doc(batchId);

    await _db.runTransaction((txn) async {
      final stockDoc = await txn.get(stockColRef.doc(stockId));
      double currentQty = (stockDoc[FirestoreConstants.stockTotalQuantityField] as num?)?.toDouble() ?? 0.0;
      txn.update(stockColRef.doc(stockId), {FirestoreConstants.stockTotalQuantityField: currentQty + quantity});

      // Update or create batch
      if (batchSnap.docs.isEmpty) {
        txn.set(batchRef, {
          FirestoreConstants.batchSupplierIdField: supplierId,
          FirestoreConstants.batchNumberField: batchNumber,
          FirestoreConstants.batchQuantityField: quantity,
          FirestoreConstants.batchPricePerUnitField: pricePerUnit,
          FirestoreConstants.batchPurchaseDateField: now,
        });
      } else {
        final batchDoc = batchSnap.docs.first;
        final currentBatchQty = (batchDoc[FirestoreConstants.batchQuantityField] as num?)?.toDouble() ?? 0.0;
        /*final currentPricePerUnit = (batchDoc[FirestoreConstants.batchPricePerUnitField] as num?)?.toDouble() ?? 0.0;
        double price = currentPricePerUnit;
        if (pricePerUnit > 0 ) {
          price = pricePerUnit;
        }*/
        txn.update(batchRef, {
          FirestoreConstants.batchQuantityField: currentBatchQty + quantity,
          FirestoreConstants.batchPricePerUnitField: pricePerUnit,
          FirestoreConstants.batchPurchaseDateField: now,
        });
      }

      // Record stock movement
      final movementRef = _companyDocRef.collection(FirestoreConstants.transactionCollection).doc();
      final stockMovement = StockMovementModel(
        id: movementRef.id,
        type: MovementConstants.inwardMovement,
        productId: productId,
        warehouseId: warehouseId,
        stockId: stockId,
        clientId: '',
        supplierId: supplierId,
        batchesAffected: [
          BatchAffected(batchId: batchId, quantity: quantity),
        ],
        totalQuantity: quantity,
        pricePerUnit: pricePerUnit,
        date: now,
        performedBy: userId,
      );

      txn.set(movementRef, stockMovement.toMap());
    });

    final query = StockBatchesQuery(warehouseId: warehouseId, stockId: stockId);
    final recent = MovementQueryParams(warehouseId: warehouseId, type: MovementConstants.inwardMovement);

    ref.invalidate(stockBatchesProvider(query));
    ref.invalidate(recentMovementsProvider(recent));
  }


  // OUTWARD movement
  Future<void> outwardStock({
    required String warehouseId,
    required String productId,
    required List<BatchAffected> batchesAffected,
    required double totalQuantity,
    required clientId,
    required pricePerUnit,
    required WidgetRef ref
  }) async {
    final User? currentUser = FirebaseAuth.instance.currentUser; // Get the nullable User object

    if (currentUser == null) { // <--- FIX: Explicit null check
      throw Exception('User Not Logged In. Cannot perform inward stock operation.');
    }
    // Now that currentUser is guaranteed non-null, you can safely access its uid
    final userId = currentUser.uid;

    final stockColRef = _warehousesCollectionRef(warehouseId);
    final stockSnap = await stockColRef.where(FirestoreConstants.stockProductIdField, isEqualTo: productId).get();

    if (stockSnap.docs.isEmpty || batchesAffected.isEmpty) {
      throw Exception("Stock not found for product or no batches affected.");
    }

    final stockId = stockSnap.docs.first.id;
    final batchCol = stockColRef.doc(stockId).collection(FirestoreConstants.batchCollection);
    final stockDocRef = stockColRef.doc(stockId);

    await _db.runTransaction((txn) async {
      final stockDoc = await txn.get(stockDocRef);
      double currentQty = (stockDoc[FirestoreConstants.stockTotalQuantityField] as num?)?.toDouble() ?? 0.0;
      final Map<String, DocumentSnapshot> batchSnapshots = {};

      for (var batch in batchesAffected) {
        final batchRef = batchCol.doc(batch.batchId);
        final batchSnap = await txn.get(batchRef);
        batchSnapshots[batch.batchId] = batchSnap;
      }

      final double newTotalStockQty = double.parse((currentQty - totalQuantity).toStringAsFixed(2));

      if (newTotalStockQty < 0) {
        throw Exception("Total stock quantity check failed."); // Optional: add better message
      }

      final Map<String, double> newBatchQuantities = {};

      for (var batch in batchesAffected) {
        final batchSnap = batchSnapshots[batch.batchId];

        if (!batchSnap!.exists) {
          throw Exception('Batch with ID ${batch.batchId} not found during transaction.');
        }

        double currentQty = (batchSnap[FirestoreConstants.batchQuantityField] as num?)?.toDouble() ?? 0.0;
        final double newBatchQty = currentQty - batch.quantity;

        if (newBatchQty < 0) {
          throw Exception("Not enough quantity in batch ${batch.batchId}");
        }
        newBatchQuantities[batch.batchId] = newBatchQty;
      }

      txn.update(stockColRef.doc(stockId), {FirestoreConstants.stockTotalQuantityField: newTotalStockQty});

      for (var batch in batchesAffected) {
        final batchRef = batchCol.doc(batch.batchId);
        final newQty = newBatchQuantities[batch.batchId]!;
        txn.update(batchRef, {FirestoreConstants.batchQuantityField: newQty}); // WRITE
      }

      final movementRef = _db.collection(FirestoreConstants.companyCollection).doc(_companyId).collection(FirestoreConstants.transactionCollection).doc();
      final now = DateTime.now();
      final stockMovement = StockMovementModel(
        id: movementRef.id,
        type: MovementConstants.outwardMovement,
        productId: productId,
        warehouseId: warehouseId,
        stockId: stockId,
        clientId: clientId,
        supplierId: '',
        batchesAffected: batchesAffected,
        totalQuantity: totalQuantity,
        pricePerUnit: pricePerUnit,
        date: now,
        performedBy: userId,
      );

      txn.set(movementRef, stockMovement.toMap());
    });

    final query = StockBatchesQuery(warehouseId: warehouseId, stockId: stockId);
    final batchQuery = BatchQuery(warehouseId: warehouseId, productId: productId);
    final recent = MovementQueryParams(warehouseId: warehouseId, type: MovementConstants.outwardMovement);

    ref.invalidate(batchListProvider(batchQuery));
    ref.invalidate(stockBatchesProvider(query));
    ref.invalidate(recentMovementsProvider(recent));
  }
}
  /*
  // Get total stock quantity for a product
  Future<int> getTotalStock(String companyId, String warehouseId, String productId) async {
    final stockSnap = await _db
        .collection('companies/$companyId/warehouses/$warehouseId/stock')
        .where('productId', isEqualTo: productId)
        .get();

    if (stockSnap.docs.isEmpty) return 0;
    return (stockSnap.docs.first['totalQuantity'] as num).toInt();
  }*/
