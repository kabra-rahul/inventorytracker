//signup_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../Service/sign_up_service.dart';


final signupServiceProvider = Provider((ref) => SignupService());

final nameControllerProvider = Provider.autoDispose((ref) => TextEditingController());
final emailControllerProvider = Provider.autoDispose((ref) => TextEditingController());
final passwordControllerProvider = Provider.autoDispose((ref) => TextEditingController());
final mobileControllerProvider = Provider.autoDispose((ref) => TextEditingController());
final companyNameControllerProvider = Provider.autoDispose((ref) => TextEditingController());
final gstControllerProvider = Provider.autoDispose((ref) => TextEditingController());

class SignupState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const SignupState({this.isLoading = false, this.error,this.isSuccess=false});

  SignupState copyWith({bool? isLoading, String? error, bool? isSuccess}) => SignupState(
    isLoading: isLoading ?? this.isLoading,
    error: error,
    isSuccess: isSuccess ?? this.isSuccess
  );
}

class SignupNotifier extends StateNotifier<SignupState> {
  final Ref ref;
  final formKey = GlobalKey<FormState>();

  SignupNotifier(this.ref) : super(const SignupState());


  Future<String?> submitForm() async {
    final name = ref.read(nameControllerProvider).text.trim();
    final email = ref.read(emailControllerProvider).text.trim();
    final password = ref.read(passwordControllerProvider).text.trim();
    final mobile = ref.read(mobileControllerProvider).text.trim();
    final companyName = ref.read(companyNameControllerProvider).text.trim();
    final gst = ref.read(gstControllerProvider).text.trim().toUpperCase();

    return await ref.read(signupServiceProvider).registerUser(
      name: name,
      email: email,
      password: password,
      mobile: mobile,
      companyName: companyName,
      gstNumber: gst,
    );
  }

  Future<void> submit(WidgetRef ref) async {
    if (!formKey.currentState!.validate()) return;

    // Check if mounted before updating state
    if (!mounted) return; // Add this line

    state = state.copyWith(isLoading: true, error: null, isSuccess: null);
    final result = await submitForm();

    // Check if mounted again before updating state
    if (!mounted) return; // Add this line

    if (result != null) {
      state = state.copyWith(isLoading: false, error: result, isSuccess: null);
    } else {
      state = state.copyWith(isLoading: false, error: null, isSuccess: true);

      ref.read(nameControllerProvider).clear();
      ref.read(emailControllerProvider).clear();
      ref.read(passwordControllerProvider).clear();
      ref.read(mobileControllerProvider).clear();
      ref.read(companyNameControllerProvider).clear();
      ref.read(gstControllerProvider).clear();
    }
  }
}


final signupProvider = StateNotifierProvider.autoDispose<SignupNotifier, SignupState>(
      (ref) => SignupNotifier(ref),
);