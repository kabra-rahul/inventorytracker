import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../Provider/app_store_provider.dart';
import '../Model/warehouse_model.dart';
import '../Service/warehouse_service.dart';
import '../../User/Service/user_service.dart';

/// UserService provider that returns AsyncValue UserService
final userServiceProvider = FutureProvider<UserService>((ref) async {
  final appStore = await ref.watch(appStoreProvider.future);

  if (appStore == null || appStore.companyId.isEmpty) {
    throw Exception('Company ID is empty');
  }
  return UserService(companyId: appStore.companyId);
});


/// WarehouseService provider that depends on both appStore and userService
final warehouseServiceProvider = FutureProvider<WarehouseService>((ref) async {
  final appStore = await ref.watch(appStoreProvider.future);
  final userService = await ref.watch(userServiceProvider.future);

  if (appStore == null || appStore.companyId.isEmpty) {
    throw Exception('Company ID is empty');
  }
  return WarehouseService(
    companyId: appStore.companyId,
    userService: userService,
  );
});


/// Warehouse list stream from service
final warehouseListProvider = StreamProvider.autoDispose<List<Warehouse>>((ref,) async* {
  final warehouseService = await ref.watch(warehouseServiceProvider.future);
  yield* warehouseService.getWarehouseList();
});


final allWarehousesMapProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  // Get the actual list from the AsyncValue by awaiting its .future
  final warehousesList = await ref.watch(warehouseListProvider.future);
  // Now you can safely call .where() and map over it
  return {
    for (var wh in warehousesList.where((w) => w.active)) wh.id: wh.name,
  };
});


/// UI state Provider
final editWarehouseProvider = StateProvider<Warehouse?>((ref) => null);


final showAllWarehousesProvider = StateProvider<bool>((ref) => false);


final showInactiveWarehousesProvider = StateProvider<bool>((ref) => false);


final warehouseSearchQueryProvider = StateProvider<String>((ref) => '');

/// Combined filtered warehouse list
final filteredWarehouseListProvider = Provider.autoDispose<AsyncValue<List<Warehouse>>>((ref) {
  final warehousesAsync = ref.watch(warehouseListProvider);
  final showDisabled = ref.watch(showInactiveWarehousesProvider);
  final searchQuery = ref.watch(warehouseSearchQueryProvider).toLowerCase();

  return warehousesAsync.whenData((warehouses) {
    final filtered = warehouses.where((w) => w.active || showDisabled).toList();

    if (searchQuery.isEmpty) return filtered;

    return filtered.where((w) => w.name.toLowerCase().contains(searchQuery) || w.location.toLowerCase().contains(searchQuery)).toList();
  });
});