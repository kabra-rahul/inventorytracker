import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:inventorytracker/Service/auth_service.dart';
import 'package:inventorytracker/Provider/auth_provider.dart';


class ForgotPasswordNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;

  ForgotPasswordNotifier(this._authService) : super(const AsyncData(null));

  Future<void> sendResetEmail(String email) async {
    state = const AsyncLoading();
    try {
      await _authService.sendPasswordResetEmail(email);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final forgotPasswordProvider =
StateNotifierProvider<ForgotPasswordNotifier, AsyncValue<void>>(
      (ref) => ForgotPasswordNotifier(ref.read(authServiceProvider)),
);