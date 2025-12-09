//hsn_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventorytracker/Functionality/Hsn/Model/hsn_model.dart';
import 'package:inventorytracker/Functionality/Hsn/Provider/hsn_provider.dart';
import 'package:inventorytracker/Routes/app_router.dart';
import 'package:inventorytracker/Shared/Constants/size_constants.dart';
import 'package:inventorytracker/Shared/Widgets/card_list_item.dart';
import 'package:inventorytracker/Shared/Widgets/custom_text_field.dart';

/// Page that lists all hsns for a given company
/// Supports real-time updates, add, edit, delete operations
class HsnListPage extends ConsumerStatefulWidget {
  const HsnListPage({super.key});

  @override
  ConsumerState<HsnListPage> createState() => _HsnListPageState();
}

class _HsnListPageState extends ConsumerState<HsnListPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Listen to search query changes from the provider
    _searchController.addListener(() {
      ref.read(hsnSearchQueryProvider.notifier).state =
          _searchController.text;
    });
  }

  @override
  void dispose() {
    // Dispose controller to avoid memory leak
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToEditPage(Hsn? hsn) {
    ref.read(editHsnProvider.notifier).state = hsn;
    context.push(AppRoutePaths.hsnEdit); // Use GoRouter to navigate
  }

  @override
  Widget build(BuildContext context) {
    final showInactive = ref.watch(showInactiveHsnsProvider);
    final filteredHsnCodesAsync = ref.watch(filteredHsnListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('HSN Codes'),
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
                padding: EdgeInsets.only(right: SizeConstants.paddingForToggle),
                child: Switch(
                  value    : showInactive,
                  onChanged: (val) => ref.read(showInactiveHsnsProvider.notifier).state = val,
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
              hintText: 'Search HSN Codes...',
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
            child: filteredHsnCodesAsync.when(
              data: (hsnCodes) {
                if (hsnCodes.isEmpty) {
                  return const Center(
                    child: Text(
                      'No HsnCodes found',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: hsnCodes.length,
                  itemBuilder: (context, index) {
                    final hsn = hsnCodes[index];
                    final isDisabled = !hsn.active;
                    return CardListItem(
                      key: ValueKey(hsn.id), // Pass the key
                      title: isDisabled
                          ? '${hsn.code} (Disabled)'
                          : hsn.code,
                      textColor: isDisabled ? Colors.grey[600] : Colors.black87,
                      textFontStyle: isDisabled ? FontStyle.italic : FontStyle.normal,
                      onTap: () => _navigateToEditPage(hsn),
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
          _navigateToEditPage(null); // Navigate to add new hsn
        },
      ),
    );
  }
}
