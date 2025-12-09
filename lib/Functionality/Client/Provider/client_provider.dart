//client_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../Provider/app_store_provider.dart';
import '../Model/client_model.dart';
import '../Service/client_service.dart';


final clientServiceProvider = Provider<ClientService>((ref) => ClientService());

final clientListProvider = StreamProvider.autoDispose<List<Client>>((ref) {
  final appAsync = ref.watch(appStoreProvider);

  return appAsync.when(
    data: (app) {
      if (app == null || app.companyId.isEmpty) { // <--- FIX: Check if app is null or companyId is empty
        return Stream.value([]); // Return an empty list stream if no valid app/companyId
      }
      return ref.read(clientServiceProvider).getClientList(app.companyId);
    },
    loading: () => const Stream.empty(),
    error: (_, _) => const Stream.empty(),
  );
});


final allClientsMapProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  final clientsList = await ref.watch(clientListProvider.future);
  return {
          for (var client in clientsList) client.id: client.companyName
        };
});


final clientsMapProvider = FutureProvider<Map<String, String>>((ref) async {
  final clientListAsyncValue = ref.watch(clientListProvider); // Watch the StreamProvider
  return clientListAsyncValue.when(
    data: (clientList) {
      return {
        for (var client in clientList.where((c) => c.active))
          client.id: client.companyName, // Assuming Client model has id and name
      };
    },
    loading: () => {}, // Return empty map while loading
    error: (err, stack) {
      return {}; // Return empty map on error
    },
  );
});

/// Provider to hold the Client being edited (if any).
/// - If editing an existing client → holds that Client.
/// - If adding new → holds `null`.
final editClientProvider = StateProvider<Client?>((ref) => null);


/// Provider to control whether Inactive Clients should be shown in the UI.
/// - If `true`, UI will include inactive clients in the list.
/// - If `false`, UI will show only active clients.
final showInactiveClientsProvider = StateProvider<bool>((ref) => false);


// StateProvider for the search query in the client list
final clientSearchQueryProvider = StateProvider<String>((ref) => '');


// Combined provider for filtered and searched clients
final filteredClientListProvider = Provider.autoDispose<AsyncValue<List<Client>>>((ref) {
  // Watch the base stream provider, which gives an AsyncValue<List<Category>>
  final clientsAsync = ref.watch(clientListProvider);
  final showDisabled = ref.watch(showInactiveClientsProvider);
  final searchQuery = ref.watch(clientSearchQueryProvider).toLowerCase();

  return clientsAsync.whenData((clients) {
    final filtered = clients.where((c) => c.active || showDisabled).toList();
    if (searchQuery.isEmpty) return filtered;
    return filtered.where((c) => c.companyName.toLowerCase().contains(searchQuery)).toList();
  });
});