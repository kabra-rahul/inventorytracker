//unit_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../Provider/app_store_provider.dart';
import '../Model/unit_model.dart';
import '../Service/unit_service.dart';


final unitServiceProvider = Provider<UnitService>((ref) => UnitService());

final unitListProvider = StreamProvider.autoDispose<List<Unit>>((ref) {
  final appAsync = ref.watch(appStoreProvider);

  return appAsync.when(
    data: (app) {
      if (app == null || app.companyId.isEmpty) {
        return Stream.value([]);
      }
      return ref.read(unitServiceProvider).getUnitList(app.companyId);
    },
    loading: () => const Stream.empty(),
    error: (_, _) => const Stream.empty(),
  );
});


final allUnitsMapProvider = FutureProvider<Map<String, String>>((ref) async {
  final unitsList = await ref.watch(unitListProvider.future);
  return  {
        for (var cat in unitsList.where((u) => u.active)) cat.id: cat.symbol
        };
});

/// Provider to hold the Unit being edited (if any).
/// - If editing an existing unit → holds that Unit.
/// - If adding new → holds `null`.
final editUnitProvider = StateProvider<Unit?>((ref) => null);


/// Provider to control whether Inactive Units should be shown in the UI.
/// - If `true`, UI will include inactive units in the list.
/// - If `false`, UI will show only active units.
final showInactiveUnitsProvider = StateProvider<bool>((ref) => false);


// StateProvider for the search query in the unit list
final unitSearchQueryProvider = StateProvider<String>((ref) => '');


// Combined provider for filtered and searched units
final filteredUnitListProvider = Provider.autoDispose<AsyncValue<List<Unit>>>((ref) {
  // Watch the base stream provider, which gives an AsyncValue<List<Unit>>
  final unitsAsync = ref.watch(unitListProvider);
  final showDisabled = ref.watch(showInactiveUnitsProvider);
  final searchQuery = ref.watch(unitSearchQueryProvider).toLowerCase();

  return unitsAsync.whenData((units) {
    final filtered = units.where((u) => u.active || showDisabled).toList();
    if (searchQuery.isEmpty) return filtered;
    return filtered.where((u) => u.name.toLowerCase().contains(searchQuery) || u.symbol.toLowerCase().contains(searchQuery)).toList();
  });
});