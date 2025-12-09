//movement_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventorytracker/Shared/Constants/movement_constants.dart';
import 'package:inventorytracker/Shared/Constants/size_constants.dart';
import '../../StockMovement/Model/stock_movement_model.dart';

class MovementCard extends StatelessWidget {
  final StockMovementModel movement;
  final String productName;
  final String unitSymbol;
  final Map<String, String> supplierNames;
  final Map<String, String> clientNames;
  final Map<String, String> batchNumber;
  final Map<String, String> batchToSupplierId;
  final VoidCallback onUndo;
  final bool isAdmin;

  const MovementCard({
    super.key,
    required this.movement,
    required this.productName,
    required this.unitSymbol,
    required this.supplierNames,
    required this.clientNames,
    required this.batchNumber,
    required this.batchToSupplierId,
    required this.onUndo,
    required this.isAdmin
  });

  static const double _labelWidth = 75.0;

  // Helper method to build an aligned row for details
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed width container for the label + colon
          SizedBox(
            width: _labelWidth,
            child: Text(
              label, // Colon is now part of the label string
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Text(':',style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          // Small space between the colon and the value
          const SizedBox(width: 16.0),

          // Value takes up the remaining space
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {

    final bool isOutward = movement.type == MovementConstants.outwardMovement;

    return Card(
      margin: const EdgeInsets.all(SizeConstants.paddingForCard),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(SizeConstants.paddingForCard),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product name and Undo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded (
                  child: Text(
                    'Product : $productName',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (isAdmin)
                  Column(
                    spacing: 0,
                    children: [
                      IconButton(icon: const Icon(Icons.undo), onPressed: onUndo),
                      Text('Undo')
                    ],
                  ),
              ],
            ),
            const SizedBox(height: SizeConstants.spaceBetweenFields/2),
            if (isOutward) // Conditional rendering for client name
              Column(
                  children: [_buildDetailRow('Client', clientNames[movement.clientId] ?? 'N/A'),
                            const Divider(height: 15),
                  ]
              ),
            // Each batch row
            Column(
              children: movement.batchesAffected.map((batch) {
                final String supplierId = batchToSupplierId[batch.batchId] ?? '';
                final String supplierName = supplierId.isNotEmpty ? (supplierNames[supplierId] ?? 'N/A') : 'N/A';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Supplier', supplierName),
                    _buildDetailRow('Lot No', batchNumber[batch.batchId] ?? 'N/A'),
                    _buildDetailRow('Quantity', '${batch.quantity} $unitSymbol'),
                    _buildDetailRow('Date', DateFormat('dd MMM yyyy hh:mm a').format(movement.date)),
                    const Divider(height: 15),
                  ],
                );
              }).toList(),
            ),

            const SizedBox(height: SizeConstants.spaceBetweenFields/4),

            // Total Qty
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Total Quantity: ${movement.totalQuantity} $unitSymbol',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
