import '../Model/hsn_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventorytracker/Shared/Constants/firestore_constants.dart';


class HsnService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Hsn>> getHsnList(String companyId) {
    return _db
        .collection(FirestoreConstants.companyCollection)
        .doc(companyId)
        .collection(FirestoreConstants.hsnCollection)
        .snapshots()
        .map((snap) => snap.docs.map(Hsn.fromDoc).toList());
  }


  Future<void> addHsn(String companyId, Hsn hsn) async {
    await _db
        .collection(FirestoreConstants.companyCollection)
        .doc(companyId)
        .collection(FirestoreConstants.hsnCollection)
        .add(hsn.toMap());
  }


  Future<void> updateHsn(String companyId, Hsn hsn) async {
    await _db
        .collection(FirestoreConstants.companyCollection)
        .doc(companyId)
        .collection(FirestoreConstants.hsnCollection)
        .doc(hsn.id)
        .update(hsn.toMap());
  }


  Future<bool> isDuplicate(String companyId, String code, [String? excludeId]) async {
    final result = await _db
        .collection(FirestoreConstants.companyCollection)
        .doc(companyId)
        .collection(FirestoreConstants.hsnCollection)
        .where(FirestoreConstants.codeField, isEqualTo: code.toUpperCase())
        .get();

    return result.docs.any((doc) => doc.id != excludeId);
  }

}
