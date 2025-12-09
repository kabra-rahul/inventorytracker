//unit_service.dart
import '../Model/unit_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventorytracker/Shared/Constants/firestore_constants.dart';


class UnitService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Unit>> getUnitList(String companyId) {
    return _db
        .collection(FirestoreConstants.companyCollection)
        .doc(companyId)
        .collection(FirestoreConstants.unitCollection)
        .snapshots()
        .map((snap) => snap.docs.map(Unit.fromDoc).toList());
  }


  Future<void> addUnit(String companyId, Unit unit) async {
    await _db
        .collection(FirestoreConstants.companyCollection)
        .doc(companyId)
        .collection(FirestoreConstants.unitCollection)
        .add(unit.toMap());
  }


  Future<void> updateUnit(String companyId, Unit unit) async {
    await _db
        .collection(FirestoreConstants.companyCollection)
        .doc(companyId)
        .collection(FirestoreConstants.unitCollection)
        .doc(unit.id)
        .update(unit.toMap());
  }


  Future<bool> isDuplicate(String companyId, String symbol, [String? excludeId]) async {
    final result = await _db
        .collection(FirestoreConstants.companyCollection)
        .doc(companyId)
        .collection(FirestoreConstants.unitCollection)
        .where(FirestoreConstants.symbolField, isEqualTo: symbol.toUpperCase())
        .get();

    return result.docs.any((doc) => doc.id != excludeId);
  }

}
