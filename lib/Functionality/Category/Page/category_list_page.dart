//category_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventorytracker/Functionality/Category/Model/category_model.dart';
import 'package:inventorytracker/Functionality/Category/Provider/category_provider.dart';
import 'package:inventorytracker/Routes/app_router.dart';
import 'package:inventorytracker/Shared/Constants/size_constants.dart';
import 'package:inventorytracker/Shared/Widgets/card_list_item.dart';
import 'package:inventorytracker/Shared/Widgets/custom_text_field.dart';

/// Page that lists all categories for a given company
/// Supports real-time updates, add, edit, delete operations
class CategoryListPage extends ConsumerStatefulWidget {
  const CategoryListPage({super.key});

  @override
  ConsumerState<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends ConsumerState<CategoryListPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Listen to search query changes from the provider
    _searchController.addListener(() {
      ref.read(categorySearchQueryProvider.notifier).state =
          _searchController.text;
    });
  }

  @override
  void dispose() {
    // Dispose controller to avoid memory leak
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToEditPage(Category? category) {
    ref.read(editCategoryProvider.notifier).state = category;
    context.push(AppRoutePaths.categoryEdit); // Use GoRouter to navigate
  }

  @override
  Widget build(BuildContext context) {
    final showInactive = ref.watch(showInactiveCategoriesProvider);
    final filteredCategoriesAsync = ref.watch(filteredCategoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop();
          },
        ),
        actions: [
              Row(
                children: [
                  const Text("Show Inactive"),
                  Padding(
                    padding: const EdgeInsets.only(right: SizeConstants.paddingForToggle),
                    child: Switch(
                      value    : showInactive,
                      onChanged: (val) => ref.read(showInactiveCategoriesProvider.notifier).state = val
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
              hintText: 'Search categories...',
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
            child: filteredCategoriesAsync.when(
              data: (categories) {
                if (categories.isEmpty) {
                  return const Center(
                    child: Text(
                      'No Categories found',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isDisabled = !category.active;
                    return CardListItem(
                      key: ValueKey(category.id), // Pass the key
                      title:
                          isDisabled
                              ? '${category.name} (Disabled)'
                              : category.name,
                      textColor: isDisabled ? Colors.grey[600] : Colors.black87,
                      textFontStyle:
                          isDisabled ? FontStyle.italic : FontStyle.normal,
                      onTap: () => _navigateToEditPage(category),
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
          _navigateToEditPage(null); // Navigate to add new category
        },
      ),
    );
  }
}