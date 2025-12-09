//product_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:inventorytracker/Service/dropdown_service.dart';
import 'package:inventorytracker/Shared/Constants/firestore_constants.dart';
import 'package:inventorytracker/Provider/app_store_provider.dart';
import '../Model/product_model.dart';
import '../../../Model/dropdown_item_model.dart';
import '../Service/product_service.dart';


final productServiceProvider = FutureProvider<ProductService>((ref) async {

  final appStore = await ref.watch(appStoreProvider.future);

  if (appStore == null || appStore.companyId.isEmpty) {
    throw Exception("Company ID is empty for ProductService initialization.");
  }
  return ProductService(companyId: appStore.companyId);
});


final productListProvider = StreamProvider.autoDispose<List<Product>>((ref) {
  final productServiceAsync = ref.watch(productServiceProvider);
  return productServiceAsync.when(
    data: (service) => service.getProductList(),
    loading: () => const Stream.empty(),
    error: (err, stack) {
      return Stream.fromFuture(Future.error(err, stack));
    },
  );
});


final allProductsMapProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final productList = await ref.watch(productListProvider.future);
  return {
          for (var product in productList.where((p) => p.active)) product.id: product
      };
});


final categoryDropdownListProvider = StreamProvider.autoDispose<List<DropdownItem>>((ref) {
  final appAsync = ref.watch(appStoreProvider);
  return appAsync.when(
    data: (app) {
      if (app == null || app.companyId.isEmpty) {
        return Stream.value([]); // Return an empty list stream if no valid app/companyId
      }
      return DropdownService.getDropdownItems(
        companyId: app.companyId,
        collectionName: FirestoreConstants.categoryCollection,
        fieldName: FirestoreConstants.nameField,
      );
    },
    loading: () => const Stream.empty(),
    error: (err, stack) {
      return Stream.value([]);
    },
  );
});


final hsnDropdownListProvider = StreamProvider.autoDispose<List<DropdownItem>>((ref) {
  final appAsync = ref.watch(appStoreProvider);
  return appAsync.when(
    data: (app) {
      if (app == null || app.companyId.isEmpty) {
        return Stream.value([]); // Return an empty list stream if no valid app/companyId
      }
      return  DropdownService.getDropdownItems(
        companyId: app.companyId,
        collectionName: FirestoreConstants.hsnCollection,
        fieldName: FirestoreConstants.codeField,
      );
    },
    loading: () => const Stream.empty(),
    error: (err, stack) {
      return Stream.value([]);
    },
  );
});


final unitDropdownListProvider = StreamProvider.autoDispose<List<DropdownItem>>((ref) {
  final appAsync = ref.watch(appStoreProvider);
  return appAsync.when(
    data: (app) {
      if (app == null || app.companyId.isEmpty) {
        return Stream.value([]); // Return an empty list stream if no valid app/companyId
      }
      return  DropdownService.getDropdownItems(
        companyId: app.companyId,
        collectionName: FirestoreConstants.unitCollection,
        fieldName: FirestoreConstants.symbolField,
      );
    },
    loading: () => const Stream.empty(),
    error: (err, stack) {
      return Stream.value([]);
    },
  );
});


final showInactiveProductsProvider = StateProvider<bool>((ref) => false);

// StateProvider for the search query in the product list
final productSearchQueryProvider = StateProvider<String>((ref) => '');


final editProductProvider = StateProvider<Product?>((ref) => null);


final totalProductCountProvider = Provider.autoDispose<AsyncValue<int>>((ref) {
  final productsAsync = ref.watch(productListProvider);

  // Safely map the AsyncValue of List<Product> to an AsyncValue of int (the length).
  // This ensures the UI knows if it is Loading, Errored, or has a Data count.
  return productsAsync.when(
    data: (products) => AsyncValue.data(products.length),
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});


final filteredProductListProvider = Provider.autoDispose<AsyncValue<List<Product>>>((ref) {
  // Watch the base stream provider, which gives an AsyncValue<List<Product>>
  final productsAsync = ref.watch(productListProvider);
  final showDisabled = ref.watch(showInactiveProductsProvider);
  final searchQuery = ref.watch(productSearchQueryProvider).toLowerCase();

  return productsAsync.whenData((products) {
    final filtered = products.where((p) => p.active || showDisabled).toList();
    if (searchQuery.isEmpty) return filtered;
    return filtered.where((p) =>p.name.toLowerCase().contains(searchQuery)).toList();
  });
});
