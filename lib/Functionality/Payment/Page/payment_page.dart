// payment_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:inventorytracker/Functionality/Payment/Provider/company_payment_providers.dart';
import 'package:inventorytracker/Functionality/User/Provider/user_provider.dart';
import 'package:inventorytracker/Provider/app_store_provider.dart';
import 'package:inventorytracker/Shared/Constants/plan_constants.dart';
import 'package:inventorytracker/Shared/Widgets/common_submit_button.dart';

class PaymentPage extends ConsumerWidget {
  const PaymentPage({super.key});



  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appData = ref.watch(appStoreDataProvider);

    if (appData == null || appData.uid.isEmpty || appData.companyId.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'User session data not fully loaded or available. Please ensure you are logged in.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final userAsyncData = ref.watch(userByIdProvider(appData.uid));
    final paymentController = ref.read(paymentControllerProvider.notifier);
    final paymentState = ref.watch(paymentControllerProvider);
    final isLoading = paymentState.isLoading;
    final dateFormat = DateFormat('dd MMM yyyy hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: userAsyncData.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text("Error: $e")),
          data: (userData) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFreePlanCard(appData.plan),
                  const SizedBox(height: 20),
                  _buildPaidPlanCard(context, appData.plan, appData.isAdmin, isLoading, () {
                    if (appData.isAdmin) {
                      paymentController.openCheckout(
                        companyId: appData.companyId,
                        amount: 2000.0,
                        plan: PlanConstants.paidPlan,
                        contact: userData.mobile,
                        email: userData.email,
                      );
                    }
                  }),
                  const SizedBox(height: 20),
                  _buildRenewalPlanCard(context, appData.plan, appData.isAdmin, isLoading, () {
                    if (appData.isAdmin) {
                      paymentController.openCheckout(
                        companyId: appData.companyId,
                        amount: 1000.0,
                        plan: PlanConstants.renewalPlan,
                        contact: userData.mobile,
                        email: userData.email,
                      );
                    }
                  }),
                  const SizedBox(height: 30),
                  // Billing History Section
                  const Text(
                    "Payment History",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Stream of all payments
                  ref.watch(paymentHistoryProvider(appData.companyId)).when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Text("Error: $e"),
                    data: (payments) {
                      if (payments.isEmpty) {
                        return const Center(
                          child: Text(
                            "No Payments Yet",
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      final firstYear = payments.where((p) => p.plan == PlanConstants.paidPlan).toList();
                      final renewals = payments.where((p) => p.plan == PlanConstants.renewalPlan).toList();
                      renewals.sort((a, b) => b.paidAt.compareTo(a.paidAt));

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (firstYear.isNotEmpty)
                            _buildPaymentSection("Initial Payments", firstYear, dateFormat),
                          if (renewals.isNotEmpty)
                            _buildPaymentSection("Renewals", renewals, dateFormat),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Free plan card
  Widget _buildFreePlanCard(String plan) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text("Free Plan", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                if (plan == PlanConstants.freePlan)
                  _buildBadge("Current", Colors.blue),
                const Spacer(),
                const Text("₹0", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            _buildFeatureItem('Basic Inventory Tracking', true),
            _buildFeatureItem('3 Months Validity', true),
            _buildFeatureItem('Unlimited Transactions', true),
            _buildFeatureItem('Unlimited Products (Only 2 allowed)', false),
            _buildFeatureItem('Excel Report', false),
          ],
        ),
      ),
    );
  }

  /// Paid plan card
  Widget _buildPaidPlanCard(
      BuildContext context, String plan, bool isAdmin, bool isLoading, VoidCallback onUpgrade) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text("Pro Plan", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                if (plan == PlanConstants.paidPlan)
                  _buildBadge("Active", Colors.blue),
                const Spacer(),
                const Text("₹2,000", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            _buildFeatureItem('Inventory Tracking', true),
            _buildFeatureItem('1 Year Validity', true),
            _buildFeatureItem('Unlimited Transactions', true),
            _buildFeatureItem('Unlimited Products', true),
            _buildFeatureItem('Excel Report', true),
            _buildFeatureItem('Priority Support', true),
            _buildFeatureItem('Multiple Users Accounts', true),
            _buildFeatureItem('Available on both Mobile and Windows', true),
            const SizedBox(height: 16),
            if (plan == PlanConstants.freePlan && isAdmin)
              CustomElevatedButton(
                text: isLoading ? "Processing..." : "Upgrade to Pro Paid for ₹2,000",
                onPressed: isLoading ? null : onUpgrade,
              ),
          ],
        ),
      ),
    );
  }

  /// Renewal card
  Widget _buildRenewalPlanCard(
      BuildContext context, String plan, bool isAdmin, bool isLoading, VoidCallback onRenew) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text("Annual Renewal", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                if (plan == PlanConstants.renewalPlan) _buildBadge("Active", Colors.blue),
                const Spacer(),
                const Text("₹1,000", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            _buildFeatureItem('Extend plan validity by 1 year', true),
            const SizedBox(height: 16),
            if ((plan == PlanConstants.paidPlan || plan == PlanConstants.renewalPlan)  && isAdmin)
              CustomElevatedButton(
                text: isLoading ? "Processing..." : "Renew for ₹1,000",
                onPressed: isLoading ? null : onRenew,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildFeatureItem(String text, bool isIncluded) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isIncluded ? Icons.check : Icons.close,
            color: isIncluded ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(String title, List payments, DateFormat df) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        ...payments.map((p) {
          return Card(
            child: ListTile(
              //title: Text(p.plan == PlanConstants.paidPlan ? "First-year Payment Details" : "Renewal Payment Details", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Paid on                :   ${df.format(p.paidAt)}\nTransaction ID    :   ${p.paymentId}\nAmount Paid       :   ₹${p.amount.toStringAsFixed(0)}"),

            ),
          );
        }),
      ],
    );
  }
}
