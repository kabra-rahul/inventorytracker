// batch_details_report_page.dart
import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventorytracker/Model/dropdown_item_model.dart';
import 'package:inventorytracker/Functionality/Product/Model/product_model.dart';
import 'package:inventorytracker/Functionality/Product/Provider/product_provider.dart';
import 'package:inventorytracker/Functionality/Report/Provider/batch_summary_report_provider.dart';
import 'package:inventorytracker/Functionality/Report/Provider/report_provider.dart';
import 'package:inventorytracker/Functionality/Warehouse/Model/warehouse_model.dart';
import 'package:inventorytracker/Functionality/Warehouse/Provider/warehouse_provider.dart';
import 'package:inventorytracker/Shared/Constants/snackbar_color.dart';
import 'package:inventorytracker/Shared/Util/excel_style.dart';
import 'package:inventorytracker/Shared/Widgets/custom_dropdown_field.dart';
import 'package:inventorytracker/Shared/Widgets/custom_text_field.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';



class BatchDetailsReportPage extends ConsumerStatefulWidget {
  const BatchDetailsReportPage({super.key});

  @override
  ConsumerState<BatchDetailsReportPage> createState() => _BatchDetailsReportPageState();
}

class _BatchDetailsReportPageState extends ConsumerState<BatchDetailsReportPage> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final selectedWarehouseItem = ref.watch(selectedWarehouseItemProvider);
    final productController = ref.watch(productReportControllerProvider);
    final selectedProduct = ref.watch(selectedProductForReportProvider);
    final isGenerating = ref.watch(isGeneratingReportProvider);
    final generatedFilePath = ref.watch(generatedReportFilePathProvider);

    final warehouseListAsync = ref.watch(warehouseListProvider);
    final productListAsync = ref.watch(productListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Details Report'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(selectedWarehouseItemProvider.notifier).state = null;
            context.pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Options',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              // Warehouse Dropdown (Required)
              CustomDropdownField(
                label: 'Warehouse',
                hint: 'Select Warehouse',
                value: selectedWarehouseItem?.id,
                onChanged: (newValue) {
                  if (newValue == null) {
                    ref.read(selectedWarehouseItemProvider.notifier).state = null;
                    return;
                  }
                  final selectedWarehouse = warehouseListAsync.value?.firstWhere(
                        (w) => w.id == newValue,
                    orElse: () => Warehouse(id: '', name: 'Unknown Warehouse', location: '', active: true), // Prevents StateError
                  );
                  final DropdownItem? selectedItem;
                  if (selectedWarehouse != null && selectedWarehouse.id.isNotEmpty) {
                    selectedItem = DropdownItem(id: selectedWarehouse.id, name: selectedWarehouse.name);
                  } else {
                    selectedItem = null;
                  }
                  ref.read(selectedWarehouseItemProvider.notifier).state = selectedItem;
                },

                items: warehouseListAsync.when(
                  data: (warehouses) => AsyncValue.data(warehouses.map((w) => DropdownItem(id: w.id, name: w.name)).toList()),
                  loading: () => const AsyncValue.loading(),
                  error: (err, stack) => AsyncValue.error(err, stack),
                ),
              ),

              const SizedBox(height: 16),

              // Product Autocomplete (Required)
              Autocomplete<Product>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<Product>.empty();
                  }
                  return productListAsync.when(
                    data: (products) => products.where((p) => p.name.toLowerCase().contains(textEditingValue.text.toLowerCase())),
                    loading: () => const Iterable<Product>.empty(),
                    error: (err, stack) => const Iterable<Product>.empty(),
                  );
                },
                displayStringForOption: (Product p) => p.name,
                onSelected: (Product p) {
                  productController.text = p.name;
                  ref.read(selectedProductForReportProvider.notifier).state = p;
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  productController.text = controller.text;
                  return CustomTextField(
                    label: 'Product', // Required
                    hintText: 'Enter product name',
                    controller: controller,
                    focusNode: focusNode,
                    onFieldSubmitted: onFieldSubmitted,
                    validator: (value) {
                      if (value == null || value.isEmpty || selectedProduct == null) {
                        return 'Product is required';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 30),

              // Generate Report Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isGenerating
                      ? null
                      : () async {
                    if (_formKey.currentState!.validate()) {
                      // Validate required fields
                      if (selectedWarehouseItem == null || selectedWarehouseItem.id.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please select a Warehouse.'),backgroundColor: SnackBarColor.errorMessage)
                        );
                        return;
                      }
                      if (selectedProduct == null || selectedProduct.id.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please select a Product.'), backgroundColor: SnackBarColor.errorMessage),
                        );
                        return;
                      }

                      ref.read(isGeneratingReportProvider.notifier).state = true;
                      ref.read(generatedReportFilePathProvider.notifier).state = null;

                      try {
                        final filePath = await _generateExcelReport(
                          ref,
                          selectedWarehouseItem.id, // Pass ID
                          selectedProduct.id, // Pass ID
                          selectedWarehouseItem.name, // Pass name
                          selectedProduct.name, // Pass name
                        );
                        ref.read(generatedReportFilePathProvider.notifier).state = filePath;
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(content: Text('Error generating report: $e'),backgroundColor: SnackBarColor.errorMessage),
                        );
                      } finally {
                        ref.read(isGeneratingReportProvider.notifier).state = false;
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: isGenerating ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ) : const Icon(Icons.analytics_outlined),
                  label: Text(isGenerating ? 'Generating Report...' : 'Generate Report'),
                ),
              ),
              const SizedBox(height: 30),

              // Generated Report Section
              if (generatedFilePath != null) ...[
                const Text(
                  'Generated Report',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file, color: Colors.green, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          generatedFilePath.split('/').last,
                          style: const TextStyle(fontSize: 16, color: Colors.green),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.download, color: Colors.blue),
                        onPressed: () {
                          _downloadReport(context, generatedFilePath);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<String> _generateExcelReport(
      WidgetRef ref,
      String warehouseId,
      String productId,
      String warehouseName,
      String productName,
      ) async {
    ref.read(isGeneratingReportProvider.notifier).state = true;

    // FIX: Use record literal syntax for params
    final params = (warehouseId: warehouseId, productId: productId );
    final reportData = await ref.read(batchDetailsReportDataProvider(params).future);

    final excel = Excel.createExcel();
    Sheet sheet = excel['Batch Details Report'];
    excel.delete('Sheet1');

    final headers = [
      'Warehouse',
      'Product',
      'Supplier',
      'Lot No.',
      'Quantity',
      'Price Per Unit',
      'Purchase Date',
    ];

    final int headerRowIndex = sheet.maxRows;
    sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());
    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRowIndex));
      cell.cellStyle = kReportHeaderStyle;
      sheet.setColumnAutoFit(col);
    }

    double totalQuantity = 0.0;

    for (final batch in reportData) {

      sheet.appendRow([
        TextCellValue(warehouseName),
        TextCellValue(productName),
        TextCellValue(batch.supplierName),
        TextCellValue(batch.batchNumber),
        DoubleCellValue(batch.quantity),
        DoubleCellValue(batch.pricePerUnit),
        TextCellValue(DateFormat('dd MMM yyyy hh:mm a').format(batch.purchaseDate)),
      ]);
      for (int col = 0; col < headers.length; col++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: sheet.maxRows-1));
        cell.cellStyle = kReportDataStyle;
      }
      totalQuantity += batch.quantity;
    }

    // Add the total row. Place the label in the "Lot No." column (index 3)
    // and the value in the "Quantity" column (index 4).
    sheet.appendRow([
      TextCellValue(''), // 0: Warehouse
      TextCellValue(''), // 1: Product
      TextCellValue(''), // 2: Supplier
      TextCellValue('TOTAL QUANTITY:'), // 3: Lot No. (Label)
      DoubleCellValue(totalQuantity),  // 4: Quantity (Value)
      TextCellValue(''), // 5: Price Per Unit
      TextCellValue(''), // 6: Purchase Date
    ]);

    // Apply bold style to the total row cells
    final totalRowIndex = sheet.maxRows - 1;

    // Apply style to the Label cell (Index 3)
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: totalRowIndex)).cellStyle = kReportTotalStyle;
    // Apply style to the Value cell (Index 4)
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: totalRowIndex)).cellStyle = kReportTotalStyle;

    List<int>? fileBytes = excel.save();
    if (fileBytes == null) {
      throw Exception('Failed to generate Excel file bytes.');
    }

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'Batch_Details_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final filePath = '${dir.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(fileBytes);
    ref.read(isGeneratingReportProvider.notifier).state = false;
    return filePath;
  }



  void _downloadReport(BuildContext context, String filePath) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening file: ${filePath.split('/').last}'),backgroundColor: SnackBarColor.successMessage),
    );
    try {
      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        if (!mounted) return;
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(content: Text('Failed to open file: ${result.message}'),backgroundColor: SnackBarColor.errorMessage),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text('Error opening file: $e'),backgroundColor: SnackBarColor.errorMessage),
      );
    }
  }
}