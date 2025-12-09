import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventorytracker/Functionality/User/Provider/user_provider.dart';
import 'package:inventorytracker/Functionality/Warehouse/Model/warehouse_model.dart';
import 'package:inventorytracker/Functionality/Warehouse/Provider/warehouse_provider.dart';


class WarehouseCheckboxList extends ConsumerWidget {
  final int selectedWarehousesCount;

  const WarehouseCheckboxList({super.key, required this.selectedWarehousesCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedWarehouses = ref.watch(selectedWarehousesProvider);
    final showAllWarehouses = ref.watch(showAllWarehousesProvider);
    final warehousesAsyncValue = ref.watch(warehouseListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Warehouse Access ($selectedWarehousesCount)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                ref.read(showAllWarehousesProvider.notifier).state = !showAllWarehouses;
              },
              child: Text(showAllWarehouses ? 'Hide' : 'Show all'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        warehousesAsyncValue.when(
          data: (warehouses) {
            final activeWarehouseList = warehouses.where((w) => w.active);
            final List<Warehouse> sortedWarehouses = List.from(activeWarehouseList);
            sortedWarehouses.sort((a, b) => a.name.compareTo(b.name));

            if (showAllWarehouses) {
              return Column(
                children: sortedWarehouses.map((warehouse) {
                  final isSelected = selectedWarehouses.contains(warehouse.id);
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: CheckboxListTile(
                      title: Text(warehouse.name),
                      value: isSelected,
                      onChanged: (value) {
                        final updated = [...selectedWarehouses];
                        if (value == true) {
                          updated.add(warehouse.id);
                        } else {
                          updated.remove(warehouse.id);
                        }
                        ref.read(selectedWarehousesProvider.notifier).state = updated;
                      },
                      controlAffinity: ListTileControlAffinity.trailing,
                      activeColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }).toList(),
              );
            } else {
              if (selectedWarehouses.isEmpty) {
                return const Text('No warehouses selected.');
              }
              final selectedWarehouseNames = sortedWarehouses
                  .where((w) => selectedWarehouses.contains(w.id))
                  .map((w) => w.name)
                  .toList();
              return Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: selectedWarehouseNames.map((name) => Chip(label: Text(name))).toList(),
              );
            }
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error loading warehouses: $err')),
        ),
      ],
    );
  }
}