// stock_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:inventorytracker/Functionality/Category/Provider/category_provider.dart';
import 'package:inventorytracker/Functionality/Dashboard/Provider/dashboard_provider.dart';
import 'package:inventorytracker/Functionality/Hsn/Provider/hsn_provider.dart';
import 'package:inventorytracker/Functionality/StockMovement/Provider/stock_movement_provider.dart';
import 'package:inventorytracker/Functionality/Units/Provider/unit_provider.dart';
import 'package:inventorytracker/Provider/app_store_provider.dart' hide appStoreDataProvider;
import 'package:inventorytracker/Shared/Constants/enums.dart';
import '../Parameters/stock_params.dart';
import '../Service/stock_service.dart';
import '../Model/stock_model.dart';
import '../Model/batch_model.dart';


final stockServiceProvider = FutureProvider<StockService>((ref) async {
  final appStore = await ref.watch(appStoreProvider.future);
  if (appStore == null || appStore.companyId.isEmpty) {
    throw Exception('Company ID is empty for StockService initialization.');
  }
  return StockService(companyId: appStore.companyId);
});




final stockListProvider = StreamProvider.autoDispose.family<List<StockModel>, StockListParams>((ref, params) async* {
  // If app data not ready or productIds empty, return empty stream
  if (params.productIds.isEmpty) {
    yield const []; // Use yield for async* streams
    return;
  }

  final stockService = await ref.read(stockServiceProvider.future);
  final rawStockStream = stockService.getStockList(params.warehouseId, params.productIds);
  final Future<Map<String, String>> categoryMapFuture = ref.watch(allCategoriesMapProvider.future);
  final Future<Map<String, String>> hsnMapFuture = ref.watch(allHsnsMapProvider.future);
  final Future<Map<String, String>> unitMapFuture = ref.watch(allUnitsMapProvider.future);

  await for (final rawStockList in rawStockStream) {
    final categoryMap = await categoryMapFuture;
    final hsnMap = await hsnMapFuture;
    final unitMap = await unitMapFuture;

    final mappedList = rawStockList.map((stock) {
      final categoryName = categoryMap[stock.categoryId];
      final hsnCode = hsnMap[stock.hsnId];
      final unitSymbol = unitMap[stock.unitId];

      return stock.copyWithStockDetailName(categoryName!, hsnCode!, unitSymbol!);
    }).toList();

    yield mappedList; // Yield the mapped list as a new emission
  }

  final link = ref.keepAlive();
  Timer(const Duration(hours: 24), () {
    link.close();
  });
});




final stockSummaryProvider = FutureProvider.family<List<StockModel>, StockSummaryParams>((ref, params) async {
  List<String> productIdsToFetch = [];
  //if(params.productId == null || params.productId == '' || params.productId?.trim().isEmpty == true) {

  final app = ref.watch(appStoreDataProvider);

  if (app == null) return [];

  final productCount = await ref
      .read(dashboardServiceProvider)
      .watchProductStats(app.companyId, params.warehouseId, params.categoryId)
      .first;

  if (params.showLowStock) {
    productIdsToFetch = productCount.lowStockProductIds;
  } else {
    productIdsToFetch = productCount.allProductIds;
  }

  if(params.productId != null) {
    productIdsToFetch = [];
    if(!productIdsToFetch.contains(params.productId)  &&  !params.showLowStock) {
      productIdsToFetch.add(params.productId!);
    }
  }

  if (productIdsToFetch.isEmpty) return [];

  final listParams = StockListParams(
    warehouseId: params.warehouseId,
    productIds: productIdsToFetch,
  );

  return await ref.watch(stockListProvider(listParams).future);
});



final stockBatchesProvider = FutureProvider.family<List<BatchModel>, StockBatchesQuery>((ref, query) async {
  final service = await ref.watch(stockServiceProvider.future);
  final supplierMap = await ref.watch(suppliersMapProvider.future);

  final rawBatchList = await service.getBatches(query.warehouseId, query.stockId);
  final mappedBatchList = rawBatchList.map((batch) {
    final supplierName = supplierMap[batch.supplierId] ?? '';

    return batch.copyWithSupplierName(supplierName);
  }).toList();

  return mappedBatchList;
});




final stockListModeProvider = StateProvider<StockListMode>((ref) => StockListMode.allStock);



// StateProvider for the search query in the stock list
final stockSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');



// Combined provider for filtered and searched stocks
final filteredStockListProvider = Provider.autoDispose.family<AsyncValue<List<StockModel>>, StockListParams>((ref,params) {
  final stocksAsync = ref.watch(stockListProvider(params));
  final searchQuery = ref.watch(stockSearchQueryProvider).toLowerCase();

  return stocksAsync.whenData((stocks) {
    if (searchQuery.isEmpty) return stocks;
    return stocks.where((s) =>
    s.name.toLowerCase().contains(searchQuery) ||
        s.hsn.toLowerCase().contains(searchQuery) ||
        s.category.toLowerCase().contains(searchQuery)
    ).toList();
  });
});