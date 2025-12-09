import '../Model/client_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventorytracker/Shared/Constants/firestore_constants.dart';


class ClientService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Client>> getClientList(String companyId) {
    return _db
        .collection(FirestoreConstants.companyCollection)
        .doc(companyId)
        .collection(FirestoreConstants.clientCollection)
        .snapshots()
        .map((snap) => snap.docs.map(Client.fromDoc).toList());
  }


  Future<void> addClient(String companyId, Client client) async {
    await _db
        .collection(FirestoreConstants.companyCollection)
        .doc(companyId)
        .collection(FirestoreConstants.clientCollection)
        .add(client.toMap());
  }


  Future<void> updateClient(String companyId, Client client) async {
    await _db
        .collection(FirestoreConstants.companyCollection)
        .doc(companyId)
        .collection(FirestoreConstants.clientCollection)
        .doc(client.id)
        .update(client.toMap());
  }


  Future<bool> isDuplicate(String companyId, String gst, [String? excludeId]) async {
    final result = await _db
        .collection(FirestoreConstants.companyCollection)
        .doc(companyId)
        .collection(FirestoreConstants.clientCollection)
        .where(FirestoreConstants.companyGstField, isEqualTo: gst.toUpperCase())
        .get();

    return result.docs.any((doc) => doc.id != excludeId);
  }


  Future<bool> isDuplicateClient(String companyId, String companyName, [String? excludeId]) async {
    final result = await _db
        .collection(FirestoreConstants.companyCollection)
        .doc(companyId)
        .collection(FirestoreConstants.clientCollection)
        .where(FirestoreConstants.companyNameField, isEqualTo: companyName.toUpperCase())
        .get();

    return result.docs.any((doc) => doc.id != excludeId);
  }
}
