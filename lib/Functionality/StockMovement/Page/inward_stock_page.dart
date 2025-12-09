// inward_stock_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventorytracker/Functionality/Product/Model/product_model.dart';
import 'package:inventorytracker/Functionality/Supplier/Model/supplier_model.dart';
import 'package:inventorytracker/Functionality/Units/Provider/unit_provider.dart';
import 'package:inventorytracker/Provider/connectivity_provider.dart';
import 'package:inventorytracker/Shared/Constants/snackbar_color.dart';
import 'package:inventorytracker/Shared/Widgets/custom_text_field.dart';
import 'package:inventorytracker/Functionality/Product/Provider/product_provider.dart';
import 'package:inventorytracker/Functionality/Supplier/Provider/supplier_provider.dart';
import '../Provider/stock_movement_provider.dart';
import '../Service/stock_movement_service.dart'; // adjust import path

class InwardStockPage extends ConsumerStatefulWidget {
  final String companyId;
  final String warehouseId;

  const InwardStockPage({
    super.key,
    required this.companyId,
    required this.warehouseId,
  });

  @override
  ConsumerState<InwardStockPage> createState() => _InwardStockPageState();
}

class _InwardStockPageState extends ConsumerState<InwardStockPage> {
  Product? selectedProduct;
  Supplier? selectedSupplier;
  StockMovementService? stockService;

