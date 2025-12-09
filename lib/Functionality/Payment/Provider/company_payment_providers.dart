//payment_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:inventorytracker/Functionality/Payment/Controller/payment_controller.dart';
import 'package:inventorytracker/Functionality/Payment/Model/company_payment_model.dart';
import 'package:inventorytracker/Functionality/Payment/Service/company_payment_service.dart';


final companyPaymentProvider = Provider<CompanyPaymentService>((ref) {
  return CompanyPaymentService(FirebaseFirestore.instance);
});


final paymentControllerProvider = StateNotifierProvider<PaymentController, AsyncValue<void>>((ref) {
  final repo = ref.watch(companyPaymentProvider);
  return PaymentController(repo);
});


final paymentHistoryProvider = StreamProvider.family<List<PaymentModel>, String>((ref, companyId) {
  final repo = ref.watch(companyPaymentProvider);
  return repo.streamPayment(companyId);
});
