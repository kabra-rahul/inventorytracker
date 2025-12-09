import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventorytracker/Provider/app_store_provider.dart';
import 'package:inventorytracker/Model/app_store_model.dart';
import 'dart:async';

final userSessionDataProvider = FutureProvider<AppStore>((ref) async {
  final appStoreSnapshot = ref.read(appStoreProvider);

  // Immediate check
  if (appStoreSnapshot is AsyncData<AppStore?>) {
    final appStore = appStoreSnapshot.value;
    if (appStore != null && appStore.companyId.isNotEmpty) {
      return appStore;
    }
  }

  final completer = Completer<AppStore>();

  final sub = ref.listen<AsyncValue<AppStore?>>(appStoreProvider, (prev, next) {
    next.when(
      data: (appStore) {
        if (appStore != null && appStore.companyId.isNotEmpty && !completer.isCompleted) {
          completer.complete(appStore);
        }
      },
      error: (error, stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      },
      loading: () {
        // no-op
      },
    );
  }, fireImmediately: true);

  ref.onDispose(() => sub.close());

  return completer.future;
});
