//stock_form_common_widget.dart
import 'package:flutter/material.dart';

class LabeledTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType inputType;
  final bool isMandatory;

  const LabeledTextField({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.inputType = TextInputType.text,
    this.isMandatory = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        decoration: InputDecoration(
          labelText: isMandatory ? "$label *" : label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
