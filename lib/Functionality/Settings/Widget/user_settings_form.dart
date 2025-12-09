//user_settings_form.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventorytracker/Functionality/User/Model/app_user_model.dart';
import 'package:inventorytracker/Functionality/User/Provider/user_provider.dart';
import 'package:inventorytracker/Shared/Constants/size_constants.dart';
import 'package:inventorytracker/Shared/Constants/snackbar_color.dart';
import 'package:inventorytracker/Shared/Util/validators.dart';
import 'package:inventorytracker/Shared/Widgets/common_submit_button.dart';
import 'package:inventorytracker/Shared/Widgets/custom_text_field.dart';
import 'package:go_router/go_router.dart';
import 'package:inventorytracker/Routes/app_router.dart';
import 'package:inventorytracker/Provider/app_store_provider.dart';
import '../Provider/user_settings_notifier.dart';

class UserSettingsForm extends ConsumerStatefulWidget {
  const UserSettingsForm({super.key});

  @override
  ConsumerState<UserSettingsForm> createState() => _UserSettingsFormState();
}

class _UserSettingsFormState extends ConsumerState<UserSettingsForm> {
  final _formKey = GlobalKey<FormState>();
  final _pwdFormKey = GlobalKey<FormState>();

  late final TextEditingController _nameC;
  late final TextEditingController _mobileC;
  late final TextEditingController _emailC;

  final TextEditingController _oldPwdC = TextEditingController();
  final TextEditingController _newPwdC = TextEditingController();
  final TextEditingController _confirmPwdC = TextEditingController();

  bool _controllersInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameC = TextEditingController();
    _mobileC = TextEditingController();
    _emailC = TextEditingController();
  }

  @override
  void dispose() {
    _nameC.dispose();
    _mobileC.dispose();
    _emailC.dispose();
    _oldPwdC.dispose();
    _newPwdC.dispose();
    _confirmPwdC.dispose();
    super.dispose();
  }

  void _updateControllers(AppUser userData) {
    if (!_controllersInitialized) {
      _nameC.text = userData.userName;
      _mobileC.text = userData.mobile;
      _emailC.text = userData.email;
      _controllersInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appData = ref.watch(appStoreDataProvider);
    final userSettingsState = ref.watch(userSettingsProvider);
    final userSettingsNotifier = ref.read(userSettingsProvider.notifier);

    ref.listen<UserSettingsState>(userSettingsProvider, (previous, current) {
      if (current.error != null && !current.isLoading) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(current.error!), backgroundColor: SnackBarColor.errorMessage),
          );
          userSettingsNotifier.clearMessages(); // Clear error after showing
        }
      } else if (current.success != null && !current.isLoading) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(current.success!), backgroundColor: SnackBarColor.successMessage),
          );
          userSettingsNotifier.clearMessages(); // Clear success after showing
        }
      }

      if (current.passwordUpdatedAndLoggedOut && !current.isLoading) {
        if (mounted) {
          // Clear this flag after navigation
          userSettingsNotifier.clearMessages();
          // Navigate to login page after successful password update and logout
          GoRouter.of(context).go(AppRoutePaths.login); // Assuming you have AppRoutePaths.login
        }
      }
    });

    if (appData == null || appData.uid.isEmpty || appData.companyId.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'User session data not fully loaded or available. Please ensure you are logged in.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final userAsyncValue = ref.watch(userByIdProvider(appData.uid));

    return SingleChildScrollView(
      child: Column(
        children: [
          userAsyncValue.when(
            data: (userData) {
              _updateControllers(userData);
              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      label: 'Name',
                      controller: _nameC,
                      hintText: 'Enter your name',
                      validator: validateRequired,
                    ),
                    const SizedBox(height: SizeConstants.spaceBetweenFields),
                    CustomTextField(
                      label: 'Mobile',
                      controller: _mobileC,
                      hintText: 'Enter your mobile number',
                      keyboardType: TextInputType.phone,
                      validator: validateMobile,
                    ),
                    const SizedBox(height: SizeConstants.spaceBetweenFields),
                    CustomTextField(
                      label: 'Email',
                      controller: _emailC,
                      hintText: 'Enter your email',
                      keyboardType: TextInputType.emailAddress,
                      validator: validateEmail,
                    ),
                    const SizedBox(height: SizeConstants.spaceBeforeAndAfterField),
                    userSettingsState.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : CustomElevatedButton(
                          text: 'Save Profile',
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              userSettingsNotifier.updateProfile(
                                name: _nameC.text.trim(),
                                mobile: _mobileC.text.trim(),
                                email: _emailC.text.trim(),
                                companyId: appData.companyId,
                              );
                            }
                          }
                        ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error loading user data: ${e.toString()}')),
          ),

          const SizedBox(height: SizeConstants.spaceBetweenFields),
          const Divider(),
          const SizedBox(height: SizeConstants.spaceBetweenFields),
          Form(
            key: _pwdFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: const Padding(
                    padding: EdgeInsets.only(bottom: SizeConstants.pageFormPadding),
                    child: Text('Update Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18), textAlign: TextAlign.center),
                  ),
                ),
                const SizedBox(height: SizeConstants.spaceBetweenFields),
                CustomTextField(
                  label: 'Old Password',
                  controller: _oldPwdC,
                  hintText: 'Enter old password',
                  isPassword: true,
                  validator: validateRequired,
                ),
                const SizedBox(height: SizeConstants.spaceBetweenFields),
                CustomTextField(
                  label: 'New Password',
                  controller: _newPwdC,
                  hintText: 'Enter new password',
                  isPassword: true,
                  validator: validatePassword, // Ensure this validates min length etc.
                ),
                const SizedBox(height: SizeConstants.spaceBetweenFields),
                CustomTextField(
                  label: 'Confirm Password',
                  controller: _confirmPwdC,
                  hintText: 'Confirm new password',
                  isPassword: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirmation is required';
                    if (v != _newPwdC.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: SizeConstants.spaceBeforeAndAfterField),
                userSettingsState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : CustomElevatedButton( // --- USE YOUR NEW WIDGET HERE ---
                        text: 'Update Password',
                        onPressed: ()  {
                          if (_pwdFormKey.currentState!.validate()) {
                              // 1. Await the update.\
                              // If it completes successfully, we proceed to the next line.
                              userSettingsNotifier.updatePassword(
                                oldPassword: _oldPwdC.text.trim(),
                                newPassword: _newPwdC.text.trim(),
                              );

                              // --- If the update was successful (no exception was thrown) ---
                              // 2. Reset the LoginNotifier state
                              //ref.read(loginProvider.notifier).reset();

                              // 3. Clear the text fields
                              _oldPwdC.clear();
                              _newPwdC.clear();
                              _confirmPwdC.clear();

                          }
                        }
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}