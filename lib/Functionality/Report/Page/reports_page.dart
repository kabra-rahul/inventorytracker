// reports_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventorytracker/Shared/Widgets/common_action_tile.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../Routes/app_router.dart';

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Report Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Two columns as per the image
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 1.2, // Adjust aspect ratio to fit content well
                ),
                itemCount: _reportTiles.length,
                itemBuilder: (context, index) {
                  final tile = _reportTiles[index];
                  return CommonActionTile(
                    label: tile['label'] as String,
                    icon: tile['icon'] as IconData,
                    onTap: () {
                      context.push(tile['onTap']);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // List of report tile data
  List<Map<String, dynamic>> get _reportTiles => [
    {
      'label': 'Current Stock Report',
      'icon' : FontAwesomeIcons.boxesStacked, // Icon for stock
      'onTap': AppRoutePaths.stockSummaryReport
    },
    {
      'label': 'Batch Details Report',
      'icon' : FontAwesomeIcons.boxesStacked, // Icon for stock
      'onTap': AppRoutePaths.batchSummaryReport
    },
    {
      'label': 'Client-wise Sell Report',
      'icon' : FontAwesomeIcons.users, // Icon for clients/customers
      'onTap': AppRoutePaths.clientSummaryReport
    },
    {
      'label': 'Supplier-wise Purchase Report',
      'icon' : FontAwesomeIcons.truckFast, // Icon for supplier/delivery
      'onTap': AppRoutePaths.supplierSummaryReport
    },

    {
      'label': 'Stock Transaction Report',
      'icon' : FontAwesomeIcons.rightLeft, // Icon for transactions/movement
      'onTap': AppRoutePaths.transactionReport
    },
    {
      'label': 'Undone transaction Report',
      'icon' : FontAwesomeIcons.triangleExclamation, // Icon for warnings/issues
      'onTap': AppRoutePaths.undoTransactionReport
    },
  ];
}