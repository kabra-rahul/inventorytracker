// stock_summary_report_page.dart
import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventorytracker/Functionality/Category/Provider/category_provider.dart';
import 'package:inventorytracker/Model/dropdown_item_model.dart';
import 'package:inventorytracker/Functionality/Product/Model/product_model.dart';
import 'package:inventorytracker/Functionality/Category/Model/category_model.dart';
import 'package:inventorytracker/Functionality/Product/Provider/product_provider.dart';
import 'package:inventorytracker/Functionality/Report/Provider/report_provider.dart';
import 'package:inventorytracker/Functionality/Report/Provider/stock_summary_report_provider.dart';
import 'package:inventorytracker/Functionality/Stock/Parameters/stock_params.dart';
import 'package:inventorytracker/Functionality/Warehouse/Provider/warehouse_provider.dart';
import 'package:inventorytracker/Shared/Constants/snackbar_color.dart';
import 'package:inventorytracker/Shared/Util/excel_style.dart';
import 'package:inventorytracker/Shared/Widgets/custom_dropdown_field.dart';
import 'package:inventorytracker/Shared/Widgets/custom_text_field.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../Stock/Provider/stock_provider.dart';
import '../../Warehouse/Model/warehouse_model.dart'; // Your CustomTextField



class StockSummaryReportPage extends ConsumerStatefulWidget {
  const StockSummaryReportPage({super.key});

  @override
  ConsumerState<StockSummaryReportPage> createState() => _StockSummaryReportPageState();
}


class _StockSummaryReportPageState extends ConsumerState<StockSummaryReportPage> {
  final _formKey = GlobalKey<FormState>();


