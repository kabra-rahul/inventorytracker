//category_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../Provider/app_store_provider.dart';
import '../Model/category_model.dart';
import '../Service/category_service.dart';


final categoryServiceProvider = Provider<CategoryService>((ref) => CategoryService());

final categoryListProvider = StreamProvider.autoDispose<List<Category>>((ref) {
  final appAsync = ref.watch(appStoreProvider);
   return appAsync.when(
    data: (app) {
      if (app == null || app.companyId.isEmpty) { // <--- FIX: Check if app is null or companyId is empty
        return Stream.value([]); // Return an empty list stream if no valid app/companyId
      }
      return ref.read(categoryServiceProvider).getCategoryList(app.companyId);
    },
    loading: () => const Stream.empty(),
    error: (_, _) => const Stream.empty(),
  );
});


final allCategoriesMapProvider = StreamProvider.autoDispose<Map<String, String>>((ref) {
  final categoriesListAsync = ref.watch(categoryListProvider);
  return categoriesListAsync.when(
    data: (categories) {
      return Stream.value({for (var cat in categories.where((c) => c.active)) cat.id: cat.name});
    },
    loading: () => const Stream.empty(), // Emit empty stream while loading
    error: (err, stack) => const Stream.empty() // Emit empty stream on error
  );
});


/// Provider to hold the Category being edited (if any).
/// - If editing an existing category → holds that Category.
/// - If adding new → holds `null`.
final editCategoryProvider = StateProvider<Category?>((ref) => null);


/// Provider to control whether Inactive Category's should be shown in the UI.
/// - If `true`, UI will include inactive category's in the list.
/// - If `false`, UI will show only active category's.
final showInactiveCategoriesProvider = StateProvider<bool>((ref) => false);


// StateProvider for the search query in the category list
final categorySearchQueryProvider = StateProvider<String>((ref) => '');


// Combined provider for filtered and searched categories
final filteredCategoryListProvider = Provider.autoDispose<AsyncValue<List<Category>>>((ref) {
  // Watch the base stream provider, which gives an AsyncValue<List<Category>>
  final categoriesAsync = ref.watch(categoryListProvider);
  final showDisabled = ref.watch(showInactiveCategoriesProvider);
  final searchQuery = ref.watch(categorySearchQueryProvider).toLowerCase();

  return categoriesAsync.whenData((categories) {
    final filtered = categories.where((c) => c.active || showDisabled).toList();
    if (searchQuery.isEmpty) return filtered;
    return filtered.where((c) => c.name.toLowerCase().contains(searchQuery)).toList();
  });
});