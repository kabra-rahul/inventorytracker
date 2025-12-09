// stock_service.dart
import 'package:async/async.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventorytracker/Shared/Constants/firestore_constants.dart';
import '../Model/stock_model.dart';
import '../Model/batch_model.dart';
import '../../Product/Model/product_model.dart';

class StockService {
  final FirebaseFirestore _db;
  final String _companyId;

  StockService({
    required String companyId,
    FirebaseFirestore? firestore, // Allows injecting Firestore for testing
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _companyId = companyId;


  // Helper getter for the company document reference
  DocumentReference get _companyDocRef =>
      _db.collection(FirestoreConstants.companyCollection).doc(_companyId);


  // Helper getter for the base path to warehouses under this company
  CollectionReference<Map<String, dynamic>> _warehousesCollectionRef(
    String warehouseId,
  ) => _companyDocRef
      .collection(FirestoreConstants.warehouseCollection)
      .doc(warehouseId)
      .collection(FirestoreConstants.stockCollection);



  // Helper to chunk large lists for whereIn (limit is 10 or 30 depending on the plan)
  List<List<String>> _chunkList(List<String> list, int chunkSize) {
    List<List<String>> chunks = [];
    for (int i = 0; i < list.length; i += chunkSize) {
      chunks.add(
        list.sublist(
          i,
          i + chunkSize > list.length ? list.length : i + chunkSize,
        ),
      );
    }
    return chunks;
  }



  Stream<List<StockModel>> getStockList(
    String warehouseId,
    List<String> productIds,
  ) {
    final stockColRef = _warehousesCollectionRef(warehouseId);
    final stockChunks = _chunkList(productIds.toSet().toList(), 25);

    // Create a list of streams for each stock chunk query
    final List<Stream<QuerySnapshot<Map<String, dynamic>>>> stockStreams =
        stockChunks.map((chunk) {
          return stockColRef
              .where(FirestoreConstants.stockProductIdField, whereIn: chunk)
              .snapshots(); // Using snapshots for real-time
        }).toList();

    final mergedStockStream = StreamGroup.merge(stockStreams);
    final Map<List<String>, QuerySnapshot<Map<String, dynamic>>>latestStockSnapshotsByChunk = {};
    final Future<Map<String, Product>> productMapFuture = _fetchProductMap(productIds);

    return mergedStockStream.asyncMap((chunkSnapshot) async {
      // When a chunk stream emits, update its corresponding snapshot in the map
      final chunkKey = stockChunks.firstWhere(
        (chunk) => chunkSnapshot.docs.any(
          (doc) => chunk.contains(
            doc.data()[FirestoreConstants.stockProductIdField],
          ),
        ),
      );
      latestStockSnapshotsByChunk[chunkKey] = chunkSnapshot;

      // Combine all documents from the latest snapshots of all chunks
      final List<QueryDocumentSnapshot<Map<String, dynamic>>> allStockDocs =
          latestStockSnapshotsByChunk.values
              .expand((snapshot) => snapshot.docs)
              .toList();

      // Fetch all supporting lookup maps (product, category, hsn, unit) in parallel
      // We retrieve these from Futures here.
      final productMap = await productMapFuture;

      // Build StockModel list
      return allStockDocs.map((stockDoc) {
        final stockData = stockDoc.data();
        final productId = stockData[FirestoreConstants.stockProductIdField] as String;
        final product = productMap[productId];

        return StockModel.fromMap(stockDoc.id, stockData, product!, '', '', '');
      }).toList();
    });
  }



  Future<Map<String, Product>> _fetchProductMap(List<String> productIds) async {
    final productSnapshot =
        await _companyDocRef
            .collection(FirestoreConstants.productCollection)
            .where(FieldPath.documentId, whereIn: productIds,)
            .get();
    return {
      for (var doc in productSnapshot.docs)
        doc.id: Product.fromMap(doc.id, doc.data()),
    };
  }



  Future<List<BatchModel>> getBatches(
    String warehouseId,
    String stockId,
  ) async {
    final stockColRef = _warehousesCollectionRef(warehouseId);

    final batchSnap =
        await stockColRef
            .doc(stockId)
            .collection(FirestoreConstants.batchCollection)
            .where(FirestoreConstants.batchQuantityField, isGreaterThan: 0.0)
            .get();

    // Return batches
    List<BatchModel> batches = batchSnap.docs.map((d) {
      final data = d.data();
      String supplierName = '';
      return BatchModel.fromMap(d.id, data, supplierName);
    }).toList();

    batches.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));

    return batches;
  }



  Future<String?> getStockIdForProduct(
      String warehouseId,
      String productId,
      ) async {

    final QuerySnapshot<Map<String, dynamic>> snapshot = await _warehousesCollectionRef(warehouseId)
        .where(FirestoreConstants.stockProductIdField, isEqualTo: productId)
        .limit(1) // We only need one matching stock document
        .get();

    // If a document is found, return its ID; otherwise, return null.
    return snapshot.docs.firstOrNull?.id;
  }

}
