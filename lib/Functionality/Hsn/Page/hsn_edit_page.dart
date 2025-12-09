// hsn_edit_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventorytracker/Shared/Constants/size_constants.dart';
import 'package:inventorytracker/Shared/Constants/snackbar_color.dart';
import 'package:inventorytracker/Shared/Widgets/common_submit_button.dart';
import '../../../Shared/Util/validators.dart';
import '../../../Shared/Widgets/custom_text_field.dart';
import '../../../Provider/app_store_provider.dart';
import '../Model/hsn_model.dart';
import '../Provider/hsn_provider.dart';
import '../../../Shared/Widgets/confirmation_dialog.dart'; // For navigation

class HsnEditPage extends ConsumerStatefulWidget {
  const HsnEditPage({super.key});

  @override
  ConsumerState<HsnEditPage> createState() => _HsnEditPageState();
}

class _HsnEditPageState extends ConsumerState<HsnEditPage> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // For form validation
  late bool _isActive;
  Hsn? _initialHsn; // To hold the hsn being edited


  @override
  void initState() {
    super.initState();
    // Read the initial hsn when the widget is initialized
    _initialHsn = ref.read(editHsnProvider);

    if (_initialHsn != null) {
      _codeController.text = _initialHsn!.code;
      _isActive = _initialHsn!.active;
    } else {
      _isActive = true; // Default for new hsn
    }
  }


  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }


  Future<void> _saveHsn() async {
    if (!_formKey.currentState!.validate()) {
      return; // Form is invalid
    }

    final companyId = ref.read(appStoreProvider).value?.companyId;
    final hsnService = ref.read(hsnServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    final code = _codeController.text.trim();

    // Confirmation dialog
    final bool? confirm = await showConfirmationDialog(
      context,
      title: _initialHsn == null ? 'Add Hsn' : 'Update Hsn',
      content:
      _initialHsn == null
          ? 'Are you sure you want to add this Hsn Code?'
          : 'Are you sure you want to update this Hsn Code?',
    );

    if (confirm != true) {
      return; // User cancelled
    }

    try {
      // Check for duplicate code
      final isDuplicate = await hsnService.isDuplicate(
        companyId.toString(),
        code,
        _initialHsn?.id,
      );

      if (isDuplicate) {
        messenger.showSnackBar(
          SnackBar(content: Text('Hsn code already exists!'), backgroundColor: SnackBarColor.errorMessage)
        );
        return;
      }

      if (_initialHsn == null) {
        // Add new hsn
        final newHsn = Hsn(id: '', code: code, active: _isActive);
        await hsnService.addHsn(companyId.toString(), newHsn);
        messenger.showSnackBar(
          SnackBar(content: Text('Hsn code added successfully!'), backgroundColor: SnackBarColor.successMessage),
        );
      } else {
        // Update existing hsn
        final updatedHsn = _initialHsn!.copyWith(
          code: code,
          active: _isActive,
        );
        await hsnService.updateHsn(
          companyId.toString(),
          updatedHsn,
        );
        messenger.showSnackBar(SnackBar(content: Text('Hsn code updated successfully!'), backgroundColor: SnackBarColor.successMessage));
      }

      // Clear selected hsn
      ref.read(editHsnProvider.notifier).state = null;

      if (mounted) context.pop(); // Go back to list page
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error saving hsn code : ${e.toString()}'), backgroundColor: SnackBarColor.errorMessage)
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
            _initialHsn == null ? 'Add Hsn Code' : 'Edit Hsn Code',
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
                label: 'Hsn Name',
                controller: _codeController,
                hintText: 'Enter HSN Code',
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
          text: _initialHsn == null
              ? 'Add Hsn'
              : 'Update Hsn',
          onPressed: _saveHsn
      ),
    );
  }
}
