// auth_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inventorytracker/Service/auth_service.dart';


final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Listens to Firebase Auth state
final authStateProvider = StreamProvider<User?>((ref) {

  final authService = ref.watch(authServiceProvider);

  return authService.getCurrentUserStream().asyncMap((user) async {
    if (user != null) {
      try {
        //await user.reload();
       // final refreshedUser = FirebaseAuth.instance.currentUser;

        /*final tokenResult = await user.getIdTokenResult();
        final claims = tokenResult.claims;

        if (claims?['disabled'] == true) {
          await FirebaseAuth.instance.signOut();
          return null;
        }*/
        //print("User Details : $user");
        return user;
      } catch (e) {
        // Optional: log error
        return user; // fallback to original user
      }
    }
    return null;
  });
});
