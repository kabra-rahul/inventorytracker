// lib/common_widgets/confirmation_dialog.dart
import 'package:flutter/material.dart';

/// Shows a generic confirmation dialog.
Future<bool?> showConfirmationDialog(
    BuildContext context, {
      required String title,
      required String content,
      String confirmButtonText = 'Confirm',
      String cancelButtonText = 'Cancel',
    }) async {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // User chose not to confirm
            child: Text(cancelButtonText),

          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true), // User confirmed
            child: Text(confirmButtonText),
          ),
        ],
      );
    },
  );
}