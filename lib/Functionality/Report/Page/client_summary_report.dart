import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' hide Border; // Hide Border to avoid conflict
import 'package:flutter/material.dart';
import 'package:inventorytracker/Functionality/Transaction/Provider/transaction_provider.dart';
import 'package:inventorytracker/Shared/Constants/snackbar_color.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventorytracker/Functionality/Client/Model/client_model.dart';
import 'package:inventorytracker/Functionality/Client/Provider/client_provider.dart';
import 'package:inventorytracker/Shared/Widgets/custom_text_field.dart';
import 'package:inventorytracker/Functionality/Report/Provider/report_provider.dart';
import 'package:inventorytracker/Functionality/Report/Provider/client_summary_provider.dart';

import '../../../Shared/Util/excel_style.dart';




class ClientBuyReportPage extends ConsumerStatefulWidget {
  const ClientBuyReportPage({super.key});

  @override
  ConsumerState<ClientBuyReportPage> createState() => _ClientBuyReportPageState();
}

class _ClientBuyReportPageState extends ConsumerState<ClientBuyReportPage> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final clientController = ref.watch(clientBuyReportControllerProvider);
    final selectedClient = ref.watch(selectedClientForBuyReportProvider);
    final fromDate = ref.watch(buyReportFromDateProvider);
    final toDate = ref.watch(buyReportToDateProvider);
    final isGenerating = ref.watch(isGeneratingReportProvider);
    final generatedFilePath = ref.watch(generatedReportFilePathProvider);

    final clientListAsync = ref.watch(clientListProvider); // For Autocomplete options

    return Scaffold(
      appBar: AppBar(
        title: const Text('Client-wise Sell Report'),
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

              // client Autocomplete
              Autocomplete<Client>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<Client>.empty();
                  }
                  return clientListAsync.when(
                    data: (clients) => clients.where((s) => s.companyName.toLowerCase().contains(textEditingValue.text.toLowerCase())),
                    loading: () => const Iterable<Client>.empty(),
                    error: (err, stack) => const Iterable<Client>.empty(),
                  );
                },
                displayStringForOption: (Client s) => s.companyName,
                onSelected: (Client s) {
                  clientController.text = s.companyName;
                  ref.read(selectedClientForBuyReportProvider.notifier).state = s;
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  clientController.text = controller.text;
                  return CustomTextField(
                    label: 'client',
                    hintText: 'Enter client name or ID',
                    controller: controller,
                    focusNode: focusNode,
                    onFieldSubmitted: onFieldSubmitted,
                  );
                },
              ),
              const SizedBox(height: 16),

              // From Date
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
                    ref.read(buyReportFromDateProvider.notifier).state = pickedDate;
                  }
                },
                suffixIcon: const Icon(Icons.calendar_today),
                validator: (value) {
                  if (fromDate == null) {
                    return 'From Date is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // To Date
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
                    ref.read(buyReportToDateProvider.notifier).state = pickedDate;
                  }
                },
                suffixIcon: const Icon(Icons.calendar_today),
                validator: (value) {
                  if (toDate == null) {
                    return 'To Date is required.';
                  }
                  return null;
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
                      if (selectedClient == null || selectedClient.id == '' || selectedClient.id.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please select a client.'),backgroundColor: SnackBarColor.errorMessage)
                        );
                        return;
                      } else if (fromDate != null && toDate != null) {
                        // 1. Check if fromDate is after toDate
                        if (fromDate.isAfter(toDate)) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('From Date cannot be after To Date.'), backgroundColor: SnackBarColor.errorMessage),
                          );
                          return;
                        }

                        // 2. Check if the range is greater than 1 year (366 days covers leap years)
                        // If toDate is after (fromDate + 366 days), the range is too large.
                        final oneYearLater = fromDate.add(const Duration(days: 366));
                        if (toDate.isAfter(oneYearLater)) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('The selected date range cannot exceed one year.'), backgroundColor: SnackBarColor.errorMessage),
                          );
                          return;
                        }
                      }

                      ref.read(isGeneratingReportProvider.notifier).state = true;
                      ref.read(generatedReportFilePathProvider.notifier).state = null;

                      try {
                        final filePath = await _generateExcelReport(
                          ref,
                          selectedClient,
                          fromDate,
                          toDate,
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
      Client client,
      DateTime? fromDate,
      DateTime? toDate,
      ) async {
    ref.read(isGeneratingReportProvider.notifier).state = true;

    final params = (
    clientId: client.id,
    fromDate: fromDate,
    toDate: toDate,
    );

    final reportData = await ref.read(clientBuyReportDataProvider(params).future);

    final excel = Excel.createExcel();
    Sheet sheet = excel['client Buy Report'];
    excel.delete('Sheet1');

    final headers = [
      'client Name',
      'Warehouse',
      'Product Name',
      'HSN Code',
      'Unit',
      'Quantity',
      'Price Per unit',
      'Transaction Date',
    ];

    final int headerRowIndex = sheet.maxRows;
    sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());
    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRowIndex));
      cell.cellStyle = kReportHeaderStyle;
      sheet.setColumnAutoFit(col);
    }

    for (final transaction in reportData) {
      sheet.appendRow([
        TextCellValue(client.companyName),
        TextCellValue(transaction.warehouseName),
        TextCellValue(transaction.productName),
        TextCellValue(transaction.hsnCode),
        TextCellValue(transaction.unitName),
        DoubleCellValue(transaction.quantity),
        DoubleCellValue(transaction.price),
        TextCellValue(DateFormat('dd MMM yyyy hh:mm a').format(transaction.date)),
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
    final fileName = 'client_Buy_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
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
          SnackBar(content: Text('Failed to open file: ${result.message}'), backgroundColor: SnackBarColor.errorMessage),
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