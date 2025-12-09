// product_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventorytracker/Shared/Constants/firestore_constants.dart';
import '../Model/product_model.dart';

class ProductService {
  final String companyId;
  final FirebaseFirestore _db;

  ProductService({required this.companyId, FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;


  Stream<List<Product>> getProductList() {
    final productCollection = _db
        .collection(FirestoreConstants.companyCollection)
        .doc(companyId)
        .collection(FirestoreConstants.productCollection);
    return productCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Product.fromDoc(doc);
      }).toList();
    });
  }


  Future<void> addProduct(Product product) async {
    await _db
        .collection(FirestoreConstants.companyCollection)
        .doc(companyId)
        .collection(FirestoreConstants.productCollection)
        .add(product.toMap());
  }

  Future<void> updateProduct(Product product) async {
    await _db
        .collection(FirestoreConstants.companyCollection)
        .doc(companyId)
        .collection(FirestoreConstants.productCollection)
        .doc(product.id)
        .update(product.toMap());
  }

  Future<bool> isDuplicate(String name, [String? excludeId]) async {
    final result = await _db
        .collection(FirestoreConstants.companyCollection)
        .doc(companyId)
        .collection(FirestoreConstants.productCollection)
        .where(FirestoreConstants.nameField, isEqualTo: name.toUpperCase())
        .get();

    return result.docs.any((doc) => doc.id != excludeId);
  }
}