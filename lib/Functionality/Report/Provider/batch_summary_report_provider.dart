//batch_summary_report_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventorytracker/Functionality/Stock/Parameters/stock_params.dart';
import 'package:inventorytracker/Functionality/Stock/Provider/stock_provider.dart';
import 'package:inventorytracker/Functionality/Stock/Model/batch_model.dart';
import '../Parameter/report_parameter.dart';



final batchDetailsReportDataProvider = FutureProvider.family<List<BatchModel>, BatchDetailsReportParams>((ref, params) async {

  final service = await ref.read(stockServiceProvider.future);

  // First, get the stockId for the given productId and warehouseId
  final stockId = await service.getStockIdForProduct(
    params.warehouseId,
    params.productId,
  );

  if (stockId == null) {
    return []; // No stock found for this product in this warehouse
  }


  final stockBatchesQuery = StockBatchesQuery(
  warehouseId: params.warehouseId,
  stockId: stockId,
  );

  try {
    final batches = await ref.watch(stockBatchesProvider(stockBatchesQuery).future);
    return batches; // ✅ must return inside try
  } catch (e) {
    return []; // ✅ ensures no hanging
  }
});



