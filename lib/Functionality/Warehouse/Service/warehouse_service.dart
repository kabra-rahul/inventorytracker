//warehouse_service.dart
import '../Model/warehouse_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventorytracker/Shared/Constants/firestore_constants.dart';
import 'package:inventorytracker/Functionality/User/Service/user_service.dart';

class WarehouseService {
  final FirebaseFirestore _db; // Now an instance member
  final String _companyId; // Company ID for this service instance
  final UserService _userService; // The injected UserService

  // Constructor now requires companyId AND userService
  WarehouseService({
    required String companyId,
    required UserService userService, // This is the key change!
    FirebaseFirestore? firestore, // Allows injecting Firestore for testing
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _companyId = companyId,
        _userService = userService; // Assign the injected service

  // Helper to get the correct warehouse collection reference scoped by company
  CollectionReference<Map<String, dynamic>> _warehouseCollectionRef() {
    return _db
        .collection(FirestoreConstants.companyCollection)
        .doc(_companyId) // Use the instance's companyId
        .collection(FirestoreConstants.warehouseCollection);
  }


  Stream<List<Warehouse>> getWarehouseList() {
    return _warehouseCollectionRef()
        .snapshots()
        .map((snap) => snap.docs.map(Warehouse.fromDoc).toList());
  }


  Future<void> addWarehouse(Warehouse warehouse) async {
    try {
      final DocumentReference docRef = await _warehouseCollectionRef()
          .add(warehouse.toMap());

      final String newWarehouseId = docRef.id;

      await _userService.addWarehouseToAdminUsers(_companyId,newWarehouseId);
      return;
    } on Exception catch (e) {
      throw Exception("Failed to add warehouse: $e");
    }
  }


  Future<void> updateWarehouse(Warehouse warehouse) async {
    await _warehouseCollectionRef()
        .doc(warehouse.id)
        .update(warehouse.toMap());
  }


  Future<bool> isDuplicate(String name, [String? excludeId]) async {
    final result = await _warehouseCollectionRef()
        .where(FirestoreConstants.nameField, isEqualTo: name.toUpperCase())
        .get();

    return result.docs.any((doc) => doc.id != excludeId);
  }
}