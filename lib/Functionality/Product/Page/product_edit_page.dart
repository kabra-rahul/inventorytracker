import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventorytracker/Functionality/Dashboard/Provider/dashboard_provider.dart';
import 'package:inventorytracker/Functionality/Product/Provider/product_provider.dart';
import 'package:inventorytracker/Shared/Constants/size_constants.dart';
import 'package:inventorytracker/Shared/Constants/snackbar_color.dart';
import 'package:inventorytracker/Shared/Widgets/common_submit_button.dart';
import 'package:inventorytracker/Shared/Widgets/confirmation_dialog.dart';
import 'package:inventorytracker/Shared/Widgets/custom_dropdown_field.dart';
import 'package:inventorytracker/Shared/Widgets/custom_text_field.dart';
import 'package:inventorytracker/Shared/Util/validators.dart';
import '../Model/product_model.dart';
import '../../../Model/dropdown_item_model.dart';


/// Edit/Add product page
class ProductEditPage extends ConsumerStatefulWidget {

  const ProductEditPage({super.key});

  @override
  ConsumerState<ProductEditPage> createState() => _ProductEditPageState();
}

class _ProductEditPageState extends ConsumerState<ProductEditPage> {
  final _nameController = TextEditingController();
  final _lowStockController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // For form validation
  late bool _isActive;
  Product? _initialProduct;

  DropdownItem? selectedCategory;
  DropdownItem? selectedHSN;
  DropdownItem? selectedUnit;

  bool _isInitialDataLoaded = false;

  @override
  void initState() {
    super.initState();

    _initialProduct = ref.read(editProductProvider);
    _isActive = _initialProduct?.active ?? true;

    if (_initialProduct != null) {
      _nameController.text = _initialProduct!.name;
      _lowStockController.text = _initialProduct!.lowStockAlert.toString();
    }
  }


  void _initializeDropdowns(
      List<DropdownItem> categories,
      List<DropdownItem> hsns,
      List<DropdownItem> units,
      ) {
    // Only run if we are in Edit mode and haven't loaded the data yet
    if (_initialProduct == null || _isInitialDataLoaded) {
      return;
    }

    // Category
    final categoryMatch = categories.where((c) => c.id == _initialProduct!.categoryId);
    selectedCategory = categoryMatch.isNotEmpty ? categoryMatch.first : null;

    // HSN
    final hsnMatch = hsns.where((h) => h.id == _initialProduct!.hsnId);
    selectedHSN = hsnMatch.isNotEmpty ? hsnMatch.first : null;

    // Unit
    final unitMatch = units.where((u) => u.id == _initialProduct!.unitId);
    selectedUnit = unitMatch.isNotEmpty ? unitMatch.first : null;

    // If any selection was made, update the state and flag
    if (selectedCategory != null || selectedHSN != null || selectedUnit != null) {
      setState(() {
        _isInitialDataLoaded = true;
      });
    }
  }


