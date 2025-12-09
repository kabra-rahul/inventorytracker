// custom_text_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatter

/// A custom text input field widget with a label, hint, and validation.
class CustomTextField extends StatelessWidget {

  const CustomTextField({
    super.key,
    this.label,
    required this.controller,
    this.hintText,
    this.isPassword = false,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
    this.inputFormatters,
    this.onFieldSubmitted,
    this.textInputAction,
    this.maxLines = 1,
    this.focusNode,
    this.onChanged
  });

  final String? label;
  final TextEditingController controller;
  final String? hintText;
  final bool isPassword;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final VoidCallback? onFieldSubmitted;
  final TextInputAction? textInputAction;
  final int maxLines;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label != null && label!.isNotEmpty && label != ''
            ? Text(label!, style: const TextStyle(fontWeight: FontWeight.w500))
            : const SizedBox.shrink(),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: isPassword,
            readOnly: readOnly,
            onTap: onTap,
            inputFormatters: inputFormatters,
            onFieldSubmitted: (text) => onFieldSubmitted?.call(),
            textInputAction: textInputAction,
            maxLines: maxLines,
            focusNode: focusNode,
            decoration: InputDecoration(
              hintText: hintText,
              border: InputBorder.none,
              suffixIcon: suffixIcon,
            ),
            validator: validator,
            onChanged: onChanged  ,
          ),
        ),
      ],
    );
  }
}