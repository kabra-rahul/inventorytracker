//app_store_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import '../Shared/Constants/firestore_constants.dart';
import '../Model/app_store_model.dart';

class AppStoreService {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  AppStoreService({
    required this.auth,
    required this.firestore,
  });


  Stream<AppStore?> get appStoreStream {
    return auth.authStateChanges().switchMap((user) {
      if (user == null) return Stream.value(null);

      final uid = user.uid;

      // Step 1: Get stream of user-to-company mapping document
      final mappingDocRef = firestore.collection(FirestoreConstants.userMapCollection).doc(uid);
      final userDocStream = mappingDocRef.snapshots();

      return userDocStream.switchMap((mappingSnap) {
        if (!mappingSnap.exists) return Stream.value(null);
        final companyId = mappingSnap.data()?[FirestoreConstants.companyIdField] as String?;
        if (companyId == null) return Stream.value(null);

        // Step 2: Get stream of user document inside company
        final userDocRef = firestore
            .collection(FirestoreConstants.companyCollection)
            .doc(companyId)
            .collection(FirestoreConstants.userCollection)
            .doc(uid);
        final companyDocRef = firestore
            .collection(FirestoreConstants.companyCollection)
            .doc(companyId);

        final userStream = userDocRef.snapshots();
        final companyStream = companyDocRef.snapshots();

        // Step 3: Combine both user and company stream
        return Rx.combineLatest2<DocumentSnapshot, DocumentSnapshot, AppStore?>(
          userStream,
          companyStream,
              (userSnap, companySnap) {
            if (!userSnap.exists || userSnap.data() == null ||
                !companySnap.exists || companySnap.data() == null) {
              return null; // Emit null if any required document/data is missing
            }
            final userData = userSnap.data() as Map<String, dynamic>;
            final companyData = companySnap.data() as Map<String, dynamic>;

            return AppStore.fromMap(
              uid: uid,
              companyId: companyId,
              userData: userData,
              companyData: companyData,
            );
          },
        );
      });
    });
  }
}