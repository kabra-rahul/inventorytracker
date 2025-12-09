//supplier_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../Provider/app_store_provider.dart';
import '../Model/supplier_model.dart';
import '../Service/supplier_service.dart';


final supplierServiceProvider = Provider<SupplierService>((ref) => SupplierService());

final supplierListProvider = StreamProvider.autoDispose<List<Supplier>>((ref) {
  final appAsync = ref.watch(appStoreProvider);

  return appAsync.when(
    data: (app) {
      if (app == null || app.companyId.isEmpty) {
        return Stream.value([]);
      }
      return ref.read(supplierServiceProvider).getSupplierList(app.companyId);
    },
    loading: () => const Stream.empty(),
    error: (_, _) => const Stream.empty(),
  );
});


final allSuppliersMapProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  final suppliersList = await ref.watch(supplierListProvider.future);

  return {
    for (var supplier in suppliersList) supplier.id: supplier.companyName
  };
  /*return suppliersListAsync.when(
      data: (suppliers) {
        return Stream.value({for (var supplier in suppliers) supplier.id: supplier.companyName});
      },
      loading: () => const Stream.empty(), // Emit empty stream while loading
      error: (err, stack) => const Stream.empty() // Emit empty stream on error
  );*/
});


/// Provider to hold the Supplier being edited (if any).
/// - If editing an existing supplier → holds that Supplier.
/// - If adding new → holds `null`.
final editSupplierProvider = StateProvider<Supplier?>((ref) => null);


/// Provider to control whether Inactive Suppliers should be shown in the UI.
/// - If `true`, UI will include inactive suppliers in the list.
/// - If `false`, UI will show only active suppliers.
final showInactiveSuppliersProvider = StateProvider<bool>((ref) => false);


// StateProvider for the search query in the supplier list
final supplierSearchQueryProvider = StateProvider<String>((ref) => '');


// Combined provider for filtered and searched suppliers
final filteredSupplierListProvider = Provider.autoDispose<AsyncValue<List<Supplier>>>((ref) {
  // Watch the base stream provider, which gives an AsyncValue<List<Supplier>>
  final suppliersAsync = ref.watch(supplierListProvider);
  final showDisabled = ref.watch(showInactiveSuppliersProvider);
  final searchQuery = ref.watch(supplierSearchQueryProvider).toLowerCase();

  return suppliersAsync.whenData((suppliers) {
    final filtered = suppliers.where((s) => s.active || showDisabled).toList();
    if (searchQuery.isEmpty) return filtered;
    return filtered.where((s) => s.companyName.toLowerCase().contains(searchQuery)).toList();
  });
});