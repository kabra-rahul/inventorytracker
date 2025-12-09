// user_management_service.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserManagementService {
  static Future<void> disableUser(String userId) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User is not signed in or token is not ready.');
    }

    try {
      await user.getIdToken(true);
      //await Future.delayed(const Duration(milliseconds: 100));
      final HttpsCallable callable =
      FirebaseFunctions.instance.httpsCallable('disableUser');
      await callable.call({'uid': userId});
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e);
    }
  }


  static Future<void> enableUser(String userId) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User is not signed in or token is not ready.');
    }

    try {
      await user.getIdToken(true);
      //await Future.delayed(const Duration(milliseconds: 100));
      final HttpsCallable callable =
      FirebaseFunctions.instance.httpsCallable('enableUser');
      await callable.call({'uid': userId});
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e);
    }
  }


  static Future<void> updateUserEmail(String userId, String email) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User is not signed in or token is not ready.');
    }

    try {
      await user.getIdToken(true);
      //await Future.delayed(const Duration(milliseconds: 100));
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('updateUserEmail');
      await callable.call({'uid': userId, 'email': email});
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e);
    }
  }


  static Future<void> updateUserDisplayName(String userId, String displayName) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User is not signed in or token is not ready.');
    }

    try {
      await user.getIdToken(true);
      //await Future.delayed(const Duration(milliseconds: 100));
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('updateUserDisplayName');
      await callable.call({'uid': userId, 'displayName': displayName});
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e);
    }
  }
}