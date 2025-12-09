import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:inventorytracker/Functionality/Client/Provider/client_provider.dart';
import 'package:inventorytracker/Functionality/Hsn/Provider/hsn_provider.dart';
import 'package:inventorytracker/Functionality/Product/Model/product_model.dart';
import 'package:inventorytracker/Functionality/Product/Provider/product_provider.dart';
import 'package:inventorytracker/Functionality/Report/Model/undone_transaction_model.dart';
import 'package:inventorytracker/Functionality/StockMovement/Model/stock_movement_model.dart';
import 'package:inventorytracker/Functionality/Supplier/Provider/supplier_provider.dart';
import 'package:inventorytracker/Functionality/Transaction/Provider/transaction_provider.dart';
import 'package:inventorytracker/Functionality/Units/Provider/unit_provider.dart';
import 'package:inventorytracker/Functionality/User/Model/app_user_model.dart';
import 'package:inventorytracker/Functionality/User/Provider/user_provider.dart';
import 'package:inventorytracker/Functionality/Warehouse/Provider/warehouse_provider.dart';
import '../../../Provider/app_store_provider.dart';
import '../Parameter/report_parameter.dart';



final undoTransactionReportFromDateProvider = StateProvider.autoDispose<DateTime?>((ref) => null);


final undoTransactionReportToDateProvider = StateProvider.autoDispose<DateTime?>((ref) => null);


final undoTransactionReportUserSearchControllerProvider = Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});


final selectedUserForUndoTransactionReportProvider = StateProvider<AppUser?>((ref) => null);



final undoTransactionReportDataProvider = FutureProvider.family<List<StockMovementUndoReportModel>, UndoneTransactionReportParams>((ref, params) async {
  final appStore = await ref.watch(appStoreProvider.future);
  if (appStore == null || appStore.companyId.isEmpty) return [];

  final service = await ref.read(transactionServiceProvider.future);

  final List<StockMovementModel> rawTransactions = await service.getUndoTransactions(
    fromDate: params.fromDate,
    toDate: params.toDate,
    userId: params.undoneByUserId,
  );

  if (rawTransactions.isEmpty) return [];

  // Fetch all necessary lookup maps in parallel
  final Future<Map<String, String>> warehouseNamesFuture = ref.watch(allWarehousesMapProvider.future);
  final Future<Map<String, dynamic>> productsFuture = ref.watch(allProductsMapProvider.future);
  final Future<Map<String, String>> hsnCodesFuture = ref.watch(allHsnsMapProvider.future);
  final Future<Map<String, String>> unitNamesFuture = ref.watch(allUnitsMapProvider.future);
  final Future<Map<String, String>> supplierNamesFuture = ref.watch(allSuppliersMapProvider.future);
  final Future<Map<String, String>> clientNamesFuture = ref.watch(allClientsMapProvider.future);
  final Future<Map<String, String>> userNamesFuture = ref.watch(allUsersMapProvider.future);


  final results = await Future.wait([
    warehouseNamesFuture,
    productsFuture,
    hsnCodesFuture,
    unitNamesFuture,
    supplierNamesFuture,
    clientNamesFuture,
    userNamesFuture
  ]);

  final Map<String, String> warehouseNamesMap = results[0] as Map<String, String>;
  final Map<String, dynamic> productMapRaw = results[1];
  final Map<String, Product> productMap = productMapRaw.map((key, value) => MapEntry(key, value as Product));
  final Map<String, String> hsnCodesMap = results[2] as Map<String, String>;
  final Map<String, String> unitNamesMap = results[3] as Map<String, String>;
  final Map<String, String> supplierNamesMap = results[4] as Map<String, String>;
  final Map<String, String> clientNamesMap = results[5] as Map<String, String>;
  final Map<String, String> userNamesMap = results[6] as Map<String, String>;


  return rawTransactions.map((raw) {
    Product? product = productMap[raw.productId];
    final productName = product?.name ?? 'Unknown Product';
    final hsnCode = hsnCodesMap[product?.hsnId ?? ''] ?? 'N/A';
    final unitName = unitNamesMap[product?.unitId ?? ''] ?? 'N/A';
    final warehouseName = warehouseNamesMap[raw.warehouseId] ?? 'Unknown Warehouse';
    final supplierName = raw.supplierId != '' ? (supplierNamesMap[raw.supplierId] ?? 'N/A') : 'N/A';
    final clientName = raw.clientId != '' ? (clientNamesMap[raw.clientId] ?? 'N/A') : 'N/A';
    final userName = raw.performedBy != '' ? (userNamesMap[raw.performedBy] ?? 'N/A') : 'N/A';
    final undoUserName = raw.undoneByUserId != '' ? (userNamesMap[raw.undoneByUserId] ?? 'N/A') : 'N/A';

    return StockMovementUndoReportModel.fromMap(
      raw,
      warehouseName: warehouseName,
      productName: productName,
      hsnCode: hsnCode,
      unit: unitName,
      supplierName: supplierName, // Pass to report model
      clientName: clientName,     // Pass to report model
      userName: userName,
      undoUserName: undoUserName,
    );
  }).toList();
});