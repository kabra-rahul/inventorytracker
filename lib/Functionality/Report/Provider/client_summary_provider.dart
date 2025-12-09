import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:inventorytracker/Functionality/Client/Model/client_model.dart';


final selectedClientForBuyReportProvider = StateProvider<Client?>((ref) => null);

final buyReportFromDateProvider = StateProvider.autoDispose<DateTime?>((ref) => null);

final buyReportToDateProvider = StateProvider.autoDispose<DateTime?>((ref) => null);

final clientBuyReportControllerProvider = Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});


