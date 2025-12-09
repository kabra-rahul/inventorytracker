//dashboard_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:inventorytracker/Model/app_store_model.dart';
import 'package:inventorytracker/Provider/app_store_provider.dart';
import '../Service/dashboard_service.dart';
import '../Model/product_count_result.dart';


final dashboardServiceProvider = Provider((_) => DashboardService());


typedef ProductCountParams = ({String? warehouseId, String? categoryId});


// Separate provider just to access AppStore's stream
final appStoreDataProvider = Provider<AppStore?>((ref) {
  final appAsync = ref.watch(appStoreProvider);
  return appAsync.whenOrNull(data: (data) => data);
});

// 🔁 Reactively stream warehouse data based on AppStore updates
final warehousesProvider = StreamProvider<Map<String, String>>((ref) async* {
  final app = ref.watch(appStoreDataProvider);

  if (app == null || app.companyId.isEmpty || app.warehouseIds.isEmpty) {
    yield {};
    return;
  }

  yield await ref.read(dashboardServiceProvider)
      .fetchWarehousesByIds(app.companyId, app.warehouseIds);
});


// Selected warehouse state
final selectedWarehouseProvider = StateProvider<String?>((ref) => null);


// Product count
final productCountProvider = StreamProvider.autoDispose.family<ProductCountResult, ProductCountParams>((ref, params) async* {
  final link = ref.keepAlive();
  final timer = Timer(const Duration(hours: 24), () => link.close());
  ref.onDispose(() => timer.cancel());

  final app = ref.watch(appStoreDataProvider);
  final selectedWarehouseId = ref.watch(selectedWarehouseProvider);
  final effectiveWarehouseId = params.warehouseId ?? selectedWarehouseId;

  try {
    if (app == null || app.companyId.isEmpty || effectiveWarehouseId == null || effectiveWarehouseId.isEmpty) {
      yield ProductCountResult(allProductIds: [], lowStockProductIds: []);
      return;
    }

    yield* ref.read(dashboardServiceProvider)
        .watchProductStats(app.companyId, effectiveWarehouseId, params.categoryId);
  } on Exception catch (e) {
    throw Exception(e);
  }

});
