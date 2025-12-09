//unit_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventorytracker/Functionality/Units/Model/unit_model.dart';
import 'package:inventorytracker/Functionality/Units/Provider/unit_provider.dart';
import 'package:inventorytracker/Routes/app_router.dart';
import 'package:inventorytracker/Shared/Constants/size_constants.dart';
import 'package:inventorytracker/Shared/Widgets/card_list_item.dart';
import 'package:inventorytracker/Shared/Widgets/custom_text_field.dart';

/// Page that lists all units for a given company
/// Supports real-time updates, add, edit, delete operations
class UnitListPage extends ConsumerStatefulWidget {
  const UnitListPage({super.key});

  @override
  ConsumerState<UnitListPage> createState() => _UnitListPageState();
}

class _UnitListPageState extends ConsumerState<UnitListPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Listen to search query changes from the provider
    _searchController.addListener(() {
      ref.read(unitSearchQueryProvider.notifier).state =
          _searchController.text;
    });
  }

  @override
  void dispose() {
    // Dispose controller to avoid memory leak
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToEditPage(Unit? unit) {
    ref.read(editUnitProvider.notifier).state = unit;
    context.push(AppRoutePaths.unitEdit); // Use GoRouter to navigate
  }

  @override
  Widget build(BuildContext context) {
    final showInactive = ref.watch(showInactiveUnitsProvider);
    final filteredUnitsAsync = ref.watch(filteredUnitListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Units'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop(); // Takes user back to home
          },
        ),
        actions: [
          Row(
            children: [
              const Text("Show Inactive"),
              Padding(
                padding: const EdgeInsets.only(right: SizeConstants.paddingForToggle),
                child: Switch(
                  value: showInactive,
                  onChanged: (val) => ref.read(showInactiveUnitsProvider.notifier).state = val
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: SizeConstants.spaceBeforeAndAfterField),
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: CustomTextField(
              controller: _searchController,
              hintText: 'Search units...',
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                },
              ),
            ),
          ),
          const SizedBox(height: SizeConstants.spaceBetweenFields),
          Expanded(
            child: filteredUnitsAsync.when(
              data: (units) {
                if (units.isEmpty) {
                  return const Center(
                    child: Text(
                      'No Units found',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: units.length,
                  itemBuilder: (context, index) {
                    final unit = units[index];
                    final isDisabled = !unit.active;
                    return CardListItem(
                      key: ValueKey(unit.id), // Pass the key
                      title: isDisabled
                          ? '${unit.symbol} (${unit.name}) (Disabled)'
                          : '${unit.symbol} (${unit.name})',
                      textColor: isDisabled ? Colors.grey[600] : Colors.black87,
                      textFontStyle: isDisabled ? FontStyle.italic : FontStyle.normal,
                      onTap: () => _navigateToEditPage(unit),
                      // trailing: Icon(Icons.info), // You could customize trailing here if needed
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        shape: const CircleBorder(), // For the circular shape
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          _navigateToEditPage(null); // Navigate to add new unit
        },
      ),
    );
  }
}