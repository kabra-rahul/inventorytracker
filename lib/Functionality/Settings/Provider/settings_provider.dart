import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventorytracker/Provider/app_store_provider.dart';
import '../../../Service/auth_service.dart';
import '../Model/company_model.dart';
import '../Service/company_service.dart';

final isAdminProvider = Provider<bool>((ref) {
  final app = ref.watch(appStoreProvider).asData?.value;
  if (app == null) {
    return false; // default fallback
  }
  return app.isAdmin;
});

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// FutureProvider (one-time fetch)
final companyProvider = FutureProvider.family<Company, String>((ref, companyId) {
  final companyService = ref.watch(companyServiceProvider);
  return companyService.getCompanyById(companyId);
});