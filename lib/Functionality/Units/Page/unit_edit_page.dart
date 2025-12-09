// lib/features/unit/views/unit_edit_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventorytracker/Shared/Constants/size_constants.dart';
import 'package:inventorytracker/Shared/Constants/snackbar_color.dart';
import 'package:inventorytracker/Shared/Widgets/common_submit_button.dart';
import '../../../Shared/Util/validators.dart';
import '../../../Shared/Widgets/custom_text_field.dart';
import '../../../Provider/app_store_provider.dart';
import '../Model/unit_model.dart';
import '../Provider/unit_provider.dart';
import '../../../Shared/Widgets/confirmation_dialog.dart'; // For navigation

class UnitEditPage extends ConsumerStatefulWidget {
  const UnitEditPage({super.key});

  @override
  ConsumerState<UnitEditPage> createState() => _UnitEditPageState();
}

class _UnitEditPageState extends ConsumerState<UnitEditPage> {
  final _nameController = TextEditingController();
  final _symbolController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // For form validation
  late bool _isActive;
  Unit? _initialUnit; // To hold the unit being edited


  @override
  void initState() {
    super.initState();
    // Read the initial unit when the widget is initialized
    _initialUnit = ref.read(editUnitProvider);

    if (_initialUnit != null) {
      _nameController.text = _initialUnit!.name;
      _symbolController.text = _initialUnit!.symbol;
      _isActive = _initialUnit!.active;
    } else {
      _isActive = true; // Default for new unit
    }
  }


  @override
  void dispose() {
    _nameController.dispose();
    _symbolController.dispose();
    super.dispose();
  }


  Future<void> _saveUnit() async {
    if (!_formKey.currentState!.validate()) {
      return; // Form is invalid
    }

    final companyId = ref.read(appStoreProvider).value?.companyId;
    final unitService = ref.read(unitServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    final name = _nameController.text.trim();
    final symbol = _symbolController.text.trim();

    // Confirmation dialog
    final bool? confirm = await showConfirmationDialog(
      context,
      title: _initialUnit == null ? 'Add Unit' : 'Update Unit',
      content:
      _initialUnit == null
          ? 'Are you sure you want to add this unit?'
          : 'Are you sure you want to update this unit?',
    );

    if (confirm != true) {
      return; // User cancelled
    }

    try {
      // Check for duplicate name
      final isDuplicate = await unitService.isDuplicate(
        companyId.toString(),
        symbol,
        _initialUnit?.id,
      );

      if (isDuplicate) {
        messenger.showSnackBar(
          SnackBar(content: Text('Unit name already exists!'), backgroundColor: SnackBarColor.errorMessage)
        );
        return;
      }

      if (_initialUnit == null) {
        // Add new unit
        final newUnit = Unit(id: '', name: name, symbol: symbol, active: _isActive);
        await unitService.addUnit(companyId.toString(), newUnit);
        messenger.showSnackBar(
          SnackBar(content: Text('Unit added successfully!'), backgroundColor: SnackBarColor.successMessage)
        );
      } else {
        // Update existing unit
        final updatedUnit = _initialUnit!.copyWith(
          name: name,
          symbol: symbol,
          active: _isActive,
        );
        await unitService.updateUnit(
          companyId.toString(),
          updatedUnit,
        );
        messenger.showSnackBar(
          SnackBar(content: Text('Unit updated successfully!'), backgroundColor: SnackBarColor.successMessage)
        );
      }

      // Clear selected unit
      ref.read(editUnitProvider.notifier).state = null;

      if (mounted) context.pop(); // Go back to list page
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error saving unit: ${e.toString()}'), backgroundColor: SnackBarColor.errorMessage),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
            _initialUnit == null ? 'Add Unit' : 'Edit Unit',
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
                label: 'Unit Name',
                controller: _nameController,
                hintText: 'Enter unit name',
                validator: validateRequired,
              ),
              const SizedBox(height: SizeConstants.spaceBetweenFields),
              CustomTextField(
                label: 'Unit Symbol',
                controller: _symbolController,
                hintText: 'Enter unit symbol',
                validator: validateRequired,
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
          text: _initialUnit == null
              ? 'Add Unit'
              : 'Update Unit',
          onPressed: _saveUnit
      ),
    );
  }
}
