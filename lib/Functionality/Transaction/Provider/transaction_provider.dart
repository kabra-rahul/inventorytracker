//transaction_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventorytracker/Functionality/Hsn/Provider/hsn_provider.dart';
import 'package:inventorytracker/Functionality/Product/Model/product_model.dart';
import 'package:inventorytracker/Functionality/Product/Provider/product_provider.dart';
import 'package:inventorytracker/Functionality/Report/Model/transaction_model.dart';
import 'package:inventorytracker/Functionality/Report/Parameter/report_parameter.dart';
import 'package:inventorytracker/Functionality/StockMovement/Model/stock_movement_model.dart';
import 'package:inventorytracker/Functionality/Units/Provider/unit_provider.dart';
import 'package:inventorytracker/Functionality/Warehouse/Provider/warehouse_provider.dart';
import 'package:inventorytracker/Provider/app_store_provider.dart';
import 'package:equatable/equatable.dart';
import '../Service/transaction_service.dart';



class MovementQueryParams extends Equatable {
  final String warehouseId;
  final String type;

  const MovementQueryParams({
    required this.warehouseId,
    required this.type,
  });

  @override
  List<Object?> get props => [warehouseId, type];
}


final transactionServiceProvider = FutureProvider<TransactionService>((ref) async {
  final appStore = await ref.watch(appStoreProvider.future);

  if (appStore == null || appStore.companyId.isEmpty) {
    throw Exception('Company ID is empty');
  }
  return TransactionService(companyId: appStore.companyId, userId: appStore.uid); // Changed: Returned the instance
});



final recentMovementsProvider = FutureProvider.family<Map<String, dynamic>, MovementQueryParams>((ref, args) async {
  final service = await ref.watch(transactionServiceProvider.future);
  return service.getRecentMovements(
    warehouseId: args.warehouseId,
    type       : args.type,
  );
});




final supplierSellReportDataProvider = FutureProvider.family<List<StockMovementReportModel>, SupplierSellReportParams>((ref, params) async {
  final service = await ref.watch(transactionServiceProvider.future);

  final List<StockMovementModel> rawTransactions = await service.getSupplierSellTransactions(
    supplierId: params.supplierId,
    fromDate: params.fromDate,
    toDate: params.toDate,
  );

  if (rawTransactions.isEmpty) return [];

  final Future<Map<String, String>> warehouseNamesFuture = ref.watch(allWarehousesMapProvider.future);
  final Future<Map<String, dynamic>> productsFuture = ref.watch(allProductsMapProvider.future);
  final Future<Map<String, String>> hsnCodesFuture = ref.watch(allHsnsMapProvider.future);
  final Future<Map<String, String>> unitNamesFuture = ref.watch(allUnitsMapProvider.future);

  final results = await Future.wait([
    warehouseNamesFuture,
    productsFuture,
    hsnCodesFuture,
    unitNamesFuture
  ]);

  final warehouseNamesMap = results[0];
  final Map<String, dynamic> productMapRaw = results[1];
  final Map<String, Product> productMap = productMapRaw.map((key, value) => MapEntry(key, value as Product));
  final hsnCodesMap = results[2];
  final unitNamesMap = results[3];

  return rawTransactions.map((raw) {
    Product? product = productMap[raw.productId];
    final productName = product?.name ?? 'Unknown Product';
    final hsnCode = hsnCodesMap[product?.hsnId ?? ''] ?? 'N/A';
    final unitName = unitNamesMap[product?.unitId ?? ''] ?? 'N/A';
    final warehouseName = warehouseNamesMap[raw.warehouseId] ?? 'Unknown Warehouse';

    return StockMovementReportModel.fromMap(
      raw,
      warehouseName: warehouseName,
      productName: productName,
      hsnCode: hsnCode,
      unit: unitName,
      clientName: '',
      supplierName: '',
      userName: ''
    );
  }).toList();
});


final clientBuyReportDataProvider = FutureProvider.family<List<StockMovementReportModel>, ClientSellReportParams>((ref, params) async {
  final service = await ref.watch(transactionServiceProvider.future);

  final List<StockMovementModel> rawTransactions = await service.getClientBuyTransactions(
    clientId: params.clientId,
    fromDate: params.fromDate,
    toDate: params.toDate,
  );

  if (rawTransactions.isEmpty) return [];

  final Future<Map<String, String>> warehouseNamesFuture = ref.watch(allWarehousesMapProvider.future);
  final Future<Map<String, dynamic>> productsFuture = ref.watch(allProductsMapProvider.future);
  final Future<Map<String, String>> hsnCodesFuture = ref.watch(allHsnsMapProvider.future);
  final Future<Map<String, String>> unitNamesFuture = ref.watch(allUnitsMapProvider.future);

  final results = await Future.wait([
    warehouseNamesFuture,
    productsFuture,
    hsnCodesFuture,
    unitNamesFuture
  ]);

  final warehouseNamesMap = results[0];
  final Map<String, dynamic> productMapRaw = results[1];
  final Map<String, Product> productMap = productMapRaw.map((key, value) => MapEntry(key, value as Product));
  final hsnCodesMap = results[2];
  final unitNamesMap = results[3];

  return rawTransactions.map((raw) {
    Product? product = productMap[raw.productId];
    final productName = product?.name ?? 'Unknown Product';
    final hsnCode = hsnCodesMap[product?.hsnId ?? ''] ?? 'N/A';
    final unitName = unitNamesMap[product?.unitId ?? ''] ?? 'N/A';
    final warehouseName = warehouseNamesMap[raw.warehouseId] ?? 'Unknown Warehouse';

    return StockMovementReportModel.fromMap(
      raw,
      warehouseName: warehouseName,
      productName: productName,
      hsnCode: hsnCode,
      unit: unitName,
      clientName: '',
      supplierName: '',
      userName: ''
    );
  }).toList();
});