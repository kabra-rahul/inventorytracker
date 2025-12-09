//supplier_service.dart
import '../Model/supplier_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventorytracker/Shared/Constants/firestore_constants.dart';


class SupplierService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Supplier>> getSupplierList(String companyId) {
    return _db
        .collection(FirestoreConstants.companyCollection)
        .doc(companyId)
        .collection(FirestoreConstants.supplierCollection)
        .snapshots()
        .map((snap) => snap.docs.map(Supplier.fromDoc).toList());
  }


  Future<void> addSupplier(String companyId, Supplier supplier) async {
    await _db
        .collection(FirestoreConstants.companyCollection)
        .doc(companyId)
        .collection(FirestoreConstants.supplierCollection)
        .add(supplier.toMap());
  }


  Future<void> updateSupplier(String companyId, Supplier supplier) async {
    await _db
        .collection(FirestoreConstants.companyCollection)
        .doc(companyId)
        .collection(FirestoreConstants.supplierCollection)
        .doc(supplier.id)
        .update(supplier.toMap());
  }


  Future<bool> isDuplicate(String companyId, String gst, [String? excludeId]) async {
    final result = await _db
        .collection(FirestoreConstants.companyCollection)
        .doc(companyId)
        .collection(FirestoreConstants.supplierCollection)
        .where(FirestoreConstants.companyGstField, isEqualTo: gst.toUpperCase())
        .get();

    return result.docs.any((doc) => doc.id != excludeId);
  }

  Future<bool> isDuplicateSupplier(String companyId, String companyName, [String? excludeId]) async {
    final result = await _db
        .collection(FirestoreConstants.companyCollection)
        .doc(companyId)
        .collection(FirestoreConstants.supplierCollection)
        .where(FirestoreConstants.companyNameField, isEqualTo: companyName.toUpperCase())
        .get();

    return result.docs.any((doc) => doc.id != excludeId);
  }
}
