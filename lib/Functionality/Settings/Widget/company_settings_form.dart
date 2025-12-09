import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventorytracker/Functionality/Settings/Model/company_model.dart';
import 'package:inventorytracker/Functionality/Settings/Provider/settings_provider.dart';
import 'package:inventorytracker/Shared/Constants/size_constants.dart';
import 'package:inventorytracker/Shared/Constants/snackbar_color.dart';
import 'package:inventorytracker/Shared/Util/validators.dart';
import 'package:inventorytracker/Shared/Widgets/common_submit_button.dart';
import 'package:inventorytracker/Shared/Widgets/custom_text_field.dart';
import 'package:inventorytracker/Provider/app_store_provider.dart';
import '../Provider/company_settings_notifier.dart'; // Assuming you'll create this

class CompanySettingsForm extends ConsumerStatefulWidget {
  const CompanySettingsForm({super.key});

  @override
  ConsumerState<CompanySettingsForm> createState() => _CompanySettingsFormState();
}

class _CompanySettingsFormState extends ConsumerState<CompanySettingsForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameC;
  late final TextEditingController _gstC;
  late final TextEditingController _addrC;

  bool _controllersInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameC = TextEditingController();
    _gstC = TextEditingController();
    _addrC = TextEditingController();
  }

  @override
  void dispose() {
    _nameC.dispose();
    _gstC.dispose();
    _addrC.dispose();
    super.dispose();
  }

  void _updateControllers(Company companyData) {
    if (!_controllersInitialized) {
      _nameC.text = companyData.companyName;
      _gstC.text = companyData.gst;
      _addrC.text = companyData.address;
      _controllersInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appData = ref.watch(appStoreDataProvider);
    final companySettingsState = ref.watch(companySettingsProvider);
    final companySettingsNotifier = ref.read(companySettingsProvider.notifier);

    ref.listen<CompanySettingsState>(companySettingsProvider, (previous, current) {
      if (current.error != null && !current.isLoading) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(current.error!), backgroundColor: SnackBarColor.errorMessage),

          );
          companySettingsNotifier.clearMessages();
        }
      } else if (current.success != null && !current.isLoading) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(current.success!), backgroundColor: SnackBarColor.successMessage),
          );
          companySettingsNotifier.clearMessages();
        }
      }
    });
    if (appData == null || appData.companyId.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Company data not fully loaded or available. Please ensure you are logged in.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final companyAsyncValue = ref.watch(companyProvider(appData.companyId));

    return SingleChildScrollView(
      child: Column(
        children: [
          companyAsyncValue.when(
            data: (companyData) {
              _updateControllers(companyData);
              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      label: 'Company Name',
                      controller: _nameC,
                      hintText: 'Enter company name',
                      validator: validateRequired,
                    ),
                    const SizedBox(height: SizeConstants.spaceBetweenFields),
                    CustomTextField(
                      label: 'GST Number',
                      controller: _gstC,
                      hintText: 'Enter GST number',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null; // Optional field
                        return validateGst(value); // Run GST validation if non-empty
                      },
                    ),
                    const SizedBox(height: SizeConstants.spaceBetweenFields),
                    CustomTextField(
                      label: 'Address',
                      controller: _addrC,
                      hintText: 'Enter company address',
                      maxLines: 3,
                    ),
                    const SizedBox(height: SizeConstants.spaceBeforeAndAfterField),
                    companySettingsState.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : CustomElevatedButton(
                      text: 'Update Company Details',
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          companySettingsNotifier.update(
                            companyId: appData.companyId,
                            name: _nameC.text.trim(),
                            gst: _gstC.text.trim(),
                            address: _addrC.text.trim(),
                            ref: ref
                          );
                          //ref.invalidate(companyProvider(appData.companyId));
                        }
                      },
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error loading company data: ${e.toString()}')),
          ),
        ],
      ),
    );
  }
}