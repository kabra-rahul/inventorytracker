// undone_transaction_report_page.dart
import 'dart:io';

import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart'; // For DateFormat
import 'package:inventorytracker/Functionality/Report/Provider/report_provider.dart'; // For report-specific StateProviders
import 'package:inventorytracker/Functionality/Report/Provider/undo_transaction_report_provider.dart';
import 'package:inventorytracker/Functionality/User/Model/app_user_model.dart';
import 'package:inventorytracker/Functionality/User/Provider/user_provider.dart'; // For userListProvider
import 'package:inventorytracker/Shared/Constants/movement_constants.dart';
import 'package:inventorytracker/Shared/Constants/snackbar_color.dart';
import 'package:inventorytracker/Shared/Constants/sort_enums.dart';
import 'package:inventorytracker/Shared/Util/excel_style.dart';
import 'package:inventorytracker/Shared/Widgets/custom_text_field.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';


class UndoneTransactionReportPage extends ConsumerStatefulWidget {
  const UndoneTransactionReportPage({super.key});

  @override
  ConsumerState<UndoneTransactionReportPage> createState() => _UndoneTransactionReportPageState();
}

class _UndoneTransactionReportPageState extends ConsumerState<UndoneTransactionReportPage> {
  final _formKey = GlobalKey<FormState>();
  SortOrder? _sortOrder = SortOrder.Descending;

