// lib/Shared/Widgets/confirmation_input_dialog.dart
import 'package:flutter/material.dart';

/// A dialog that asks for confirmation and allows text input.
/// Returns the entered text if confirmed, or null if cancelled.
Future<String?> showConfirmationInputDialog(
    BuildContext context, {
      required String title,
      required String content,
      String confirmButtonText = 'Confirm',
      String cancelButtonText = 'Cancel',
      String inputHintText = 'Reason for undo (required)',
      String? initialText,
    }) async {
  final TextEditingController textController = TextEditingController(text: initialText);
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  return showDialog<String?>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(content),
                const SizedBox(height: 16),
                TextFormField(
                  controller: textController,
                  decoration: InputDecoration(
                    hintText: inputHintText,
                    border: const OutlineInputBorder(),
                    labelText: inputHintText,
                  ),
                  maxLines: 3,
                  minLines: 1,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Reason cannot be empty';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)
        ),
        actions: <Widget>[
          TextButton(
            child: Text(cancelButtonText),
            onPressed: () {
              Navigator.of(dialogContext).pop(null); // Return null on cancel
            },
          ),
          ElevatedButton(
            child: Text(confirmButtonText),
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(dialogContext).pop(textController.text.trim()); // Return entered text
              }
            },
          ),
        ],
      );
    },
  );
}