//login_page.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventorytracker/Routes/app_router.dart';
import 'package:inventorytracker/Shared/Constants/size_constants.dart';
import 'package:inventorytracker/Shared/Constants/snackbar_color.dart';
import 'package:inventorytracker/Shared/Widgets/common_submit_button.dart';
import 'package:inventorytracker/Shared/Widgets/custom_text_field.dart';
import 'package:inventorytracker/Provider/app_store_provider.dart';
import '../../../Model/app_store_model.dart';
import '../Provider/login_provider.dart';
import 'package:inventorytracker/Shared/Util/validators.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  // Helper function to display the SnackBar
  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: SnackBarColor.errorMessage,
      ),
    );
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loginState = ref.watch(loginProvider);
    final loginNotifier = ref.read(loginProvider.notifier);
    final emailController = ref.watch(emailProvider);
    final passwordController = ref.watch(passwordProvider);

    ref.listen<LoginState>(loginProvider, (previous, current) {
      if (current.errorMessage != null && !current.isLoading) {
        if (context.mounted) {
          String displayMessage = current.errorMessage!;

          if (displayMessage.toLowerCase().contains('incorrect')) {
            displayMessage = "Incorrect email or password. Please try again.";
          }

          _showErrorSnackbar(context, displayMessage);
        }
      }
    });

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(SizeConstants.pageFormPadding),
          child: Form(
            key: loginNotifier.formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min, // Make the column size itself to its children
              children: [
                // Existing email/password fields
                CustomTextField(
                  label: 'Email',
                  controller: emailController,
                  hintText: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  validator: validateEmail,
                ),
                const SizedBox(height: SizeConstants.spaceBetweenFields),
                CustomTextField(
                  label: 'Password',
                  controller: passwordController,
                  hintText: 'Enter password',
                  isPassword: true,
                  validator: validatePassword,
                ),
                const SizedBox(height: SizeConstants.spaceBeforeAndAfterField),
                if (loginState.errorMessage != null)
                  Text(
                    '',
                    style: const TextStyle(color: Colors.red),
                  ),
                loginState.isLoading
                    ? const CircularProgressIndicator()
                    : CustomElevatedButton(
                  text: 'Login',
                  onPressed: () {
                    _handleLogin(context, ref);
                  },
                ),

                // Separator for social login
                const SizedBox(height: SizeConstants.spaceBeforeAndAfterField),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text("OR"),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: SizeConstants.spaceBeforeAndAfterField),

                const SizedBox(height: SizeConstants.spacebeforeLink),
                Text.rich(
                  TextSpan(
                    text: "Don't have an account? ",
                    children: [
                      TextSpan(
                        text: 'Sign up',
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => context.go(AppRoutePaths.signup),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: SizeConstants.spacebeforeLink),
                Text.rich(
                  TextSpan(
                    text: 'Forgot your password? ',
                    children: [
                      TextSpan(
                        text: 'Reset here',
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => context.go(AppRoutePaths.forgotPassword),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Future<void> _handleLogin(BuildContext context, WidgetRef ref) async {
    final loginNotifier = ref.read(loginProvider.notifier);

    // Step 1: Attempt login. This returns user if successful, null otherwise.
    // Error messages are set in the provider state if it fails.
    final user = await loginNotifier.login();

    if (!context.mounted) return;

    // Step 2: If authentication was successful (user is not null), check authorization.
    if (user != null) {
      try {
        // Wait for company/user data to be loaded/checked via appStoreProvider
        final AppStore? appStore = await ref.read(appStoreProvider.future);

        if (!context.mounted) return;


        if (appStore != null && appStore.hasAccess) {
          // Success: Navigate to dashboard.
          context.go(AppRoutePaths.dashboard);
        } else {
          // Authorization failure: User is logged in, but lacks required company access.
          context.go(AppRoutePaths.login);
          // _showErrorSnackbar(context, 'Access denied or profile setup incomplete. Please contact support.');
        }
      } catch (e) {
        if (!context.mounted) return;
        // Error loading AppStore data (e.g., Firestore issue).
        context.go(AppRoutePaths.login);
        _showErrorSnackbar(context, 'Error loading user data after successful login: Please try again.');
      }
    }
  }
}
/*final store = ref.read(appStoreProvider);
      Future.microtask(() {
        if (!context.mounted) return; // Re-check mounted after microtask

        store.when(
          data: (appStore) {
            if (appStore == null || !context.mounted) return; // Final check before navigation
            if (!appStore.hasAccess) {
              context.go(AppRoutePaths.login);
            } else {
              context.go(AppRoutePaths.dashboard);
            }
          },
          loading: () {},
          error: (err, _) {
            if (!context.mounted) return; // Check before showing snackbar/navigation
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error checking company access: ${err.toString()}')),
            );
            context.go(AppRoutePaths.login);
          },
        );
      });*/