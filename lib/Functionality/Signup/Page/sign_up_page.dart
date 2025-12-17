//signup_page.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventorytracker/Shared/Constants/size_constants.dart';
import 'package:inventorytracker/Shared/Constants/snackbar_color.dart';
import 'package:inventorytracker/Shared/Widgets/common_submit_button.dart';
import 'package:inventorytracker/Shared/Widgets/custom_text_field.dart';
import 'package:inventorytracker/routes/app_router.dart';
import 'package:inventorytracker/Shared/Util/validators.dart';
import '../Provider/signup_provider.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}


class _SignupPageState extends ConsumerState<SignupPage> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signupProvider);
    final notifier = ref.read(signupProvider.notifier);

    final nameC = ref.watch(nameControllerProvider);
    final emailC = ref.watch(emailControllerProvider);
    final passwordC = ref.watch(passwordControllerProvider);
    final mobileC = ref.watch(mobileControllerProvider);
    final companyNameC = ref.watch(companyNameControllerProvider);
    final gstC = ref.watch(gstControllerProvider);

    ref.listen<SignupState>(signupProvider, (previous, current) {
      if (current.error != null && !current.isLoading) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(current.error!),
              backgroundColor: SnackBarColor.errorMessage,
            ),
          );
        }
      } else if (current.isSuccess && !current.isLoading) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Account created successfully'),
              backgroundColor: SnackBarColor.successMessage,
            ),
          );
          context.go(AppRoutePaths.dashboard);
        }
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up'), centerTitle: true,),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(SizeConstants.pageFormPadding),
        child: Form(
          key: notifier.formKey,
          child: Column(
            children: [
              const SizedBox(height: SizeConstants.spaceBeforeAndAfterField),
              CustomTextField(
                label: 'Full Name',
                controller: nameC,
                hintText: 'Enter your full name',
                validator: validateRequired,
              ),
              const SizedBox(height: SizeConstants.spaceBetweenFields),
              CustomTextField(
                label: 'Mobile Number',
                controller: mobileC,
                hintText: 'Enter your mobile number',
                keyboardType: TextInputType.phone,
                validator: validateMobile,
              ),
              const SizedBox(height: SizeConstants.spaceBetweenFields),
              CustomTextField(
                label: 'Email',
                controller: emailC,
                validator: validateEmail,
                keyboardType: TextInputType.emailAddress,
                hintText: 'Enter your email',
              ),
              const SizedBox(height: SizeConstants.spaceBetweenFields),
              CustomTextField(
                label: 'Password',
                controller: passwordC,
                validator: validatePassword,
                isPassword: true,
                hintText: 'Set Password',
              ),
              const SizedBox(height: SizeConstants.spaceBetweenFields),
              CustomTextField(
                label: 'Company Name',
                controller: companyNameC,
                validator: validateRequired,
                hintText: 'Enter your company name',
              ),
              const SizedBox(height: SizeConstants.spaceBetweenFields),
              CustomTextField(
                label: 'GST Number (Optional)',
                controller: gstC,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null; // Optional field
                  return validateGst(value); // Run GST validation if non-empty
                },
                hintText: 'Enter GST Number',
              ),
              const SizedBox(height: SizeConstants.spaceBeforeAndAfterField),
              state.isLoading
                  ? const CircularProgressIndicator()
                  : CustomElevatedButton(
                      text: 'Create Account',
                      onPressed: () => notifier.submit(ref)
                  ),
              const SizedBox(height: SizeConstants.spacebeforeLink),
              Text.rich(
                TextSpan(
                  text: "Already have an account? Log in",
                  style: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer:
                      TapGestureRecognizer()
                        ..onTap = () => context.go(AppRoutePaths.login),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}