  @override
  Widget build(BuildContext context) {
    final fromDate = ref.watch(undoTransactionReportFromDateProvider);
    final toDate = ref.watch(undoTransactionReportToDateProvider);
    final userController = ref.watch(undoTransactionReportUserSearchControllerProvider);
    final selectedUser = ref.watch(selectedUserForUndoTransactionReportProvider);

    final isGenerating = ref.watch(isGeneratingReportProvider);
    final generatedFilePath = ref.watch(generatedReportFilePathProvider);

    final userListAsync = ref.watch(userListProvider); // For Autocomplete options

    return Scaffold(
      appBar: AppBar(
        title: const Text('Undone Transaction Report'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
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

              // From Date (Required)
              CustomTextField(
                label: 'From Date',
                hintText: 'dd-mm-yyyy',
                controller: TextEditingController(text: fromDate != null ? DateFormat('dd-MM-yyyy').format(fromDate) : ''),
                readOnly: true,
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: fromDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    ref.read(undoTransactionReportFromDateProvider.notifier).state = pickedDate;
                  }
                },
                suffixIcon: const Icon(Icons.calendar_today),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'From Date is required';
                  }
                  if (toDate != null && fromDate != null && toDate.isBefore(fromDate)) {
                    return 'From Date cannot be after To Date';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // To Date (Required)
              CustomTextField(
                label: 'To Date',
                hintText: 'dd-mm-yyyy',
                controller: TextEditingController(text: toDate != null ? DateFormat('dd-MM-yyyy').format(toDate) : ''),
                readOnly: true,
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: toDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    ref.read(undoTransactionReportToDateProvider.notifier).state = pickedDate;
                  }
                },
                suffixIcon: const Icon(Icons.calendar_today),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'To Date is required';
                  }
                  if (fromDate != null && toDate != null) {
                    if (toDate.isBefore(fromDate)) {
                      return 'To Date cannot be before From Date';
                    }
                    // Check date difference (max 1 year)
                    if (toDate.difference(fromDate).inDays > 365) { // Roughly 1 year
                      return 'Date range cannot exceed 1 year';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // User Autocomplete (Optional - Undone By)
              Autocomplete<AppUser>( // Using User model here
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<AppUser>.empty();
                  }
                  return userListAsync.when(
                    data: (users) => users.where((u) => u.userName.toLowerCase().contains(textEditingValue.text.toLowerCase())),
                    loading: () => const Iterable<AppUser>.empty(),
                    error: (err, stack) => const Iterable<AppUser>.empty(),
                  );
                },
                displayStringForOption: (AppUser u) => u.userName,
                onSelected: (AppUser u) {
                  userController.text = u.userName;
                  ref.read(selectedUserForUndoTransactionReportProvider.notifier).state = u;
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  userController.text = controller.text;
                  return CustomTextField(
                    label: 'Undone By (Optional)',
                    hintText: 'Enter user name',
                    controller: controller,
                    focusNode: focusNode,
                    onFieldSubmitted: onFieldSubmitted,
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Sort Type',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioMenuButton<SortOrder>(
                      value: SortOrder.Ascending,
                      groupValue: _sortOrder,
                      onChanged: (selectedOrder) {
                        setState(() {
                          _sortOrder = selectedOrder;
                        });
                      },
                      style: ButtonStyle(
                          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          backgroundColor: WidgetStatePropertyAll(_sortOrder == SortOrder.Ascending ? Colors.blue : Colors.grey[200]),
                          foregroundColor: WidgetStatePropertyAll(_sortOrder == SortOrder.Ascending ? Colors.white : Colors.black87,)
                      ),
                      child: Text(SortOrder.Ascending.name),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RadioMenuButton<SortOrder>(
                      value: SortOrder.Descending,
                      groupValue: _sortOrder,
                      onChanged: (selectedOrder) {
                        setState(() {
                          _sortOrder = selectedOrder;
                        });
                      },
                      style: ButtonStyle(
                          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          backgroundColor: WidgetStatePropertyAll(_sortOrder == SortOrder.Descending ? Colors.blue : Colors.grey[200]),
                          foregroundColor: WidgetStatePropertyAll(_sortOrder == SortOrder.Descending ? Colors.white : Colors.black87,)
                      ),
                      child: Text(SortOrder.Descending.name),
                    ),
                  ),
                ],
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
                      // Date validation (already handled by CustomTextField validators, but good to double check)
                      if (fromDate == null || toDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Both From Date and To Date are required.'), backgroundColor: SnackBarColor.errorMessage)
                        );
                        return;
                      }
                      if (toDate.isBefore(fromDate)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('To Date cannot be before From Date.'), backgroundColor: SnackBarColor.errorMessage)
                        );
                        return;
                      }
                      if (toDate.difference(fromDate).inDays > 365) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Date range cannot exceed 1 year.'), backgroundColor: SnackBarColor.errorMessage)
                        );
                        return;
                      }

                      ref.read(isGeneratingReportProvider.notifier).state = true;
                      ref.read(generatedReportFilePathProvider.notifier).state = null;

                      try {
                        final filePath = await _generateExcelReport(
                          ref,
                          fromDate,
                          toDate,
                          selectedUser?.id, // Pass the ID of the user who undid it
                        );
                        ref.read(generatedReportFilePathProvider.notifier).state = filePath;
                      } catch (e) {
                        if (!mounted) return;
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
      DateTime fromDate,
      DateTime toDate,
      String? undoneByUserId,
      ) async {
    ref.read(isGeneratingReportProvider.notifier).state = true;

    final params = (
    fromDate: fromDate,
    toDate: toDate,
    undoneByUserId: undoneByUserId,
    );

    final reportData = await ref.read(undoTransactionReportDataProvider(params).future);

    final excel = Excel.createExcel();
    Sheet sheet = excel['Undone Transaction Report'];
    excel.delete('Sheet1');

    final headers = [
      'Undone Date',
      'Undone By',
      'Warehouse',
      'Product Name',
      'HSN Code',
      'Unit',
      'Type',
      'Quantity',
      'Price Per Unit',
      'Supplier',
      'Client',
      'Original Transaction Date',
      'Performed By (Original)',
      'Reason'
    ];

    final int headerRowIndex = sheet.maxRows;
    sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());
    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRowIndex));
      cell.cellStyle = kReportHeaderStyle;
      sheet.setColumnAutoFit(col);
    }

    if(_sortOrder == SortOrder.Ascending) {
      reportData.sort((a, b) => a.date.compareTo(b.date));
    } else {
      reportData.sort((a, b) => b.date.compareTo(a.date));
    }

    for (final transaction in reportData) {
      sheet.appendRow([
        TextCellValue(transaction.undoneDate != null ? DateFormat('dd MMM yyyy hh:mm a').format(transaction.undoneDate!) : 'N/A'),
        TextCellValue(transaction.undoneByUserName),
        TextCellValue(transaction.warehouseName),
        TextCellValue(transaction.productName),
        TextCellValue(transaction.hsnCode),
        TextCellValue(transaction.unitName),
        TextCellValue(transaction.type),
        DoubleCellValue(transaction.quantity),
        DoubleCellValue(transaction.price),
        TextCellValue(transaction.type == MovementConstants.inwardMovement ? transaction.supplierName : 'N/A'),
        TextCellValue(transaction.type == MovementConstants.outwardMovement ? transaction.clientName : 'N/A'),
        TextCellValue(DateFormat('dd MMM yyyy hh:mm a').format(transaction.date)),
        TextCellValue(transaction.userName), // Original Performed By
        TextCellValue(transaction.undoneReason.toString())
      ]);
      for (int col = 0; col < headers.length; col++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: sheet.maxRows-1));
        cell.cellStyle = kReportDataStyle;
      }
    }

    List<int>? fileBytes = excel.save();
    if (fileBytes == null) {
      throw Exception('Failed to generate Excel file bytes.');
    }

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'Undone_Transaction_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final filePath = '${dir.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(fileBytes);
    ref.read(isGeneratingReportProvider.notifier).state = false;
    return filePath;
  }

  void _downloadReport(BuildContext context, String filePath) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening file: ${filePath.split('/').last}'), backgroundColor: SnackBarColor.successMessage)
    );
    try {
      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        if (!mounted) return;
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(content: Text('Failed to open file: ${result.message}'), backgroundColor: SnackBarColor.errorMessage)
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text('Error opening file: $e'), backgroundColor: SnackBarColor.errorMessage)
      );
    }
  }
}
