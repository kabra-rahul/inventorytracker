//payment_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventorytracker/Functionality/Payment/Model/company_payment_model.dart';
import 'package:inventorytracker/Shared/Constants/firestore_constants.dart';


class CompanyPaymentService {
  final FirebaseFirestore firestore;

  CompanyPaymentService(this.firestore);


  Future<void> updateCompanyPlan(String companyId, String plan, {DateTime? expiry}) async {
    await firestore
        .collection(FirestoreConstants.companyCollection)
        .doc(companyId)
        .update( {
            FirestoreConstants.companyPlanField : plan,
            if (expiry != null) FirestoreConstants.companyPlanExpiryField : Timestamp.fromDate(expiry)
        });
  }


  Future<void> savePaymentDetails(Map<String, dynamic> details) async {
    await firestore
        .collection(FirestoreConstants.paymentCollection)
        .add(details);
  }


  Stream<List<PaymentModel>> streamPayment(String companyId) {
    return firestore
        .collection(FirestoreConstants.paymentCollection)
        .where(FirestoreConstants.companyIdField, isEqualTo: companyId)
        .orderBy(FirestoreConstants.paidAtField, descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((d) => PaymentModel.fromMap(d.data())).toList());
  }


  Future<PaymentModel?> getPaymentById(String paymentId) async {
    final query = await firestore
        .collection(FirestoreConstants.paymentCollection)
        .where(FirestoreConstants.paymentIdField, isEqualTo: paymentId)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return PaymentModel.fromMap(query.docs.first.data());
  }
}