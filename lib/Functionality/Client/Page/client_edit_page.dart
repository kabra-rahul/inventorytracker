// lib/features/client/views/client_edit_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventorytracker/Shared/Constants/size_constants.dart';
import 'package:inventorytracker/Shared/Util/validators.dart';
import 'package:inventorytracker/Shared/Widgets/common_submit_button.dart';
import '../../../Shared/Constants/snackbar_color.dart';
import '../../../Shared/Widgets/custom_text_field.dart';
import '../../../Provider/app_store_provider.dart';
import '../Model/client_model.dart';
import '../Provider/client_provider.dart';
import '../../../Shared/Widgets/confirmation_dialog.dart'; // For navigation

class ClientEditPage extends ConsumerStatefulWidget {
  const ClientEditPage({super.key});

  @override
  ConsumerState<ClientEditPage> createState() => _ClientEditPageState();
}

class _ClientEditPageState extends ConsumerState<ClientEditPage> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _gstController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // For form validation
  late bool _isActive;
  Client? _initialClient; // To hold the client being edited

  @override
  void initState() {
    super.initState();
    // Read the initial client when the widget is initialized
    _initialClient = ref.read(editClientProvider);

    if (_initialClient != null) {
      _nameController.text = _initialClient!.companyName;
      _addressController.text = _initialClient!.address;
      _gstController.text = _initialClient!.gst;
      _isActive = _initialClient!.active;
    } else {
      _isActive = true; // Default for new client
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) {
      return; // Form is invalid
    }

    final companyId = ref.read(appStoreProvider).value?.companyId;
    final clientService = ref.read(clientServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final gst = _gstController.text.trim();

    // Confirmation dialog
    final bool? confirm = await showConfirmationDialog(
      context,
      title: _initialClient == null ? 'Add Client' : 'Update Client',
      content:
          _initialClient == null
              ? 'Are you sure you want to add this client?'
              : 'Are you sure you want to update this client?',
    );

    if (confirm != true) {
      return; // User cancelled
    }

    try {
      // Check for duplicate name
      if (gst.isNotEmpty || gst != '') {
        final isDuplicate = await clientService.isDuplicate(
          companyId.toString(),
          gst,
          _initialClient?.id,
        );

        if (isDuplicate) {
          messenger.showSnackBar(SnackBar(content: Text('Client GST already exists!'),backgroundColor: SnackBarColor.errorMessage));
          return;
        }
      }

      final isDuplicate = await clientService.isDuplicateClient(
        companyId.toString(),
        name,
        _initialClient?.id,
      );

      if (isDuplicate) {
        messenger.showSnackBar(SnackBar(content: Text('Client Name already exists!'),backgroundColor: SnackBarColor.errorMessage));
        return;
      }

      if (_initialClient == null) {
        // Add new client
        final newClient = Client(
          id: '',
          companyName: name,
          address: address,
          gst: gst,
          active: _isActive,
        );
        await clientService.addClient(companyId.toString(), newClient);
        messenger.showSnackBar(SnackBar(content: Text('Client added successfully!'), backgroundColor: SnackBarColor.successMessage));
      } else {
        // Update existing client
        final updatedClient = _initialClient!.copyWith(
          companyName: name,
          address: address,
          gst: gst,
          active: _isActive,
        );
        await clientService.updateClient(companyId.toString(), updatedClient);
        messenger.showSnackBar(SnackBar(content: Text('Client updated successfully!'), backgroundColor: SnackBarColor.successMessage));
      }

      // Clear selected client
      ref.read(editClientProvider.notifier).state = null;

      if (mounted) context.pop(); // Go back to list page
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error saving client: ${e.toString()}'), backgroundColor: SnackBarColor.errorMessage));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_initialClient == null ? 'Add Client' : 'Edit Client'),
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
                label: 'Client Name',
                controller: _nameController,
                hintText: 'Enter client name',
                validator: validateRequired,
              ),
              const SizedBox(height: SizeConstants.spaceBetweenFields),
              CustomTextField(
                label: 'Client Address',
                controller: _addressController,
                hintText: 'Enter Address',
              ),
              const SizedBox(height: SizeConstants.spaceBetweenFields),
              CustomTextField(
                label: 'Client GST',
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
          text: _initialClient == null ? 'Add Client' : 'Update Client',
          onPressed: _saveClient
      ),
    );
  }
}