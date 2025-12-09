//stock_details_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:inventorytracker/Shared/Constants/size_constants.dart';
import '../Parameters/stock_params.dart';
import '../Provider/stock_provider.dart';
import '../Model/stock_model.dart';

class StockDetailsPage extends ConsumerWidget {
  final Map<String, dynamic> extra;

  const StockDetailsPage({super.key, required this.extra});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final warehouseId = extra['warehouseId'];
    final StockModel product = extra['product'];

    // Watch the combined batch data with supplier names
/*final batchProvider = ref.watch(
      stockBatchesProvider(
        StockBatchesQuery(
          warehouseId: warehouseId,
          stockId: product.stockId,
        ),
      ),
    );
*/
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        // Use pageFormPadding for overall padding as in the original code
        padding: const EdgeInsets.all(SizeConstants.pageFormPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch cards to full width
          children: [
            _buildProductDetailsCard(context, product),
            const SizedBox(height: 20),
            _buildBatchDetailsCard(context, ref, warehouseId, product),
            const SizedBox(height: 20),
            _buildTotalQuantityCard(context, product),
          ],
        ),
      ),
    );
  }

  // --- 1. Product Details Card ---
  Widget _buildProductDetailsCard(BuildContext context, StockModel product) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Icon
            Row(
              children: [
                const Icon(Icons.info_outline, size: 20, color: Colors.black54),
                const SizedBox(width: 8),
                Text(
                  'Product Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 0.5),

            // Details Rows
            _buildDetailRow('Category', product.category),
            _buildDetailRow('HSN Code', product.hsn),
            _buildDetailRow('Unit', product.unit),
          ],
        ),
      ),
    );
  }

  // Helper widget to build consistent detail rows (Key-Value)
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label, // Label on the left
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 16,
            ),
          ),
          Text(
            value, // Value on the right
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Batch Details Card (with Scrollable Table) ---
  Widget _buildBatchDetailsCard(
      BuildContext context, WidgetRef ref, String warehouseId, StockModel product) {
    final batchProvider = ref.watch(
      stockBatchesProvider(
        StockBatchesQuery(
          warehouseId: warehouseId,
          stockId: product.stockId,
        ),
      ),
    );

    //const double maxBodyHeight = 250.0;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header and Button Row
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Batch Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Batch Data Handling
          batchProvider.when(
            data: (batches) {
              final nonEmptyBatches = batches.where((b) => b.quantity > 0).toList();
              if (nonEmptyBatches.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: Center(child: Text('No batches with available stock.')),
                );
              }

              final ScrollController horizontalScrollController = ScrollController();

              // Custom scrollable table implementation
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Scrollbar(
                      controller: horizontalScrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        controller: horizontalScrollController,
                        child: SizedBox(
                          width: 650.0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Table Header Row
                              _buildBatchRow(
                                context,
                                supplier: 'Supplier',
                                lotNo: 'Lot No.',
                                quantity: 'Qty',
                                rate: 'Rate',
                                purchaseDate: 'Purchase Date', // Abbreviated for space
                                isHeader: true,
                              ),

                              // Data Rows
                              ...nonEmptyBatches.map((batch) {
                                final quantityText = '${batch.quantity.toString()} ${product.unit}';
                                final pricePerUnit = batch.pricePerUnit;
                                final rateText = '₹${pricePerUnit.toStringAsFixed(2)}';
                                // Assuming purchaseDate is a DateTime or similar object that can be converted to a simple date string
                                String dateText;
                                try {
                                  // Assuming batch.purchaseDate is a DateTime object
                                    dateText = DateFormat('dd MMM yyyy hh:mm a').format(batch.purchaseDate);
                                } catch (e) {
                                  // Fallback if the object is not a DateTime or format fails
                                  dateText = 'N/A';
                                }

                                return _buildBatchRow(
                                  context,
                                  supplier: batch.supplierName,
                                  lotNo: batch.batchNumber,
                                  quantity: quantityText,
                                  rate: rateText,
                                  purchaseDate: dateText,
                                  isHeader: false,
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Scroll Hint
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.swipe_left, size: 16, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          'Scroll horizontally to view all batch data',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Center(child: Text('Failed to load batches: $err')),
            ),
          ),
        ],
      ),
    );
  }

  // Helper for the dynamic table rows (header vs. data)
  Widget _buildBatchRow(
      BuildContext context, {
        required String supplier,
        required String lotNo,
        required String quantity,
        required String rate, // New parameter
        required String purchaseDate, // New parameter
        required bool isHeader,
      }) {
    // Define fixed widths for all 5 columns
    const double supplierColWidth = 180.0;
    const double lotNoColWidth = 100.0;
    const double qtyColWidth = 120.0;
    const double rateColWidth = 100.0; // Fixed width for Rate
    const double dateColWidth = 150.0; // Fixed width for Purchase Date

    // Styling based on row type
    final bgColor = isHeader ? Colors.blue.shade50 : Colors.white;
    final textStyle = isHeader
        ? Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: Colors.blue.shade800,
    )
        : Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.normal,
    );

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(
            color: isHeader ? Colors.blue.shade200 : Colors.grey.shade200,
            width: isHeader ? 2 : 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTableCell(context, supplier, textStyle, supplierColWidth),
          _buildTableCell(context, lotNo, textStyle, lotNoColWidth),
          _buildTableCell(context, quantity, textStyle, qtyColWidth),
          _buildTableCell(context, rate, textStyle, rateColWidth), // Rate Column
          _buildTableCell(context, purchaseDate, textStyle, dateColWidth), // Purchase Date Column
        ],
      ),
    );
  }

  // Helper for individual table cells
  Widget _buildTableCell(
      BuildContext context,
      String text,
      TextStyle? style,
      double width,
      ) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Text(
        text,
        style: style,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
    );
  }

  // --- 3. Total Quantity Card ---
  Widget _buildTotalQuantityCard(BuildContext context, StockModel product) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Quantity',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'All batches combined',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Text(
              '${product.totalQuantity.toString()} ${product.unit}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}