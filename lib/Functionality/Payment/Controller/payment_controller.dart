//payment_controller.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:inventorytracker/Functionality/Payment/Model/company_payment_model.dart';
import 'package:inventorytracker/Functionality/Payment/Service/company_payment_service.dart';
import 'package:inventorytracker/Shared/Constants/plan_constants.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';


class PaymentController extends StateNotifier<AsyncValue<void>> {
  final CompanyPaymentService _repository;
  late Razorpay _razorpay;
  String? _companyId;
  double? _amount;
  String? _plan;
  String? _email;
  String? _contact;

  PaymentController(this._repository) : super(const AsyncValue.data(null)) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  /// Opens the Razorpay checkout
  /// Opens Razorpay Checkout dynamically
  void openCheckout({
    required String companyId,
    required double amount,
    required String plan, // "first_year" or "renewal"
    required String contact,
    required String email,
  }) {
    _companyId = companyId;
    _amount = amount;
    _plan = plan;
    _email = email;
    _contact = contact;

    //need to check fo how to update it
    var options = {
      'key': dotenv.env['RAZORPAY_KEY'] ?? '', // ✅ from .env
      'amount': (amount * 100).toInt(),
      'name': 'Inventory tracker',
      'description': plan == PlanConstants.paidPlan
          ? 'First-year onboarding plan (₹2000)'
          : 'Annual renewal plan (₹1000)',
      'prefill': {'contact': _contact, 'email': _email},
      'external': {'wallets': ['paytm', 'phonepe', 'amazonpay']},
    };

    try {
      _razorpay.open(options);
      state = const AsyncValue.loading();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }


  /// Handles successful payment
  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_companyId == null || _amount == null) return;

    try {
      // Prevent double callback
      final existing = await _repository.getPaymentById(response.paymentId!);
      if (existing != null) return;

      // Calculate plan expiry — 1 year from now for renewal or purchase
      final expiry = DateTime.now().add(const Duration(days: 365));

      await _repository.updateCompanyPlan(_companyId!, _plan!, expiry: expiry);

      final payment = PaymentModel(
        id: response.paymentId!,
        companyId: _companyId!,
        amount: _amount!,
        plan: _plan!,
        status: 'success',
        paidAt: DateTime.now(),
        paymentId: response.paymentId!,
        orderId: response.orderId ?? '',
        method: 'razorpay',
        email: _email ?? '', // fill if you have user email
        contact: _contact ?? '', // fill if you have user contact
      );

      await _repository.savePaymentDetails(payment.toMap());

      // Optionally call verification here (future addition)
      //await verifyPaymentOnServer(response.paymentId!, response.orderId!, response.signature!);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }


  Future<void> _handlePaymentError(PaymentFailureResponse response) async {
    if (response.code == Razorpay.PAYMENT_CANCELLED) {
      // User cancelled the payment manually
      state = const AsyncValue.data(null);
    } else {
      state = AsyncValue.error("Payment failed: ${response.message}", StackTrace.current);
    }
  }


  void _handleExternalWallet(ExternalWalletResponse response) {
    state = const AsyncValue.data(null);
  }


  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }
}