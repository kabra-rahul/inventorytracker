//category_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventorytracker/Functionality/User/Model/app_user_model.dart';
import 'package:inventorytracker/Functionality/User/Provider/user_provider.dart';
import 'package:inventorytracker/Routes/app_router.dart';
import 'package:inventorytracker/Shared/Constants/size_constants.dart';
import 'package:inventorytracker/Shared/Widgets/card_list_item.dart';
import 'package:inventorytracker/Shared/Widgets/custom_text_field.dart';

/// Page that lists all users for a given company
/// Supports real-time updates, add, edit, delete operations
class UserListPage extends ConsumerStatefulWidget {
  const UserListPage({super.key});

  @override
  ConsumerState<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends ConsumerState<UserListPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Listen to search query changes from the provider
    _searchController.addListener(() {
      ref.read(userSearchQueryProvider.notifier).state =
          _searchController.text;
    });
  }

  @override
  void dispose() {
    // Dispose controller to avoid memory leak
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToEditPage(AppUser? user) {
    ref.read(editUserProvider.notifier).state = user;
    context.push(AppRoutePaths.userEdit); // Use GoRouter to navigate
  }

  @override
  Widget build(BuildContext context) {
    final showInactive = ref.watch(showInactiveUsersProvider);
    final filteredUsersAsync = ref.watch(filteredUserListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
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
                  onChanged: (val) => ref.read(showInactiveUsersProvider.notifier).state = val
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
              hintText: 'Search Users...',
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
            child: filteredUsersAsync.when(
              data: (users) {
                if (users.isEmpty) {
                  return const Center(
                    child: Text(
                      'No Users found',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final isDisabled = !user.active;
                    return CardListItem(
                      key: ValueKey(user.id), // Pass the key
                      title: isDisabled
                          ? '${user.userName} (Disabled)'
                          : user.userName,
                      textColor: isDisabled ? Colors.grey[600] : Colors.black87,
                      textFontStyle: isDisabled ? FontStyle.italic : FontStyle.normal,
                      onTap: () => _navigateToEditPage(user),
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
          _navigateToEditPage(null); // Navigate to add new user
        },
      ),
    );
  }
}