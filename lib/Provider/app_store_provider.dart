//app_store_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventorytracker/Model/app_store_model.dart';
import 'package:inventorytracker/Service/app_store_service.dart';


final appStoreServiceProvider = Provider<AppStoreService>((ref) {
  return AppStoreService(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});


final appStoreProvider = StreamProvider<AppStore?>((ref) {
  final service = ref.watch(appStoreServiceProvider);
  return service.appStoreStream;
});


final appStoreDataProvider = Provider<AppStore?>((ref) {
  final asyncApp = ref.watch(appStoreProvider);
  return asyncApp.maybeWhen(data: (data) => data, orElse: () => null);
});

final expiryCheckCompletedProvider = StateProvider<bool>((ref) => false);