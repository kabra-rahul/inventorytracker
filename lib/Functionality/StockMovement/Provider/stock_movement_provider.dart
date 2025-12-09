import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventorytracker/Functionality/Supplier/Provider/supplier_provider.dart';
import 'package:inventorytracker/Provider/app_store_provider.dart';
import '../Service/stock_movement_service.dart';
import 'package:inventorytracker/Functionality/Stock/Model/batch_model.dart';


final stockMovementServiceProvider = FutureProvider<StockMovementService>((ref) async {
  final appStore = await ref.watch(appStoreProvider.future);
  if (appStore == null || appStore.companyId.isEmpty) {
    throw Exception('Company ID is empty for StockService initialization.');
  }
  return StockMovementService(companyId: appStore.companyId);
});


final suppliersMapProvider = FutureProvider<Map<String, String>>((ref) async {
  final supplierListAsync = await ref.watch(supplierListProvider.future); // Watch the StreamProvider from supplier_provider.dart

  return {
    for (var supplier in supplierListAsync.where((s) => s.active))
      supplier.id: supplier.companyName,
  };
  /*
  return supplierListAsyncValue.when(
    data: (supplierList) {
      return {
        for (var supplier in supplierList.where((s) => s.active))
          supplier.id: supplier.companyName, // Using companyName as per your model
      };
    },
    loading: () => {}, // Return empty map while loading
    error: (err, stack) {
      return {}; // Return empty map on error
    },
  );*/
});


final batchListProvider = FutureProvider.family<List<BatchModel>, BatchQuery>((ref, query) async {
  final service = await ref.read(stockMovementServiceProvider.future);
  final supplierMap = await ref.watch(suppliersMapProvider.future);
  return service.getBatches(
      query.warehouseId,
      query.productId,
      supplierMap
  );
});



class BatchQuery {
  final String warehouseId;
  final String productId;

  BatchQuery({
    required this.warehouseId,
    required this.productId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is BatchQuery &&
              runtimeType == other.runtimeType &&
              warehouseId == other.warehouseId &&
              productId == other.productId;

  @override
  int get hashCode => warehouseId.hashCode ^ productId.hashCode;
}