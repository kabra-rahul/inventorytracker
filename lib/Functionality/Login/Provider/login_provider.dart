//login_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../Service/auth_service.dart';


final emailProvider = Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});


final passwordProvider = Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});


final loginProvider = StateNotifierProvider.autoDispose<LoginNotifier, LoginState>((ref) {
  return LoginNotifier(ref);
});


class LoginState {
  final bool isLoading;
  final String? errorMessage;

  const LoginState({this.isLoading = false, this.errorMessage});

  LoginState copyWith({bool? isLoading, String? errorMessage}) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}



class LoginNotifier extends StateNotifier<LoginState> {
  final Ref ref;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  LoginNotifier(this.ref) : super(const LoginState());

/*  void reset() {
    state = const LoginState();
  }*/

  Future<User?> login() async {
    if (!formKey.currentState!.validate()) return null;

    state = state.copyWith(isLoading: true, errorMessage: null);
    final email = ref.read(emailProvider).text.trim();
    final password = ref.read(passwordProvider).text.trim();

    try {
      final user = await _authService.signInWithEmail(email, password);
      if (user == null) {
        state = state.copyWith(errorMessage: "Login failed: No user found.", isLoading: false);
        return null;
      }

      ref.read(emailProvider).clear();
      ref.read(passwordProvider).clear();
      state = state.copyWith(isLoading: false, errorMessage: null); // Clear error on success
      return user;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(errorMessage: e.message ?? "Login failed due to authentication issue.", isLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: 'An unexpected error occurred: ${e.toString()}', isLoading: false);
    }
    return null;
  }


  /*Future<User?> loginWithGoogle() async {
    if (!formKey.currentState!.validate()) return null;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _authService.signInWithGoogle();

      if (user == null) {
        state = state.copyWith(errorMessage: "Login failed: No user found.", isLoading: false);
        return null;
      }

      state = state.copyWith(isLoading: false, errorMessage: null);
      return user;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }*/
}
