// outward_stock_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:inventorytracker/Functionality/Product/Model/product_model.dart';
import 'package:inventorytracker/Functionality/Client/Model/client_model.dart';
import 'package:inventorytracker/Functionality/Stock/Model/batch_model.dart';
import 'package:inventorytracker/Functionality/Product/Provider/product_provider.dart';
import 'package:inventorytracker/Functionality/Client/Provider/client_provider.dart';
import 'package:inventorytracker/Functionality/Units/Provider/unit_provider.dart';
import 'package:inventorytracker/Provider/connectivity_provider.dart';
import 'package:inventorytracker/Shared/Constants/snackbar_color.dart';
import 'package:inventorytracker/Shared/Widgets/custom_text_field.dart';
import '../Model/stock_movement_model.dart';
import '../Provider/stock_movement_provider.dart';

// StateProvider for the BatchQuery
final _currentBatchQueryProvider = StateProvider<BatchQuery?>((ref) => null);

class OutwardStockPage extends ConsumerStatefulWidget {
  final String companyId;
  final String warehouseId;

  const OutwardStockPage({
    super.key,
    required this.companyId,
    required this.warehouseId
  });

  @override
  ConsumerState<OutwardStockPage> createState() => _OutwardStockPageState();
}

class _OutwardStockPageState extends ConsumerState<OutwardStockPage> {
  Product? selectedProduct;
  Client? selectedClient;

  final TextEditingController productController = TextEditingController();
  final TextEditingController clientController = TextEditingController();
  final TextEditingController pricePerUnitController = TextEditingController();
  final ScrollController horizontalScrollController = ScrollController();

  final _formKey = GlobalKey<FormState>();

  // Consolidate: Map to store TextEditingControllers for *selected* batches.
  // The quantity will be read directly from these controllers when needed.
  final Map<String, TextEditingController> _selectedBatchQtyControllers = {};

  final TextEditingController _dummyController = TextEditingController();

  double _roundToTwoDecimals(double value) {
    if (value.isNaN || value.isInfinite) return 0.0;
    // Uses standard mathematical rounding based on the string representation.
    return double.parse(value.toStringAsFixed(2));
  }

  @override
  void dispose() {
    productController.dispose();
    clientController.dispose();
    pricePerUnitController.dispose();
    _selectedBatchQtyControllers.forEach((key, controller) => controller.dispose());
    horizontalScrollController.dispose();
    super.dispose();
  }

  // Helper to get or create a controller for a batch.
  // It ensures that if a batch is selected, it has a controller associated.
  /*TextEditingController _getOrCreateController(String batchId) {
    if (!_selectedBatchQtyControllers.containsKey(batchId)) {
      _selectedBatchQtyControllers[batchId] = TextEditingController(text: '0');
    }
    return _selectedBatchQtyControllers[batchId]!;
  }*/

  // Reset batch related states when product changes
  void _resetBatchStates() {
    _selectedBatchQtyControllers.forEach((key, controller) => controller.dispose());
    _selectedBatchQtyControllers.clear();
    ref.read(_currentBatchQueryProvider.notifier).state = null;
  }

