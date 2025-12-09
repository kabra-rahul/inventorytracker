//supplier_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventorytracker/Functionality/Supplier/Model/supplier_model.dart';
import 'package:inventorytracker/Functionality/Supplier/Provider/supplier_provider.dart';
import 'package:inventorytracker/Shared/Constants/size_constants.dart';
import 'package:inventorytracker/Shared/Widgets/card_list_item.dart';
import 'package:inventorytracker/Shared/Widgets/custom_text_field.dart';
import 'package:inventorytracker/routes/app_router.dart';

/// Page that lists all suppliers for a given company
/// Supports real-time updates, add, edit, delete operations
class SupplierListPage extends ConsumerStatefulWidget {
  const SupplierListPage({super.key});

  @override
  ConsumerState<SupplierListPage> createState() => _SupplierListPageState();
}

class _SupplierListPageState extends ConsumerState<SupplierListPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Listen to search query changes from the provider
    _searchController.addListener(() {
      ref.read(supplierSearchQueryProvider.notifier).state =
          _searchController.text;
    });
  }

  @override
  void dispose() {
    // Dispose controller to avoid memory leak
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToEditPage(Supplier? supplier) {
    ref.read(editSupplierProvider.notifier).state = supplier;
    context.push(AppRoutePaths.supplierEdit); // Use GoRouter to navigate
  }

  @override
  Widget build(BuildContext context) {
    final showInactive = ref.watch(showInactiveSuppliersProvider);
    final filteredSuppliersAsync = ref.watch(filteredSupplierListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppliers'),
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
                  onChanged: (val) => ref.read(showInactiveSuppliersProvider.notifier).state = val
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
              hintText: 'Search suppliers...',
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
            child: filteredSuppliersAsync.when(
              data: (suppliers) {
                if (suppliers.isEmpty) {
                  return const Center(
                    child: Text(
                      'No Suppliers found',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: suppliers.length,
                  itemBuilder: (context, index) {
                    final supplier = suppliers[index];
                    final isDisabled = !supplier.active;
                    return CardListItem(
                        key: ValueKey(supplier.id), // Pass the key
                        title: isDisabled
                            ? '${supplier.companyName} (Disabled)'
                            : supplier.companyName,
                        textColor: isDisabled ? Colors.grey[600] : Colors.black87,
                        textFontStyle: isDisabled ? FontStyle.italic : FontStyle.normal,
                        onTap: () => _navigateToEditPage(supplier)
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
          _navigateToEditPage(null); // Navigate to add new supplier
        },
      ),
    );
  }
}