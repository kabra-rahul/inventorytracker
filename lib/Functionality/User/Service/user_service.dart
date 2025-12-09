//user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inventorytracker/Shared/Constants/firestore_constants.dart';
import 'package:inventorytracker/Shared/Constants/role_constants.dart';
import '../Model/app_user_model.dart';


class UserService {
  final FirebaseFirestore _firestore; // Now an instance member
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _companyId; // Company ID for this service instance

  // Constructor now requires companyId
  UserService({required String companyId, FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _companyId = companyId;

  // Helper to get the correct user collection reference scoped by company
  CollectionReference<Map<String, dynamic>> _userCollectionRef() {
    return _firestore
        .collection(FirestoreConstants.companyCollection)
        .doc(_companyId) // Use the instance's companyId
        .collection(FirestoreConstants.userCollection);
  }


  Stream<List<AppUser>> getUserList() {
    return _userCollectionRef().snapshots().map((snap) =>
        snap.docs.map((doc) => AppUser.fromDoc(doc)).toList()
    );
  }


  Future<AppUser> getUserById(String userId) async {
    final col = await _userCollectionRef().doc(userId).get();
    if (!col.exists) {
      throw Exception('User not found');
    }
    return AppUser.fromDoc(col);
  }


  /*Future<void> addUser(AppUser user, String password) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final userCred = await auth.createUserWithEmailAndPassword(
      email: user.email,
      password: password,
    );

    final User? firebaseUser = userCred.user;
    if (firebaseUser == null) {
      throw Exception('Firebase User is null after successful credential acquisition.');
    }
    final uid = firebaseUser.uid;

    await Future.wait([
      firebaseUser.updateDisplayName(user.userName),
      _firestore.collection(FirestoreConstants.userMapCollection).add({
          FirestoreConstants.userIdField   : uid,
          FirestoreConstants.companyIdField: _companyId,
      }),
      _userCollectionRef()
          .doc(uid)
          .set(user.toMap())
    ]);
  }
*/

  Future<void> addUser(AppUser user, String password) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final currUser = _auth.currentUser;

    if (currUser == null) {
      throw Exception('User is not signed in or token is not ready.');
    }

    try {
      await currUser.getIdToken(true);

      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('createUserForAdmin');

      final result = await callable.call({
        'email': user.email,
        'password': password,
        'displayName': user.userName
      });

      final uid = result.data['uid'];

      if (uid == null) {
        throw Exception('Cloud function did not return a valid UID.');
      }

      await Future.wait([
        firestore.collection(FirestoreConstants.userMapCollection).doc(uid).set({
          FirestoreConstants.userIdField   : uid,
          FirestoreConstants.companyIdField: _companyId,
        }),
        _userCollectionRef()
            .doc(uid)
            .set(user.toMap())
      ]);

    } on FirebaseFunctionsException catch (e) {
      throw Exception('${e.message}');
    } catch (e) {
      // Catch network or other errors
      throw Exception('Failed to create user: $e');
    }
  }


  Future<void> updateUser(AppUser user) async {
    await _userCollectionRef()
        .doc(user.id)
        .update(user.toMap());
  }


  Future<void> addWarehouseToAdminUsers(String companyId, String newWarehouseId) async {
    try {
      // Query for all users with the 'admin' role within the current company context
      final QuerySnapshot adminUsersSnapshot = await _firestore
          .collection(FirestoreConstants.companyCollection)
          .doc(companyId) // Use the instance's companyId
          .collection(FirestoreConstants.userCollection)
          .where(FirestoreConstants.userRoleField, isEqualTo: RoleConstants.adminRole)
          .get();

      // Create a batch write to update multiple documents efficiently
      final WriteBatch batch = _firestore.batch();

      for (final doc in adminUsersSnapshot.docs) {
        final List<String> currentWarehouseIds = List<String>.from(doc[FirestoreConstants.userWarehousIdsField] ?? []);

        // Only add if the warehouseId is not already present
        if (!currentWarehouseIds.contains(newWarehouseId)) {
          batch.update(
            doc.reference,
            {
              FirestoreConstants.userWarehousIdsField: FieldValue.arrayUnion([newWarehouseId])
            },
          );
        }
      }
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }
}