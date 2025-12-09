import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Model/company_model.dart';
import 'package:inventorytracker/Shared/Constants/firestore_constants.dart';

class CompanyService {

  final FirebaseFirestore _fs;

  CompanyService([FirebaseFirestore? firestore]) : _fs = firestore ?? FirebaseFirestore.instance;


  Future<Company> getCompanyById(String companyId) async {
    final doc = await FirebaseFirestore.instance
        .collection(FirestoreConstants.companyCollection)
        .doc(companyId)
        .get();

    if (!doc.exists) {
      throw Exception('Company not found');
    }
    return Company.fromDoc(doc);
  }


  Future<void> updateCompany(String companyId, {required String name, required String gst, required String address}) async {

    final existingCompanySnapshot = await _fs
        .collection(FirestoreConstants.companyCollection)
        .where(FirestoreConstants.companyGstField, isEqualTo: gst.toUpperCase())
        .where(FieldPath.documentId, isNotEqualTo: companyId)
        .limit(1)
        .get();

    if (existingCompanySnapshot.docs.isNotEmpty) {
      throw Exception('A company with this GST is already registered.');
    }

    return _fs
        .collection(FirestoreConstants.companyCollection)
        .doc(companyId)
        .update({
          FirestoreConstants.companyNameField   : name.toUpperCase(),
          FirestoreConstants.companyAddressField: address,
          FirestoreConstants.companyGstField    : gst.toUpperCase()
        });
  }
}

final companyServiceProvider = Provider((_) => CompanyService());