  @override
  void dispose() {
    _nameController.dispose();
    _lowStockController.dispose();
    super.dispose();
  }


  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return; // Form is invalid
    }

    final name = _nameController.text.trim();
    final lowStock = double.tryParse(_lowStockController.text.trim()) ?? 0;
    final messenger = ScaffoldMessenger.of(context);
    final productServiceAsync = ref.read(productServiceProvider);

    if (productServiceAsync.isLoading || productServiceAsync.hasError) {
      messenger.showSnackBar(
          SnackBar(content: Text('Product service not ready.'), backgroundColor: SnackBarColor.errorMessage));
      return;
    }
    final productService = productServiceAsync.requireValue;

    if (name.isEmpty || selectedCategory == null ||  selectedUnit == null || selectedHSN == null) {
      messenger.showSnackBar(SnackBar(content: Text('Please fill all the fields'), backgroundColor: SnackBarColor.errorMessage));
      return;
    }

    // Confirmation dialog
    final bool? confirm = await showConfirmationDialog(
      context,
      title: _initialProduct == null ? 'Add Product' : 'Update Product',
      content:
      _initialProduct == null
          ? 'Are you sure you want to add this product?'
          : 'Are you sure you want to update this product?',
    );

    if (confirm != true) {
      return; // User cancelled
    }

    try {
      // Check for duplicate name
      final isDuplicate = await productService.isDuplicate(
        name,
        _initialProduct?.id,
      );

      if (isDuplicate) {
        messenger.showSnackBar(
          SnackBar(content: Text('Product name already exists!'), backgroundColor: SnackBarColor.errorMessage),
        );
        return;
      }

      if (_initialProduct == null) {
        // Add new product
        final newProduct = Product(
            id: '',
            name: name,
            categoryId: selectedCategory!.id,
            hsnId: selectedHSN!.id,
            unitId: selectedUnit!.id,
            lowStockAlert: lowStock,
            active: _isActive
        );
        await productService.addProduct(newProduct);
        messenger.showSnackBar(
          SnackBar(content: Text('Product added successfully!'), backgroundColor: SnackBarColor.successMessage),
        );
      } else {
        if(lowStock != _initialProduct?.lowStockAlert) {
          ref.invalidate(productCountProvider);
        }
        // Update existing product
        final updatedProduct = _initialProduct!.copyWith(
          name: name,
          categoryId: selectedCategory!.id,
          hsnId: selectedHSN!.id,
          unitId: selectedUnit!.id,
          lowStockAlert: lowStock,
          active: _isActive,
        );
        await productService.updateProduct(updatedProduct);
        messenger.showSnackBar(
          SnackBar(content: Text('Product updated successfully!'), backgroundColor: SnackBarColor.successMessage),
        );
      }
      // Clear selected product
      ref.read(editProductProvider.notifier).state = null;

      if (mounted) context.pop(); // Go back to list page
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error saving product: ${e.toString()}'), backgroundColor: SnackBarColor.errorMessage),
      );
    }
  }


  @override
  Widget build(BuildContext context) {

    final categoryAsync = ref.watch(categoryDropdownListProvider);
    final hsnAsync = ref.watch(hsnDropdownListProvider);
    final unitAsync = ref.watch(unitDropdownListProvider);

    final isDataReady = categoryAsync.hasValue && hsnAsync.hasValue && unitAsync.hasValue;

    if (isDataReady && _initialProduct != null && !_isInitialDataLoaded) {
      // We use addPostFrameCallback to ensure setState is called after the build phase finishes
      // This prevents the "setState() called during build" error, though it's technically
      // safe since we are guarded by the _isInitialDataLoaded flag.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeDropdowns(
          categoryAsync.value!,
          hsnAsync.value!,
          unitAsync.value!,
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
          title: Text(
            _initialProduct == null ? 'Add Product' : 'Edit Product',
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              context.pop(); // Takes user back to home
            },
          )
      ),
      body: Padding(
        padding: const EdgeInsets.all(SizeConstants.pageFormPadding),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: SizeConstants.spaceBeforeAndAfterField),
              CustomTextField(
                label: 'Product Name',
                controller: _nameController,
                hintText: 'Enter product name',
                validator: validateRequired,
              ),
              const SizedBox(height: SizeConstants.spaceBetweenFields),
              CustomDropdownField(
                label: 'Product Category',
                value: selectedCategory?.id,
                hint: 'Choose Category',
                onChanged: (value) {
                  setState(() {
                    selectedCategory = categoryAsync.value?.firstWhere((item) => item.id == value);
                  });
                },
                items: categoryAsync,
              ),
              const SizedBox(height: SizeConstants.spaceBetweenFields),
              CustomDropdownField(
                label: 'Product HSN',
                value: selectedHSN?.id,
                hint: 'Choose HSN',
                onChanged: (value) {
                  setState(() {
                    selectedHSN = hsnAsync.value?.firstWhere((item) => item.id == value);
                  });
                },
                items: hsnAsync,
              ),
              const SizedBox(height: SizeConstants.spaceBetweenFields),
              CustomDropdownField(
                label: 'Product Unit',
                value: selectedUnit?.id,
                hint: 'Choose Unit',
                onChanged: (value) {
                  setState(() {
                    selectedUnit = unitAsync.value?.firstWhere((item) => item.id == value);
                  });
                },
                items: unitAsync,
              ),
              const SizedBox(height: SizeConstants.spaceBetweenFields),
              CustomTextField(
                label: 'Low Stock Alert On',
                controller: _lowStockController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: SizeConstants.spaceBeforeAndAfterField),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Active',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Switch(
                    value: _isActive,
                    onChanged: (val) {
                      setState(() {
                        _isActive = val;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomElevatedButton(
          text: _initialProduct == null
              ? 'Add Product'
              : 'Update Product',
          onPressed: _saveProduct
      ),
    );
  }
}
