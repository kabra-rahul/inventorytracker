//hsn_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../Provider/app_store_provider.dart';
import '../Model/hsn_model.dart';
import '../Service/hsn_service.dart';


final hsnServiceProvider = Provider<HsnService>((ref) => HsnService());

final hsnListProvider = StreamProvider.autoDispose<List<Hsn>>((ref) {
  final appAsync = ref.watch(appStoreProvider);

  return appAsync.when(
    data: (app) {
      if (app == null || app.companyId.isEmpty) {
        return Stream.value([]);
      }
      return ref.read(hsnServiceProvider).getHsnList(app.companyId);
    },
    loading: () => const Stream.empty(),
    error: (_, _) => const Stream.empty(),
  );
});



final allHsnsMapProvider = FutureProvider<Map<String, String>>((ref) async {
  final hsnsList = await ref.watch(hsnListProvider.future);
  return {
        for (var hsn in hsnsList.where((h) => h.active)) hsn.id: hsn.code};

});


/// Provider to hold the Hsn being edited (if any).
/// - If editing an existing hsn → holds that Hsn.
/// - If adding new → holds `null`.
final editHsnProvider = StateProvider<Hsn?>((ref) => null);


/// Provider to control whether Inactive Hsns should be shown in the UI.
/// - If `true`, UI will include inactive hsns in the list.
/// - If `false`, UI will show only active hsns.
final showInactiveHsnsProvider = StateProvider<bool>((ref) => false);


// StateProvider for the search query in the hsn list
final hsnSearchQueryProvider = StateProvider<String>((ref) => '');


// Combined provider for filtered and searched hsnCodes
final filteredHsnListProvider = Provider.autoDispose<AsyncValue<List<Hsn>>>((ref) {
  // Watch the base stream provider, which gives an AsyncValue<List<Category>>
  final hsnAsync = ref.watch(hsnListProvider);
  final showDisabled = ref.watch(showInactiveHsnsProvider);
  final searchQuery = ref.watch(hsnSearchQueryProvider).toLowerCase();

  return hsnAsync.whenData((hsn) {
    final filtered = hsn.where((h) => h.active || showDisabled).toList();
    if (searchQuery.isEmpty) return filtered;
    return filtered.where((h) => h.code.toLowerCase().contains(searchQuery)).toList();
  });
});