  // Calculate total quantity from selected batch controllers
  double _calculateTotalMoveQuantity() {
    double total = 0.0;
    _selectedBatchQtyControllers.forEach((batchId, controller) {
      total += _roundToTwoDecimals(double.tryParse(controller.text) ?? 0.0);
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {

    final isConnected = ref.watch(isConnectedProvider);
    final productListAsync = ref.watch(productListProvider);
    final clientListAsync = ref.watch(clientListProvider);
    final allUnitsMapAsync = ref.watch(allUnitsMapProvider);
    final List<BatchModel> list = [];

    final batchQuery = ref.watch(_currentBatchQueryProvider);
    final batchListAsync = batchQuery != null
        ? ref.watch(batchListProvider(batchQuery))
        : AsyncValue.data(list);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Outward Movement'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(_currentBatchQueryProvider.notifier).state = null;
            context.pop();
          },
        ),
      ),
      body: productListAsync.when(
        data: (productList) {
          return clientListAsync.when(
            data: (clientList) {
              return allUnitsMapAsync.when(
                data: (unitsMap) {
                  final unitSymbol = selectedProduct != null
                      ? unitsMap[selectedProduct!.unitId] ?? ''
                      : '';

                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Autocomplete
                            Autocomplete<Product>(
                              optionsBuilder: (TextEditingValue textEditingValue) {
                                if (textEditingValue.text.isEmpty) {
                                  return const Iterable<Product>.empty();
                                }
                                return productList.where((Product p) => p.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                              },
                              displayStringForOption: (Product p) => p.name,
                              onSelected: (Product p) {
                                setState(() {
                                  selectedProduct = p;
                                  productController.text = p.name;
                                  _resetBatchStates(); // Reset batch states when product changes
                                });
                              },
                              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                productController.text = controller.text;
                                return CustomTextField(
                                  label: 'Product',
                                  hintText: 'Search and select product',
                                  controller: controller,
                                  focusNode: focusNode,
                                  onFieldSubmitted: onFieldSubmitted,
                                  validator: (value) {
                                    if (selectedProduct == null ) {
                                      return 'Please select a product';
                                    }
                                    if (value?.trim().isEmpty ?? true) {
                                      return 'Product Name cannot be empty'; // More specific message
                                    }
                                    return null;
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 16),

                            // Client Autocomplete (Optional)
                            // Assuming clientList is available in scope (List<Client>)
                            Autocomplete<Client>(
                              optionsBuilder: (TextEditingValue textEditingValue) {
                                final input = textEditingValue.text.trim();

                                // If empty, clear selection and return nothing
                                if (input.isEmpty) {
                                  // Defer clearing selectedClient to after this frame
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    // NOTE: We check if selectedClient is not null to avoid redundant setState calls
                                    if (mounted && selectedClient != null) setState(() => selectedClient = null);
                                  });
                                  return const Iterable<Client>.empty();
                                }

                                final lowerInput = input.toLowerCase();

                                // 1. Find matches for the dropdown
                                // Assuming we use the full clientList for matching
                                final matches = clientList
                                    .where((c) => c.companyName.toLowerCase().contains(lowerInput))
                                    .toList();

                                // 2. Find exact match (case-insensitive)
                                final exactMatchList = clientList
                                    .where((c) => c.companyName.trim().toLowerCase() == lowerInput);
                                final Client? exact = exactMatchList.isNotEmpty ? exactMatchList.first : null;

                                // 3. Defer updating selectedClient so we don't modify state during build.
                                // This updates the state to the exact match (or null) if the user types it in.
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) setState(() => selectedClient = exact);
                                });

                                return matches;
                              },

                              displayStringForOption: (Client c) => c.companyName,
                              onSelected: (Client c) => setState(() => selectedClient = c), // Tapping an option sets the state directly

                              // Added the clean optionsViewBuilder for responsiveness
                              optionsViewBuilder: (context, onSelected, options) => Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  elevation: 4,
                                  child: SizedBox(
                                    width: MediaQuery.of(context).size.width - 32,
                                    child: options.isEmpty
                                        ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Text('No matches found',style: TextStyle(color: Colors.grey)),
                                    )
                                        : ListView(
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      children: [
                                        ...options
                                            .map((c) => ListTile(
                                          title: Text(c.companyName),
                                          onTap: () => onSelected(c),
                                        ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              fieldViewBuilder: (
                                  context,
                                  controller,
                                  focusNode,
                                  onFieldSubmitted,
                                  ) {
                                return CustomTextField(
                                  label: 'Client (Optional)',
                                  hintText: 'Search and select client',
                                  controller: controller,
                                  focusNode: focusNode,
                                  onFieldSubmitted: onFieldSubmitted,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return null; // Client is optional, so empty input is fine.
                                    }
                                    // If text is present, but no selection (exact match or dropdown tap) was made, it's invalid.
                                    if (selectedClient == null) {
                                      return 'Please select a valid client from the list.';
                                    }
                                    return null;
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 20),

                            // --- Conditional UI based on batchListAsync state ---
                            batchListAsync.when(
                              data: (availableBatches) {
                                if (batchQuery != null) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 20),
                                      const Text(
                                        'Available Batches',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Row(
                                          children: [
                                            Icon(Icons.swipe_left, size: 16, color: Colors.grey),
                                            SizedBox(width: 8),
                                            Text(
                                              'Scroll horizontally to view all batch data',
                                              style: TextStyle(color: Colors.grey, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Scrollbar(
                                        controller: horizontalScrollController,
                                        thumbVisibility: true,
                                        trackVisibility: true,
                                        thickness: 6.0,
                                        child: SingleChildScrollView(
                                          controller: horizontalScrollController,
                                          scrollDirection: Axis.horizontal,
                                          child: Card(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10), // Sets rounded corners
                                            ),
                                            clipBehavior: Clip.antiAlias,
                                              child: DataTable(
                                                columnSpacing: 10,
                                                dataRowMinHeight: 50,
                                                dataRowMaxHeight: 70,
                                                headingRowHeight: 58,
                                                horizontalMargin: 5.0,
                                                dataRowColor: WidgetStateProperty.all(Colors.grey.shade200) ,
                                                headingRowColor:  WidgetStateProperty.all(Colors.blue.shade200),
                                                columns: [
                                                  const DataColumn(label: SizedBox(width: 50,  child: Text(''))),
                                                  const DataColumn(label: SizedBox(width: 180, child: Text('Suppliers Name'))),
                                                  const DataColumn(label: SizedBox(width: 100, child: Text('Lot Number'), )),
                                                  const DataColumn(label: SizedBox(width: 100, child: Text('Move Quantity'))),
                                                  DataColumn(label: SizedBox(width: 100, child: Center(child: Text('Quantity')))),
                                                  DataColumn(label: SizedBox(width: 100, child: Text('Price Per $unitSymbol'))),
                                                ],
                                                rows: availableBatches.map((batch) {
                                                  final isSelected = _selectedBatchQtyControllers.containsKey(batch.batchId);
                                                  final TextEditingController? qtyController = isSelected
                                                      ? _selectedBatchQtyControllers[batch.batchId]
                                                      : (() {
                                                    _dummyController.text = ''; // Side effect: Clears the field visually
                                                    return _dummyController;    // Return value: The cleared controller
                                                  })();

                                                  return DataRow(
                                                    key: ValueKey(batch.batchId),
                                                    selected: isSelected,
                                                    cells: [
                                                      DataCell(Center(
                                                        child: Checkbox(
                                                          value: isSelected,
                                                          onChanged: (bool? value) {
                                                            setState(() {
                                                              if (value == true) {
                                                                _selectedBatchQtyControllers[batch.batchId] = TextEditingController(text: '0');
                                                              } else {
                                                                _selectedBatchQtyControllers[batch.batchId]?.dispose();
                                                                _selectedBatchQtyControllers.remove(batch.batchId);
                                                              }
                                                            });
                                                          },
                                                        ),
                                                      )),
                                                      DataCell(Text(batch.supplierName.isEmpty ? 'N/A' :batch.supplierName)),
                                                      DataCell(Text(batch.batchNumber)),
                                                      DataCell(
                                                        SizedBox(
                                                          width: 80,
                                                          child: Center(
                                                            child: TextField(
                                                              controller: qtyController,
                                                              enabled: isSelected,
                                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                              inputFormatters: [
                                                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                                              ],
                                                              onChanged: (value) {
                                                                setState(() {});
                                                              },
                                                              decoration: InputDecoration(
                                                                filled: isSelected ? true:false,
                                                                fillColor: Colors.white,
                                                                border: OutlineInputBorder(),
                                                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      DataCell(Center(child: Text(batch.quantity.toStringAsFixed(2)))),
                                                      DataCell(Center(child: Text(batch.pricePerUnit.toString())))
                                                    ],
                                                  );
                                                }).toList(),
                                              ),

                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 20),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          'Total Quantity: ${_calculateTotalMoveQuantity()} $unitSymbol',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      CustomTextField(
                                        label: 'Price per $unitSymbol',
                                        hintText: 'Enter Selling Price Per $unitSymbol',
                                        controller: pricePerUnitController,
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                        ],
                                      ),

                                      const SizedBox(height: 20),

                                      Center(
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: _calculateTotalMoveQuantity() > 0
                                                ? () async {
                                              await saveOutwardStock(availableBatches);
                                            }
                                                : null,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              foregroundColor: Colors.white ,
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: const Text('Submit Outward Movement'),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                } else {
                                  return Center(
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: selectedProduct == null
                                            ? null
                                            : () {
                                          if(!isConnected) {
                                            showErrorSnackbar('No Internet Connection.');
                                            return;
                                          } else if (_formKey.currentState!.validate()) {
                                            ref.read(_currentBatchQueryProvider.notifier).state = BatchQuery(
                                              warehouseId: widget.warehouseId,
                                              productId: selectedProduct!.id,
                                            );
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white ,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Text('Load Batches'),
                                      ),
                                    ),
                                  );
                                }
                              },
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (err, stack) => Center(child: Text('Error loading batches: $err')),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error loading units: $err')),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error loading clients: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading products: $err')),
      ),
    );
  }

  Future<void> saveOutwardStock(List<BatchModel> availableBatches) async {
    final isConnected = ref.read(isConnectedProvider);
    if (!isConnected) {
      showErrorSnackbar('No Internet Available');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      showErrorSnackbar('Please correct the errors in the form.');
      return;
    }

    final List<BatchAffected> batchesToMove = [];
    bool validationFailed = false;

    // Iterate through _selectedBatchQtyControllers to get selected batches and their quantities
    for (final entry in _selectedBatchQtyControllers.entries) {
      final batchId = entry.key;
      final controller = entry.value;
      final qty = _roundToTwoDecimals(double.tryParse(controller.text) ?? 0.0);

      if (qty > 0) {
        final batchModel = availableBatches.firstWhere(
              (b) => b.batchId == batchId,
          orElse: () => throw Exception('BatchModel not found for ID: $batchId'),
        );

        if (qty > batchModel.quantity) {
          showErrorSnackbar('Move quantity for Lot Number ${batchModel.batchNumber} exceeds available quantity (${batchModel.quantity}).');
          validationFailed = true;
          break; // Exit the loop on first validation failure
        }
        batchesToMove.add(BatchAffected(batchId: batchId, quantity: qty));
      }
    }

    if (validationFailed) {
      return;
    }

    if (batchesToMove.isEmpty) {
      showErrorSnackbar('Please enter a quantity for at least one selected batch.');
      return;
    }

    //final price = double.tryParse(pricePerUnitController.text.trim()) ?? 0.0;
    //final totalQuantity = batchesToMove.fold(0.0, (sum, b) => sum + b.quantity);
    final totalQuantity = _roundToTwoDecimals(batchesToMove.fold(0.0, (sum, b) => sum + b.quantity));
    final price = _roundToTwoDecimals(double.tryParse(pricePerUnitController.text.trim()) ?? 0.0);

    try {
      if (selectedProduct == null) {
        showErrorSnackbar('Please select a product before saving.');
        return;
      }

      final stockService = await ref.read(stockMovementServiceProvider.future);
      await stockService.outwardStock(
        warehouseId: widget.warehouseId,
        productId: selectedProduct!.id,
        batchesAffected: batchesToMove,
        totalQuantity: totalQuantity,
        clientId: selectedClient?.id ?? '',
        pricePerUnit: price,
        ref: ref
      );

      showSuccessSnackbar('Outward stock saved successfully!');

      if (!mounted) return;

      // Reset form after successful save
      productController.clear();
      clientController.clear();
      pricePerUnitController.clear();
      setState(() {
        selectedProduct = null;
        selectedClient = null;
        _resetBatchStates(); // Clear all batch related UI and data
        _formKey.currentState?.reset(); // Reset form fields
      });

      // It's usually good practice to pop after a successful submission if it navigates away.
      // If the user should stay on this page to enter more, remove this line.
      context.pop();
    } catch (e) {
      showErrorSnackbar('Error saving outward stock: $e');
    }
  }

  void showErrorSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: SnackBarColor.errorMessage));
  }

  void showSuccessSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: SnackBarColor.successMessage));
  }
}