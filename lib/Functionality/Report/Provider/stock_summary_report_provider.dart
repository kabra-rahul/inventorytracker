
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:inventorytracker/Functionality/Category/Model/category_model.dart';



// State for "Show Only Low Stock" toggle
final showLowStockProvider = StateProvider<bool>((ref) => false);


// State for selected Category (from Autocomplete)
final selectedCategoryForReportProvider = StateProvider<Category?>((ref) => null);


// State for Category Autocomplete Text Controller
final categoryReportControllerProvider = Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

