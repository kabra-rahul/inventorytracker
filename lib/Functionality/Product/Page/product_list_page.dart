//product_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventorytracker/Functionality/Product/Model/product_model.dart';
import 'package:inventorytracker/Functionality/Product/Provider/product_provider.dart';
import 'package:inventorytracker/Routes/app_router.dart';
import 'package:inventorytracker/Shared/Constants/plan_constants.dart';
import 'package:inventorytracker/Shared/Constants/size_constants.dart';
import 'package:inventorytracker/Shared/Constants/snackbar_color.dart';
import 'package:inventorytracker/Shared/Widgets/card_list_item.dart';
import 'package:inventorytracker/Shared/Widgets/custom_text_field.dart';
import 'package:inventorytracker/Provider/app_store_provider.dart';

/// Page that lists all products for a given company
/// Supports real-time updates, add, edit, delete operations
class ProductListPage extends ConsumerStatefulWidget {
  const ProductListPage({super.key});

  @override
  ConsumerState<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends ConsumerState<ProductListPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Listen to search query changes from the provider
    _searchController.addListener(() {
      ref.read(productSearchQueryProvider.notifier).state =
          _searchController.text;
    });
  }

  @override
  void dispose() {
    // Dispose controller to avoid memory leak
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToEditPage(Product? product) {
    ref.read(editProductProvider.notifier).state = product;
    context.push(AppRoutePaths.productEdit); // Use GoRouter to navigate
  }

  @override
  Widget build(BuildContext context) {
    final showInactive = ref.watch(showInactiveProductsProvider);
    final filteredProductsAsync = ref.watch(filteredProductListProvider);
    final productCountAsync = ref.watch(totalProductCountProvider);
    final appStore = ref.watch(appStoreDataProvider);
    final isLimitReached = productCountAsync.maybeWhen(
      data: (count) => count >= 2,
      orElse: () => false, // Default to false if loading or error
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop(); // Takes user back to home
          },
        ),
        actions: [
          Row(
            children: [
              const Text("Show Inactive"),
              Padding(
                padding: const EdgeInsets.only(right: SizeConstants.paddingForToggle),
                child: Switch(
                  value: showInactive,
                  onChanged: (val) => ref.read(showInactiveProductsProvider.notifier).state = val
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: SizeConstants.spaceBeforeAndAfterField),
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: CustomTextField(
              controller: _searchController,
              hintText: 'Search products...',
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                },
              ),
            ),
          ),
          const SizedBox(height: SizeConstants.spaceBetweenFields),
          Expanded(
            child: filteredProductsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return const Center(
                    child: Text(
                      'No Products found',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final isDisabled = !product.active;
                    //listCount = products.length;
                    return CardListItem(
                      key: ValueKey(product.id), // Pass the key
                      title: isDisabled
                          ? '${product.name} (Disabled)'
                          : product.name,
                      textColor: isDisabled ? Colors.grey[600] : Colors.black87,
                      textFontStyle: isDisabled ? FontStyle.italic : FontStyle.normal,
                      onTap: () => _navigateToEditPage(product),
                      // trailing: Icon(Icons.info), // You could customize trailing here if needed
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        shape: const CircleBorder(), // For the circular shape
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          if (appStore == null ) {
            // If plan is null (meaning appStore data isn't ready or user not logged in),
            // you might want to show a message or disable the FAB entirely.
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('User plan data not available yet. Please wait.'), backgroundColor: SnackBarColor.errorMessage));
            return; // Prevent further execution
          }

          final currentPlan = appStore.plan;

          if(isLimitReached  && currentPlan == PlanConstants.freePlan) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Can add only 2 Product in Free Plan. Convert to Paid Plan to add more'), backgroundColor: SnackBarColor.errorMessage));
          } else if(currentPlan != PlanConstants.freePlan && appStore.planExpiry != null && appStore.planExpiry!.add(const Duration(days: 7)).isBefore(DateTime.now())) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Please Renew the Paid Plan to continue Adding New Products'), backgroundColor: SnackBarColor.errorMessage));
          }
          else {
            _navigateToEditPage(null); // Navigate to add new product
          }
        },
      ),
    );
  }
}
