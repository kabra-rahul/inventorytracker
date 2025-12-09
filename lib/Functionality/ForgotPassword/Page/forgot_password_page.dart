// pages/forgot_password_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventorytracker/Routes/app_router.dart';
import 'package:inventorytracker/Shared/Constants/size_constants.dart';
import 'package:inventorytracker/Shared/Constants/snackbar_color.dart';
import 'package:inventorytracker/Shared/Widgets/common_submit_button.dart';
import 'package:inventorytracker/Shared/Widgets/custom_text_field.dart';
import 'package:inventorytracker/Shared/Util/validators.dart';
import '../Provider/forgot_password_provider.dart';


class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();


  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }


  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(forgotPasswordProvider.notifier);

    // Trigger the reset


    try {
      await notifier.sendResetEmail(_emailController.text.trim());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset link sent. Check your email.'),
          backgroundColor: SnackBarColor.successMessage,
        ),
      );

      context.go(AppRoutePaths.login);

    } on Exception catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: SnackBarColor.errorMessage,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(forgotPasswordProvider.select((state) => state.isLoading));
    //final error = ref.watch(forgotPasswordProvider.select((state) => state.error));

    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(SizeConstants.pageFormPadding),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: SizeConstants.spaceBeforeAndAfterField),
              const Text('Enter your registered email to receive a password reset link.', textAlign: TextAlign.center),
              const SizedBox(height: SizeConstants.spaceBetweenFields),
              CustomTextField(
                label: 'Email',
                controller: _emailController,
                hintText: 'Enter your email',
                keyboardType: TextInputType.emailAddress,
                validator: validateEmail,
              ),
              const SizedBox(height: SizeConstants.spaceBeforeAndAfterField),
              isLoading
                ? const CircularProgressIndicator()
                : CustomElevatedButton(
                    text: 'Send Reset Link',
                    onPressed: _handleSubmit,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}