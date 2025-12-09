// user_settings_notifier.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:inventorytracker/Functionality/Settings/Provider/settings_provider.dart';
import 'package:inventorytracker/Service/auth_service.dart'; // Assuming authService is defined here
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inventorytracker/Service/user_management_service.dart';
import 'package:inventorytracker/Shared/Constants/firestore_constants.dart';

class UserSettingsState {
  final bool isLoading;
  final String? error;
  final String? success;
  final bool passwordUpdatedAndLoggedOut;

  const UserSettingsState({
    this.isLoading = false,
    this.error,
    this.success,
    this.passwordUpdatedAndLoggedOut = false,
  });

  UserSettingsState copyWith({
    bool? isLoading,
    String? error,
    String? success,
    bool? passwordUpdatedAndLoggedOut,
  }) => UserSettingsState(
    isLoading: isLoading ?? this.isLoading,
    error: error, // Null out error if not provided
    success: success, // Null out success if not provided
    passwordUpdatedAndLoggedOut: passwordUpdatedAndLoggedOut ?? this.passwordUpdatedAndLoggedOut,
  );
}

class UserSettingsNotifier extends StateNotifier<UserSettingsState> {
  final AuthService _authService;

  UserSettingsNotifier(this._authService) : super(const UserSettingsState());


  Future<void> updateProfile({
    required String name,
    required String mobile,
    required String email,
    required String companyId,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      success: null,
      passwordUpdatedAndLoggedOut: false,
    );
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("No authenticated user found.");
      }

      if (email != FirebaseAuth.instance.currentUser?.email) {
        await UserManagementService.updateUserEmail(user.uid, email);
      }

      await user.updateDisplayName(name);

      final docRef = FirebaseFirestore.instance
          .collection(FirestoreConstants.companyCollection)
          .doc(companyId)
          .collection(FirestoreConstants.userCollection)
          .doc(user.uid);

      await docRef.update({
        FirestoreConstants.userNameField: name,
        FirestoreConstants.userMobileField: mobile,
        FirestoreConstants.userEmailField: email,
      });

      state = state.copyWith(
        isLoading: false,
        success: 'Profile updated successfully',
      );
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message ?? "Authentication Error",
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      success: null,
      passwordUpdatedAndLoggedOut: false,
    );
    try {
      await _authService.reauthenticate(oldPassword);
      await _authService.updatePassword(newPassword);

      // Force logout after password update
      await _authService.signOut();

      state = state.copyWith(
        isLoading: false,
        success: 'Password updated. Please log in again.',
        passwordUpdatedAndLoggedOut: true,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'Incorrect old password.';
          break;
        case 'user-disabled':
          errorMessage = 'User account has been disabled.';
          break;
        case 'requires-recent-login':
          errorMessage = 'Please log out and log in again to update password.';
          break;
        default:
          errorMessage =
              e.message ?? 'An unknown authentication error occurred.';
          break;
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Method to clear any success/error messages if needed by the UI
  void clearMessages() {
    state = state.copyWith(
      error: null,
      success: null,
      passwordUpdatedAndLoggedOut: false,
    );
  }
}

final userSettingsProvider =
    StateNotifierProvider.autoDispose<UserSettingsNotifier, UserSettingsState>(
      (ref) => UserSettingsNotifier(ref.read(authServiceProvider)), // Pass ref
    );
