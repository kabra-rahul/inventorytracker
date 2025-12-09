// dropdown_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventorytracker/Model/dropdown_item_model.dart';
import 'package:inventorytracker/Shared/Constants/firestore_constants.dart';

class DropdownService {
  static Stream<List<DropdownItem>> getDropdownItems({
    required String companyId,
    required String collectionName,
    required String fieldName,
  }) {
    return FirebaseFirestore.instance
        .collection(FirestoreConstants.companyCollection)
        .doc(companyId)
        .collection(collectionName)
        .where(FirestoreConstants.activeField, isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => DropdownItem(id: doc.id, name: doc.data()[fieldName] ?? '')).toList());
  }
}
