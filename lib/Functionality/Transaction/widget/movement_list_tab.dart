//movement_list_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventorytracker/Functionality/Settings/Provider/settings_provider.dart';
import 'package:inventorytracker/Shared/Constants/snackbar_color.dart';
import 'package:inventorytracker/Shared/Constants/transaction_details_constants.dart';
import 'package:inventorytracker/Shared/Widgets/confirmation_input_dialog.dart';
import '../../Stock/Parameters/stock_params.dart';
import '../../Stock/Provider/stock_provider.dart';
import '../../StockMovement/Model/stock_movement_model.dart';
import '../Provider/transaction_provider.dart';
import '../widget/movement_card.dart';

class MovementListTab extends ConsumerWidget {
  final String warehouseId;
  final String type;

  const MovementListTab({
    super.key,
    required this.warehouseId,
    required this.type,
  });


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movementParams = MovementQueryParams(
      warehouseId: warehouseId,
      type: type,
    );

    final movementAsync = ref.watch(recentMovementsProvider(movementParams));
    final isAdmin = ref.watch(isAdminProvider);

    return movementAsync.when(
      data: (data) {
        final movements         = data[TransactionDetailsConstants.transactionDocuments] as List<StockMovementModel>;
        final productNames      = (data[TransactionDetailsConstants.productNames] as Map).cast<String, String>();
        final unitSymbols       = (data[TransactionDetailsConstants.unitSymbols] as Map).cast<String, String>();
        final supplierNames     = (data[TransactionDetailsConstants.supplierNames] as Map).cast<String, String>();
        final clientNames       = (data[TransactionDetailsConstants.clientNames] as Map).cast<String, String>();
        final batchNumber       = (data[TransactionDetailsConstants.batchNumber] as Map).cast<String, String>();
        final batchToSupplierId = (data[TransactionDetailsConstants.batchToSupplierId] as Map).cast<String, String>();

        if (movements.isEmpty) {
          return const Center(child: Text('No transactions found'));
        }
        return ListView.builder(
          itemCount: movements.length,
          itemBuilder: (context, index) {
            final movement = movements[index];
            return MovementCard(
              movement: movement,
              productName: productNames[movement.productId] ?? '',
              unitSymbol: unitSymbols[movement.productId] ?? '',
              supplierNames: supplierNames,
              clientNames: clientNames,
              batchNumber: batchNumber,
              batchToSupplierId: batchToSupplierId,
              isAdmin: isAdmin,
              onUndo: () async {
                final String? undoReason = await showConfirmationInputDialog(
                  context,
                  title: 'Undo Transaction',
                  content: 'Please provide a reason for undoing this transaction:',
                  inputHintText: 'Reason for undo (e.g., "Data entry error", "Wrong quantity")',
                );

                try {
                  if (undoReason != null && undoReason.isNotEmpty && undoReason != '') {
                    final service = await ref.read(transactionServiceProvider.future);
                    await service.undoMovement(
                        movement: movement,
                        undoMovementReason: undoReason
                    );
                    final query = StockBatchesQuery(warehouseId: movement.warehouseId, stockId: movement.stockId);
                    ref.invalidate(stockBatchesProvider(query));
                    ref.invalidate(recentMovementsProvider(movementParams));

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Transaction undone!'), backgroundColor: SnackBarColor.successMessage,),
                      );
                    }
                  }
                } on Exception catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Transaction Undone Failed : $e'), backgroundColor: SnackBarColor.errorMessage,),
                    );
                  }
                }
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading: $err')),
    );
  }
}
