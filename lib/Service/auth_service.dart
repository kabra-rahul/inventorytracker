// auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? get currentUser => _auth.currentUser;

  /// Auth state stream
  Stream<User?> getCurrentUserStream() => _auth.authStateChanges();


  /// -----------------------
  /// EMAIL/PASSWORD LOGIN
  Future<User?> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }


  /// -----------------------
  /// SIGN OUT
  /// -----------------------
  Future<void> signOut() async {
    await _auth.signOut();
//    await GoogleSignIn.instance.signOut();
  }



  /// -----------------------
  /// ACCOUNT MANAGEMENT
  Future<void> updateEmail(String newEmail) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not signed in");

    if (newEmail == user.email) return;

    try {
      await user.verifyBeforeUpdateEmail(newEmail);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception("Email already in use by another account");
      } else {
        throw Exception("Failed to update email: ${e.message}");
      }
    }
  }



  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not signed in");
    await user.updatePassword(newPassword);
  }



  Future<void> reauthenticate(String oldPassword) async {
    final user = currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'no-user', message: 'User not logged in');
    }
    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: oldPassword,
    );
    await user.reauthenticateWithCredential(cred);
  }



  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