  @override
  Widget build(BuildContext context) {
    // Watch filter states
    final selectedWarehouseItem = ref.watch(selectedWarehouseItemProvider);
    final productController = ref.watch(productReportControllerProvider);
    final selectedProduct = ref.watch(selectedProductForReportProvider);
    final categoryController = ref.watch(categoryReportControllerProvider);
    final selectedCategory = ref.watch(selectedCategoryForReportProvider);
    final showLowStock = ref.watch(showLowStockProvider);

    final generatedFilePath = ref.watch(generatedReportFilePathProvider);
    final isGenerating = ref.watch(isGeneratingReportProvider);

    // Watch data for dropdowns and autocompletes
    final warehouseListAsync = ref.watch(warehouseListProvider);
    final productListAsync = ref.watch(productListProvider);
    final categoryListAsync = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Current Stock Report'),
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

              // Warehouse Dropdown
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

              // Product Autocomplete
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
                  // Sync internal controller with Autocomplete's controller
                  productController.text = controller.text;
                  return CustomTextField(
                    label: 'Product (Optional)',
                    hintText: 'Enter product name',
                    controller: controller,
                    focusNode: focusNode,
                    onFieldSubmitted: onFieldSubmitted,
                    onChanged: (text) {
                        // FIX: If the text is cleared manually, reset the product state
                        if (text.isEmpty && ref.read(selectedProductForReportProvider) != null) {
                          ref.read(selectedProductForReportProvider.notifier).state = null;
                          // Also clear the separate productController if needed,
                          // though Autocomplete's controller handles the input field text.
                          productController.clear();
                        }
                      }
                  );
                },
              ),
              const SizedBox(height: 16),

              // Category Autocomplete
              Autocomplete<Category>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<Category>.empty();
                  }
                  return categoryListAsync.when(
                    data: (categories) => categories.where((c) => c.name.toLowerCase().contains(textEditingValue.text.toLowerCase())),
                    loading: () => const Iterable<Category>.empty(),
                    error: (err, stack) => const Iterable<Category>.empty(),
                  );
                },
                displayStringForOption: (Category c) => c.name,
                onSelected: (Category c) {
                  categoryController.text = c.name;
                  ref.read(selectedCategoryForReportProvider.notifier).state = c;
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  // Sync internal controller with Autocomplete's controller
                  categoryController.text = controller.text;
                  return CustomTextField(
                    label: 'Category (Optional)',
                    hintText: 'Enter category',
                    controller: controller,
                    focusNode: focusNode,
                    onFieldSubmitted: onFieldSubmitted,
                    onChanged: (text) {
                        // FIX: If the text is cleared manually, reset the product state
                        if (text.isEmpty && ref.read(selectedCategoryForReportProvider) != null) {
                          ref.read(selectedCategoryForReportProvider.notifier).state = null;
                          // Also clear the separate productController if needed,
                          // though Autocomplete's controller handles the input field text.
                          categoryController.clear();
                        }
                    }
                  );
                },
              ),
              const SizedBox(height: 20),

              // Show Only Low Stock Toggle
              const Text(
                'Show Only Low Stock',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => ref.read(showLowStockProvider.notifier).state = true,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: showLowStock ? Colors.blue : Colors.grey[200],
                        foregroundColor: showLowStock ? Colors.white : Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Yes'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => ref.read(showLowStockProvider.notifier).state = false,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !showLowStock ? Colors.blue : Colors.grey[200],
                        foregroundColor: !showLowStock ? Colors.white : Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('No'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Generate Report Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isGenerating
                      ? null
                      : () async {
                    if (_formKey.currentState!.validate()) {
                      // Validate dropdown
                      if (selectedWarehouseItem == null || selectedWarehouseItem.id == '' || selectedWarehouseItem.id.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please select a Warehouse.'), backgroundColor: SnackBarColor.errorMessage),
                        );
                        return;
                      }

                      ref.read(isGeneratingReportProvider.notifier).state = true;
                      ref.read(generatedReportFilePathProvider.notifier).state = null; // Clear previous

                      try {
                        // Simulate report generation
                        final filePath = await _generateExcelReport(
                          ref,
                          selectedWarehouseItem,
                          selectedProduct?.id,
                          selectedCategory?.id,
                          showLowStock
                        );
                        ref.read(generatedReportFilePathProvider.notifier).state = filePath;
                      } catch (e) {
                        if(!mounted) return;
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(content: Text('Error generating report: $e'), backgroundColor: SnackBarColor.errorMessage)
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
                          generatedFilePath.split('/').last, // Show just the filename
                          style: const TextStyle(fontSize: 16, color: Colors.green),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.download, color: Colors.blue),
                        onPressed: () {
                          // In a real app, this would trigger file download/share
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


  // --- Placeholder for Excel Report Generation ---
  // In a real app, this would involve fetching data,
  // using an Excel package (e.g., 'excel'), and saving the file.
  Future<String> _generateExcelReport(
      WidgetRef ref,
      DropdownItem selectedWarehouse,
      String? productId,
      String? categoryId,
      bool showLowStock
      ) async {
    ref.read(isGeneratingReportProvider.notifier).state = true;

    try {
      // 1. Load product count safely
      final summaryParams = StockSummaryParams(
        warehouseId: selectedWarehouse.id,
        categoryId: categoryId,
        productId: productId,
        showLowStock: showLowStock,
      );

      final stockData = await ref.read(stockSummaryProvider(summaryParams).future);

      final excel = Excel.createExcel();
      Sheet sheet = excel['Stock Summary'];
      excel.delete('Sheet1');

    // Header values
      final headers = [
        'Warehouse',
        'Product',
        'Category',
        'HSN Code',
        'Unit',
        'Quantity',
        'Low Stock Alert On',
      ];

// Manually set each header cell with style
      for (int col = 0; col < headers.length; col++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
        cell.value = TextCellValue(headers[col]);
        cell.cellStyle = kReportHeaderStyle;
        sheet.setColumnAutoFit(col);
      }

      for (final stock in stockData) {
        sheet.appendRow([
          TextCellValue(selectedWarehouse.name),
          TextCellValue(stock.name),
          TextCellValue(stock.category),
          TextCellValue(stock.hsn),
          TextCellValue(stock.unit),
          DoubleCellValue(stock.totalQuantity),
          DoubleCellValue(stock.lowStockAlert),
        ]);
        for (int col = 0; col < headers.length; col++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: sheet.maxRows-1));
          cell.cellStyle = kReportDataStyle;
        }
      }
// 4. Save the Excel workbook to bytes
      List<int>? fileBytes = excel.save(); // This generates the bytes

// Error handling for save operation
      if (fileBytes == null) {
        throw Exception('Failed to generate Excel file bytes.');
      }

      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'Current_Stock_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final filePath = '${dir.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(fileBytes);
      ref.read(isGeneratingReportProvider.notifier).state = false;
      return filePath;
    } finally {
      ref.read(isGeneratingReportProvider.notifier).state = false;
    }
  }



  // --- Placeholder for Report Download ---
  void _downloadReport(BuildContext context, String filePath) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading file: ${filePath.split('/').last}'), backgroundColor: SnackBarColor.successMessage)
    );
    try {
      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        if(!mounted) return;
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(content: Text('Failed to open file: ${result.message}'), backgroundColor: SnackBarColor.errorMessage)
        );
      }
    } catch (e) {
      if(!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text('Error opening file: $e'), backgroundColor: SnackBarColor.errorMessage)
      );
    }
  }
}
