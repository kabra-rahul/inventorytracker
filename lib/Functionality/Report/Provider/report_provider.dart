import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:inventorytracker/Model/dropdown_item_model.dart';
import 'package:inventorytracker/Functionality/Product/Model/product_model.dart';



// State for the path/URL of the generated report file
final generatedReportFilePathProvider = StateProvider.autoDispose<String?>((ref) => null);

// State for loading indicator during report generation
final isGeneratingReportProvider = StateProvider.autoDispose<bool>((ref) => false);

// State for selected Warehouse ID
final selectedWarehouseItemProvider = StateProvider<DropdownItem?>((ref) => null);

// State for selected Product (from Autocomplete)
final selectedProductForReportProvider = StateProvider<Product?>((ref) => null);


// State for Product Autocomplete Text Controller
final productReportControllerProvider = Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

