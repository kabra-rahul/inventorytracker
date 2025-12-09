// common_dropdown_field.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventorytracker/Model/dropdown_item_model.dart'; // Adjust this import path as needed

class CustomDropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final String hint;
  final void Function(String?) onChanged;
  // Using DropdownItem for type safety, as inferred from e.id and e.name
  final AsyncValue<List<DropdownItem>> items;

  const CustomDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.hint,
    required this.onChanged,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: items.when(
            data: (dataList) {
              return DropdownButtonFormField<String>(
                value: value,
                isExpanded: true,
                decoration: const InputDecoration(border: InputBorder.none),
                hint: Text(hint),
                items: dataList
                    .map((e) => DropdownMenuItem<String>(
                    value: e.id,
                    child: Text(e.name))) // Assumes DropdownItem has 'id' and 'name'
                    .toList(),
                onChanged: onChanged,
                menuMaxHeight: 300,
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (err, stack) => Text("Error: $err"), // Added stack trace for debugging
          ),
        ),
      ],
    );
  }
}