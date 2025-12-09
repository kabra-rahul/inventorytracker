import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:inventorytracker/Functionality/Supplier/Model/supplier_model.dart';


final selectedSupplierForSellReportProvider = StateProvider<Supplier?>((ref) => null);

final sellReportFromDateProvider = StateProvider.autoDispose<DateTime?>((ref) => null);

final sellReportToDateProvider = StateProvider.autoDispose<DateTime?>((ref) => null);

final supplierSellReportControllerProvider = Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});


