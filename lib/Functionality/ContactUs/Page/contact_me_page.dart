import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:inventorytracker/Shared/Constants/size_constants.dart';
import 'package:inventorytracker/Shared/Constants/snackbar_color.dart';
import 'package:inventorytracker/Shared/Widgets/common_submit_button.dart';
import 'package:inventorytracker/Shared/Widgets/custom_text_field.dart';
import 'package:inventorytracker/Shared/Util/validators.dart';
import '../Model/contact_message_model.dart';
import '../Provider/contact_me_provider.dart';

class ContactMePage extends ConsumerStatefulWidget {
  const ContactMePage({super.key});

  @override
  ConsumerState<ContactMePage> createState() => _ContactMePageState();
}

class _ContactMePageState extends ConsumerState<ContactMePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitMessage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    final message = ContactMessage(
      userName: _nameController.text.trim(),
      email: email,
      mobile: _phoneController.text.trim(),
      message: _messageController.text.trim(),
      messageSentOn: DateTime.now(),
    );

    try {
      await ref.read(contactServiceProvider).submitMessage(message);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Message sent successfully!'), backgroundColor: SnackBarColor.successMessage)
        );
      }

      _nameController.clear();
      _phoneController.clear();
      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sending message: $e'), backgroundColor: SnackBarColor.errorMessage));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Contact Us'),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                context.pop(); // Takes user back to home
              }
          ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(SizeConstants.pageFormPadding),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: SizeConstants.spaceBeforeAndAfterField),
                  CustomTextField(
                    label: 'Name',
                    controller: _nameController,
                    hintText: 'Enter your name',
                    validator: validateRequired,
                  ),
                  const SizedBox(height: SizeConstants.spaceBetweenFields),
                  CustomTextField(
                    label: 'Mobile',
                    controller: _phoneController,
                    hintText: 'Enter Your Mobile Number',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: SizeConstants.spaceBetweenFields),
                  CustomTextField(
                    label: 'Message',
                    controller: _messageController,
                    hintText: 'Write your message',
                    maxLines: 5,
                    validator: validateRequired,
                  ),
                  const SizedBox(height: SizeConstants.spaceBeforeAndAfterField),
                  CustomElevatedButton(
                    text: 'Submit',
                    onPressed: _isSubmitting ? null : _submitMessage,
                  ),
                ],
              ),
            ),
            const SizedBox(height: SizeConstants.spaceBeforeAndAfterField),
            const Divider(),
            const SizedBox(height: SizeConstants.spaceBeforeAndAfterField),
            SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Company Name: Tejas Tech Pvt Ltd',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Email: tejas.teck5@gmail.com'),
                  Text('Address: Mumbai, India'),
                  Text('Support Timing: 9 AM to 6 PM IST'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
