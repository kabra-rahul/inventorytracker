// lib/features/warehouse/views/warehouse_edit_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventorytracker/Shared/Constants/size_constants.dart';
import 'package:inventorytracker/Shared/Constants/snackbar_color.dart';
import 'package:inventorytracker/Shared/Widgets/common_submit_button.dart';
import '../../../Shared/Util/validators.dart';
import '../../../Shared/Widgets/custom_text_field.dart';
import '../Model/warehouse_model.dart';
import '../Provider/warehouse_provider.dart';
import '../../../Shared/Widgets/confirmation_dialog.dart'; // For navigation

class WarehouseEditPage extends ConsumerStatefulWidget {
  const WarehouseEditPage({super.key});

  @override
  ConsumerState<WarehouseEditPage> createState() => _WarehouseEditPageState();
}

class _WarehouseEditPageState extends ConsumerState<WarehouseEditPage> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // For form validation
  late bool _isActive;
  Warehouse? _initialWarehouse; // To hold the warehouse being edited


  @override
  void initState() {
    super.initState();
    // Read the initial warehouse when the widget is initialized
    _initialWarehouse = ref.read(editWarehouseProvider);

    if (_initialWarehouse != null) {
      _nameController.text = _initialWarehouse!.name;
      _locationController.text = _initialWarehouse!.location;
      _isActive = _initialWarehouse!.active;
    } else {
      _isActive = true; // Default for new warehouse
    }
  }


  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }


  Future<void> _saveWarehouse() async {
    if (!_formKey.currentState!.validate()) {
      return; // Form is invalid
    }

    final messenger = ScaffoldMessenger.of(context);
    final name = _nameController.text.trim();
    final location = _locationController.text.trim();
    final warehouseService = await ref.read(warehouseServiceProvider.future);

    // Confirmation dialog
    if(!mounted) return;

    final bool? confirm = await showConfirmationDialog(context,
      title: _initialWarehouse == null ? 'Add Warehouse' : 'Update Warehouse',
      content:
      _initialWarehouse == null
          ? 'Are you sure you want to add this warehouse?'
          : 'Are you sure you want to update this warehouse?',
    );

    if (confirm != true) {
      return; // User cancelled
    }

    try {
      // Check for duplicate name
      final isDuplicate = await warehouseService.isDuplicate(
        name,
        _initialWarehouse?.id,
      );

      if (isDuplicate) {
        messenger.showSnackBar(
          SnackBar(content: Text('Warehouse name already exists!'), backgroundColor: SnackBarColor.errorMessage)
        );
        return;
      }

      if (_initialWarehouse == null) {
        // Add new warehouse
        final newWarehouse = Warehouse(id: '', name: name, location: location, active: _isActive);
        await warehouseService.addWarehouse(
            newWarehouse
        );
        messenger.showSnackBar(SnackBar(content: Text('Warehouse added successfully!'), backgroundColor: SnackBarColor.successMessage),
        );
      } else {
        // Update existing warehouse
        final updatedWarehouse = _initialWarehouse!.copyWith(
          name: name,
          location: location,
          active: _isActive,
        );
        await warehouseService.updateWarehouse(
          updatedWarehouse,
        );
        messenger.showSnackBar(
          SnackBar(content: Text('Warehouse updated successfully!'), backgroundColor: SnackBarColor.successMessage),
        );
      }

      // Clear selected warehouse
      ref.read(editWarehouseProvider.notifier).state = null;

      if (mounted) context.pop(); // Go back to list page
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error saving warehouse: ${e.toString()}'), backgroundColor: SnackBarColor.errorMessage)
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
            _initialWarehouse == null ? 'Add Warehouse' : 'Edit Warehouse',
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
                label: 'Warehouse Name',
                controller: _nameController,
                hintText: 'Enter warehouse name',
                validator: validateRequired,
              ),
              const SizedBox(height: SizeConstants.spaceBetweenFields),
              CustomTextField(
                label: 'Warehouse Location',
                controller: _locationController,
                hintText: 'Enter warehouse location',
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
          text: _initialWarehouse == null
              ? 'Add Warehouse'
              : 'Update Warehouse',
          onPressed: _saveWarehouse
      ),
    );
  }
}
