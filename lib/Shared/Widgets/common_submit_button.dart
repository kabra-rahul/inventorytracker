// custom_elevated_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventorytracker/Provider/connectivity_provider.dart';

import '../Constants/snackbar_color.dart';

/// A custom full-width elevated button with a predefined style.
class CustomElevatedButton extends ConsumerWidget {
  const CustomElevatedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = Colors.blue, // Default blue
    this.textColor = Colors.white,     // Default white
    this.fontSize = 16,                // Default font size
    this.verticalPadding = 16,         // Default vertical padding
    this.borderRadius = 12,            // Default border radius
    this.minimumHeight = 50,           // Default minimum height
  });

  final String text;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;
  final double verticalPadding;
  final double borderRadius;
  final double minimumHeight;


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(isConnectedProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity, // Makes the button take full available width
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton(
            onPressed: () {
              if (isConnected) {
                onPressed?.call();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("No internet connection"), backgroundColor: SnackBarColor.errorMessage),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              padding: EdgeInsets.symmetric(vertical: verticalPadding),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              minimumSize: Size.fromHeight(minimumHeight), // Ensures a consistent height
            ),
            child: Text(
              text, // Use the provided text for the button label
              style: TextStyle(fontSize: fontSize, color: textColor),
            ),
          ),
        ),
      ),
    );
  }
}