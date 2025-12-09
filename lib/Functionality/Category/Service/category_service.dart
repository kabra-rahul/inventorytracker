import '../Model/category_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventorytracker/Shared/Constants/firestore_constants.dart';


class CategoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Category>> getCategoryList(String companyId) {
    return _db
        .collection(FirestoreConstants.companyCollection)
        .doc(companyId)
        .collection(FirestoreConstants.categoryCollection)
        .snapshots()
        .map((snap) => snap.docs.map(Category.fromDoc).toList());
  }


  Future<void> addCategory(String companyId, Category category) async {
    await _db
        .collection(FirestoreConstants.companyCollection)
        .doc(companyId)
        .collection(FirestoreConstants.categoryCollection)
        .add(category.toMap());
  }


  Future<void> updateCategory(String companyId, Category category) async {
    await _db
        .collection(FirestoreConstants.companyCollection)
        .doc(companyId)
        .collection(FirestoreConstants.categoryCollection)
        .doc(category.id)
        .update(category.toMap());
  }


  Future<bool> isDuplicate(String companyId, String name, [String? excludeId]) async {
    final result = await _db
        .collection(FirestoreConstants.companyCollection)
        .doc(companyId)
        .collection(FirestoreConstants.categoryCollection)
        .where(FirestoreConstants.nameField, isEqualTo: name.toUpperCase())
        .get();

    return result.docs.any((doc) => doc.id != excludeId);
  }
}