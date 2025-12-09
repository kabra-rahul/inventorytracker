// lib/Shared/Provider/connectivity_provider.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});


final isConnectedProvider = Provider.autoDispose<bool>((ref) {
  final connectivityAsync = ref.watch(connectivityProvider);

  return connectivityAsync.when(
    data: (results) => !results.contains(ConnectivityResult.none), // True if connected
    loading: () => true, // Assume connected while loading (e.g., initial app start)
    error: (_, _) => false, // Assume not connected if there's an error with the stream
  );
});