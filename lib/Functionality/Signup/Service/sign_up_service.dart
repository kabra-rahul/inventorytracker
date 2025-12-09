//signup_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inventorytracker/Shared/Constants/firestore_constants.dart';
import 'package:inventorytracker/Shared/Constants/plan_constants.dart';
import 'package:inventorytracker/Shared/Constants/role_constants.dart';

class SignupService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> registerUser({
    required String name,
    required String email,
    required String password,
    required String mobile,
    required String companyName,
    required String gstNumber,
  }) async {
    if (gstNumber != '') {
      // Step 1: Check if GST already registered
      final existingCompany =
          await _firestore
              .collection(FirestoreConstants.companyCollection)
              .where(FirestoreConstants.companyGstField, isEqualTo: gstNumber.toUpperCase())
              .limit(1)
              .get();

      if (existingCompany.docs.isNotEmpty) {
        return 'A company with this GST is already registered.';
      }
    }

    try {
      // Step 2: Create user in Firebase Auth
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCred.user == null) {
        return ('Failed to create user account.');
      }

      final User? firebaseUser = userCred.user;
      if (firebaseUser == null) {
        // Handle the unexpected case where userCred.user is null
        throw Exception('Firebase User is null after successful credential acquisition.');
      }
      final uid = firebaseUser.uid;

      // Step 3: Add company document
      final companyRef = await _firestore
          .collection(FirestoreConstants.companyCollection)
          .add({
            FirestoreConstants.companyNameField: companyName.toUpperCase(),
            FirestoreConstants.companyAddressField: '',
            FirestoreConstants.companyGstField: gstNumber.toUpperCase(),
            FirestoreConstants.companyCreatedByField: uid,
            FirestoreConstants.companyCreatedOnField: FieldValue.serverTimestamp(),
            FirestoreConstants.companyPlanField: PlanConstants.freePlan,
            FirestoreConstants.companyPlanExpiryField: DateTime.now().add(const Duration(days: 90))
          });

      final companyId = companyRef.id;

      await Future.wait([
        _firestore.collection(FirestoreConstants.userMapCollection).doc(uid).set({
          FirestoreConstants.userIdField: uid,
          FirestoreConstants.companyIdField: companyId,
        }),
        _firestore
            .collection(FirestoreConstants.companyCollection)
            .doc(companyId)
            .collection(FirestoreConstants.userCollection)
            .doc(uid)
            .set({
              FirestoreConstants.userNameField: name,
              FirestoreConstants.userMobileField: mobile,
              FirestoreConstants.userEmailField: email,
              FirestoreConstants.userRoleField: RoleConstants.adminRole,
              FirestoreConstants.userWarehousIdsField: <String>[],
              FirestoreConstants.activeField: true,
              FirestoreConstants.userCreatedOnField: FieldValue.serverTimestamp(),
            }),
        firebaseUser.updateDisplayName(name),
      ]);

      return null;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage =
              'The email address is already in use by another account.';
          break;
        case 'weak-password':
          errorMessage = 'The password provided is too weak.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        default:
          errorMessage =
              e.message ?? 'An unknown authentication error occurred.';
          break;
      }
      return errorMessage;
    } catch (e) {
      return 'Unexpected error: $e';
    }
  }
}