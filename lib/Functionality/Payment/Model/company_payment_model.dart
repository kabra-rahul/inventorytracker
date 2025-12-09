//payment_model.dart

import 'package:inventorytracker/Shared/Constants/firestore_constants.dart';

class PaymentModel {
  final String id;
  final String companyId;
  final double amount;
  final String plan;
  final String status;
  final DateTime paidAt;
  final String paymentId;
  final String orderId;
  final String method;
  final String email;
  final String contact;

  PaymentModel({
    required this.id,
    required this.companyId,
    required this.amount,
    required this.plan,
    required this.status,
    required this.paidAt,
    required this.paymentId,
    required this.orderId,
    required this.method,
    required this.email,
    required this.contact,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      FirestoreConstants.companyIdField    : companyId,
      FirestoreConstants.amountField       : amount,
      FirestoreConstants.companyPlanField  : plan,
      FirestoreConstants.orderStatusField  : status,
      FirestoreConstants.paidAtField       : paidAt.toIso8601String(),
      FirestoreConstants.paymentIdField    : paymentId,
      FirestoreConstants.orderIdField      : orderId,
      FirestoreConstants.paymentMethodField: method,
      FirestoreConstants.userEmailField    : email,
      FirestoreConstants.userMobileField   : contact,
    };
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id       : map['id'] ?? '',
      companyId: map[FirestoreConstants.companyIdField] ?? '',
      amount   : (map[FirestoreConstants.amountField] ?? 0).toDouble(),
      plan     : map[FirestoreConstants.companyPlanField] ?? '',
      status   : map[FirestoreConstants.orderStatusField] ?? '',
      paidAt   : DateTime.parse(map[FirestoreConstants.paidAtField]),
      paymentId: map[FirestoreConstants.paymentIdField] ?? '',
      orderId  : map[FirestoreConstants.orderIdField] ?? '',
      method   : map[FirestoreConstants.paymentMethodField] ?? '',
      email    : map[FirestoreConstants.userEmailField] ?? '',
      contact  : map[FirestoreConstants.userMobileField] ?? '',
    );
  }
}