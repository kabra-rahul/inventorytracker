// supplier_edit_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventorytracker/Shared/Constants/size_constants.dart';
import 'package:inventorytracker/Shared/Constants/snackbar_color.dart';
import 'package:inventorytracker/Shared/Util/validators.dart';
import 'package:inventorytracker/Shared/Widgets/common_submit_button.dart';
import '../../../Shared/Widgets/custom_text_field.dart';
import '../../../Provider/app_store_provider.dart';
import '../Model/supplier_model.dart';
import '../Provider/supplier_provider.dart';
import '../../../Shared/Widgets/confirmation_dialog.dart'; // For navigation

class SupplierEditPage extends ConsumerStatefulWidget {
  const SupplierEditPage({super.key});

  @override
  ConsumerState<SupplierEditPage> createState() => _SupplierEditPageState();
}

class _SupplierEditPageState extends ConsumerState<SupplierEditPage> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _gstController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // For form validation
  late bool _isActive;
  Supplier? _initialSupplier; // To hold the supplier being edited

  @override
  void initState() {
    super.initState();
    // Read the initial supplier when the widget is initialized
    _initialSupplier = ref.read(editSupplierProvider);

    if (_initialSupplier != null) {
      _nameController.text = _initialSupplier!.companyName;
      _addressController.text = _initialSupplier!.address;
      _gstController.text = _initialSupplier!.gst;
      _isActive = _initialSupplier!.active;
    } else {
      _isActive = true; // Default for new supplier
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  Future<void> _saveSupplier() async {
    if (!_formKey.currentState!.validate()) {
      return; // Form is invalid
    }

    final companyId = ref.read(appStoreProvider).value?.companyId;
    final supplierService = ref.read(supplierServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final gst = _gstController.text.trim();

    // Confirmation dialog
    final bool? confirm = await showConfirmationDialog(
      context,
      title: _initialSupplier == null ? 'Add Supplier' : 'Update Supplier',
      content:
          _initialSupplier == null
              ? 'Are you sure you want to add this supplier?'
              : 'Are you sure you want to update this supplier?',
    );

    if (confirm != true) {
      return; // User cancelled
    }

    try {
      // Check for duplicate name
      if (gst.isNotEmpty || gst != '') {
        final isDuplicate = await supplierService.isDuplicate(
          companyId.toString(),
          gst,
          _initialSupplier?.id,
        );

        if (isDuplicate) {
          messenger.showSnackBar(
            SnackBar(content: Text('Supplier GST already exists!'), backgroundColor: SnackBarColor.errorMessage)
          );
          return;
        }
      }

      final isDuplicate = await supplierService.isDuplicateSupplier(
        companyId.toString(),
        name,
        _initialSupplier?.id,
      );

      if (isDuplicate) {
        messenger.showSnackBar(
          SnackBar(content: Text('Supplier Name already exists!'), backgroundColor: SnackBarColor.errorMessage)
        );
        return;
      }

      if (_initialSupplier == null) {
        // Add new supplier
        final newSupplier = Supplier(
          id: '',
          companyName: name,
          address: address,
          gst: gst,
          active: _isActive,
        );
        await supplierService.addSupplier(companyId.toString(), newSupplier);
        messenger.showSnackBar(
          SnackBar(content: Text('Supplier added successfully!'), backgroundColor: SnackBarColor.successMessage)
        );
      } else {
        // Update existing supplier
        final updatedSupplier = _initialSupplier!.copyWith(
          companyName: name,
          address: address,
          gst: gst,
          active: _isActive,
        );
        await supplierService.updateSupplier(companyId.toString(), updatedSupplier);
        messenger.showSnackBar(
          SnackBar(content: Text('Supplier updated successfully!'), backgroundColor: SnackBarColor.successMessage)
        );
      }

      // Clear selected supplier
      ref.read(editSupplierProvider.notifier).state = null;

      if (mounted) context.pop(); // Go back to list page
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error saving supplier: ${e.toString()}'), backgroundColor: SnackBarColor.errorMessage)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_initialSupplier == null ? 'Add Supplier' : 'Edit Supplier'),
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
                label: 'Supplier Name',
                controller: _nameController,
                hintText: 'Enter supplier name',
                validator: validateRequired,
              ),
              const SizedBox(height: SizeConstants.spaceBetweenFields),
              CustomTextField(
                label: 'Supplier Address',
                controller: _addressController,
                hintText: 'Enter Address',
              ),
              const SizedBox(height: SizeConstants.spaceBetweenFields),
              CustomTextField(
                label: 'Supplier GST',
                controller: _gstController,
                hintText: 'Enter GST',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null; // Optional field
                  return validateGst(value); // Run GST validation if non-empty
                },
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
          text: _initialSupplier == null ? 'Add Supplier' : 'Update Supplier',
          onPressed: _saveSupplier
      ),
    );
  }
}