  final TextEditingController batchNumberController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController pricePerUnitController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Cache the stock service once
    ref.read(stockMovementServiceProvider.future).then((service) {
      if (mounted) {
        setState(() {
          stockService = service;
        });
      }
    });
  }

  @override
  void dispose() {
    batchNumberController.dispose();
    quantityController.dispose();
    pricePerUnitController.dispose();
    super.dispose();
  }


  double _roundToTwoDecimals(double value) {
    if (value.isNaN || value.isInfinite) return 0.0;
    // Uses standard mathematical rounding based on the string representation.
    return double.parse(value.toStringAsFixed(2));
  }


  @override
  Widget build(BuildContext context) {
    final productListAsync = ref.watch(productListProvider);
    final supplierListAsync = ref.watch(supplierListProvider);
    final unitSymbolAsync =
        selectedProduct != null ? ref.watch(allUnitsMapProvider) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inward Stock'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: productListAsync.when(
        data: (productList) {
          return supplierListAsync.when(
            data: (supplierList) {
              final activeSupplierList =
                  supplierList.where((s) => s.active).toList();

              return Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Product Autocomplete
                        Autocomplete<Product>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return const Iterable<Product>.empty();
                            }
                            return productList.where(
                              (p) => p.name.toLowerCase().contains(
                                textEditingValue.text.toLowerCase(),
                              ),
                            );
                          },
                          displayStringForOption: (p) => p.name,
                          onSelected: (p) {
                            setState(() => selectedProduct = p);
                          },
                          fieldViewBuilder: (
                            context,
                            controller,
                            focusNode,
                            onFieldSubmitted,
                          ) {
                            return CustomTextField(
                              label: 'Product',
                              hintText: 'Search and select Product',
                              controller: controller,
                              focusNode: focusNode,
                              onFieldSubmitted: () => saveInwardStock(),
                              validator: (_) {
                                if (selectedProduct == null) {
                                  return 'Please select a product from List';
                                }
                                return null;
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 12),

                        // Supplier Autocomplete
                        Autocomplete<Supplier>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            final input = textEditingValue.text.trim();

                            // If empty, clear selection and return nothing
                            if (input.isEmpty) {
                              // Defer clearing selectedSupplier to after this frame
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted && selectedSupplier != null)  setState(() => selectedSupplier = null);
                              });
                              return const Iterable<Supplier>.empty();
                            }

                            // Find matches
                            final matches = activeSupplierList
                                .where((s) => s.companyName.toLowerCase().contains(input.toLowerCase()))
                                .toList();

                            // Find exact match (case-insensitive)
                            final exactMatchList = activeSupplierList
                                .where((s) => s.companyName.trim().toLowerCase() == input.toLowerCase());
                            final Supplier? exact = exactMatchList.isNotEmpty ? exactMatchList.first : null;

                            // Defer updating selectedSupplier so we don't modify state during build
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) setState(() => selectedSupplier = exact);
                            });
                            return matches;
                          },

                          displayStringForOption: (s) => s.companyName,
                          onSelected            : (s) => setState(() => selectedSupplier = s),
                          optionsViewBuilder    : (context, onSelected, options) => Align(
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
                                          ...options.map((s) => ListTile(
                                                  title: Text(s.companyName),
                                                  onTap: () => onSelected(s),
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
                              label: 'Supplier',
                              hintText: 'Search and select Supplier',
                              controller: controller,
                              focusNode: focusNode,
                              onFieldSubmitted: () {},
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return null; // optional
                                }
                                // If the user typed text, but the background logic determined it wasn't a valid selection
                                // (because selectedSupplier is still null), then it's invalid.
                                if (selectedSupplier == null) {
                                  return 'Please select a supplier from the list.';
                                }
                                // If selectedSupplier is NOT null, it means the deferred logic found an exact match
                                // or the user used the dropdown, so it is valid.
                                return null;
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 12),

                        // Lot Number
                        CustomTextField(
                          label: 'Lot Number',
                          controller: batchNumberController,
                        ),
                        const SizedBox(height: 12),

                        // Quantity
                        CustomTextField(
                          label: 'Quantity',
                          controller: quantityController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'),
                            ),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Quantity is mandatory';
                            }
                            if (double.tryParse(value) == null ||
                                double.parse(value) <= 0) {
                              return 'Please enter a valid quantity';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Price per Unit (dynamic label)
                        Builder(
                          builder: (context) {
                            final unitSymbol =
                                (unitSymbolAsync?.maybeWhen(
                                  data:
                                      (unitsMap) =>
                                          unitsMap[selectedProduct?.unitId] ??
                                          '',
                                  orElse: () => '',
                                )) ??
                                '';

                            return CustomTextField(
                              label:
                                  unitSymbol.isNotEmpty
                                      ? 'Price per $unitSymbol'
                                      : 'Price per Unit',
                              controller: pricePerUnitController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d{0,2}'),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: saveInwardStock,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white ,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Submit Inward Movement'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (err, _) =>
                    Center(child: Text('Error loading suppliers: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading products: $err')),
      ),
    );
  }

  Future<void> saveInwardStock() async {
    final isConnected = ref.read(isConnectedProvider);
    if (!isConnected) {
      showErrorSnackbar('No Internet Connection');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      showErrorSnackbar('Please correct the errors in the form.');
      return;
    }

    final product = selectedProduct;
    final supplier = selectedSupplier;
    //final qty = double.tryParse(quantityController.text.trim());
    final parsedQty = double.tryParse(quantityController.text.trim());
    final qty = parsedQty != null ? _roundToTwoDecimals(parsedQty) : null;

    final parsedPrice = double.tryParse(pricePerUnitController.text.trim()) ?? 0.0;
    final price = _roundToTwoDecimals(parsedPrice);

    if (widget.warehouseId.isEmpty) {
      showErrorSnackbar('Warehouse ID is missing. Cannot save stock.');
      return;
    }

    if (product == null || qty == null || qty <= 0) {
      showErrorSnackbar('Invalid product or quantity');
      return;
    }
    if (stockService == null) {
      showErrorSnackbar('Service not ready yet');
      return;
    }

    try {
      await stockService!.inwardStock(
        warehouseId: widget.warehouseId,
        productId: product.id,
        supplierId: supplier?.id ?? '',
        batchNumber: batchNumberController.text.trim(),
        quantity: qty,
        pricePerUnit: price,
        ref: ref
      );

      showSuccessSnackbar('Inward Stock saved successfully!');
      if (!mounted) return;
      context.pop();
    } catch (e) {
      showErrorSnackbar('Error saving inward stock: $e');
    }
  }

  void showErrorSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: SnackBarColor.errorMessage,));
  }

  void showSuccessSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: SnackBarColor.successMessage));
  }
}
