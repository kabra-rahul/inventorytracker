//dashboard_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventorytracker/Shared/Constants/firestore_constants.dart';
import '../Model/product_count_result.dart';


class DashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  Future<Map<String, String>> fetchWarehousesByIds(String companyId, List<String> warehouseIds) async {
    if (warehouseIds.isEmpty) return {};

    final warehouseSnap = await _firestore
        .collection(FirestoreConstants.companyCollection)
        .doc(companyId)
        .collection(FirestoreConstants.warehouseCollection)
        .where(FieldPath.documentId, whereIn: warehouseIds)
        .where(FirestoreConstants.activeField, isEqualTo: true)
        .get();

    return {for (var doc in warehouseSnap.docs) doc[FirestoreConstants.nameField] as String: doc.id};
  }


  /// Count number of products in a warehouse
  Stream<ProductCountResult> watchProductStats(String companyId, String warehouseId, String? categoryId) async* {
    final stockRef = _firestore
        .collection(FirestoreConstants.companyCollection)
        .doc(companyId)
        .collection(FirestoreConstants.warehouseCollection)
        .doc(warehouseId)
        .collection(FirestoreConstants.stockCollection);

    await for (final stockSnap in stockRef.snapshots()) {
      if (stockSnap.docs.isEmpty) {
        yield ProductCountResult(allProductIds: [], lowStockProductIds: []);
        continue;
      }

      // 1. Create productId -> quantity map
      final quantityMap = <String, double>{
        for (var doc in stockSnap.docs)
          doc[FirestoreConstants.stockProductIdField]: (doc[FirestoreConstants.stockTotalQuantityField] ?? 0) as double
      };

      final productIds = quantityMap.keys.toList();

      final int chunkSize = 25; // Firestore limit for whereIn clause
      final List<List<String>> productIdsChunks = [];
      for (int i = 0; i < productIds.length; i += chunkSize) {
        productIdsChunks.add(
          productIds.sublist(i, i + chunkSize > productIds.length ? productIds.length : i + chunkSize),
        );
      }


      final allProductDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      if (productIdsChunks.isNotEmpty) {
        for (final chunk in productIdsChunks) {
          if(categoryId == null || categoryId == '') {
            final chunkProductSnap = await _firestore
                .collection(FirestoreConstants.companyCollection)
                .doc(companyId)
                .collection(FirestoreConstants.productCollection)
                .where(FieldPath.documentId, whereIn: chunk)
                .where(FirestoreConstants.activeField, isEqualTo: true)
                .get();
            allProductDocs.addAll(chunkProductSnap.docs);
          } else {
            final chunkProductSnap = await _firestore
                .collection(FirestoreConstants.companyCollection)
                .doc(companyId)
                .collection(FirestoreConstants.productCollection)
                .where(FieldPath.documentId, whereIn: chunk)
                .where(FirestoreConstants.activeField, isEqualTo: true)
                .where(FirestoreConstants.productCategoryIdField, isEqualTo: categoryId)
                .get();
            allProductDocs.addAll(chunkProductSnap.docs);
          }
        }
      }

      final allProductIds = <String>[];
      final lowStockProductIds = <String>[];

      for (var doc in allProductDocs) {
        final productId = doc.id;
        final lowStockAlert = (doc[FirestoreConstants.productLowStockAlertField] ?? 0) as double;
        final qty = quantityMap[productId] ?? 0;

        allProductIds.add(productId);
        if (qty <= lowStockAlert) {
          lowStockProductIds.add(productId);
        }
      }

      yield ProductCountResult(
        allProductIds: allProductIds,
        lowStockProductIds: lowStockProductIds,
      );
    }
  }
}
