//dashboard_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventorytracker/Model/app_store_model.dart';
import 'package:inventorytracker/Model/dropdown_item_model.dart';
import 'package:inventorytracker/Provider/app_store_provider.dart';
import 'package:inventorytracker/Provider/connectivity_provider.dart';
import 'package:inventorytracker/Routes/app_router.dart';
import 'package:inventorytracker/Shared/Constants/plan_constants.dart';
import 'package:inventorytracker/Shared/Constants/role_constants.dart';
import 'package:inventorytracker/Shared/Constants/snackbar_color.dart';
import 'package:inventorytracker/Shared/Widgets/custom_dropdown_field.dart';
import 'package:inventorytracker/Shared/globals.dart';
import '../Provider/dashboard_provider.dart';
import '../Widget/dashboard_side_drawer.dart';
import '../Widget/dashboard_primary_tile.dart';
import '../../../Shared/Widgets/common_action_tile.dart';
import 'package:inventorytracker/Shared/Constants/enums.dart';


class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});



  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queryParams = GoRouterState.of(context).uri.queryParameters;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (queryParams['expired'] == 'true' && !initialExpiryCheckDone) {
        initialExpiryCheckDone = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Your paid plan has expired. Please renew to continue using Services.'),
            backgroundColor: SnackBarColor.errorMessage,
          ),
        );
      } else if (queryParams['grace_period'] == 'true' && !initialExpiryCheckDone) {
        initialExpiryCheckDone = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Your paid plan has expired. Please renew to prevent stopping of Services.',),
            backgroundColor: SnackBarColor.errorMessage,
          ),
        );
      } else if (queryParams['expiry_reminder'] == 'true' && !initialExpiryCheckDone) {
        initialExpiryCheckDone = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Your paid plan is about to Expire. Please renew.',),
            backgroundColor: SnackBarColor.errorMessage,
          ),
        );
      }
    });

    final user = FirebaseAuth.instance.currentUser;
    final String userName = user?.displayName ?? 'User'; // Safely get display name, fallback to 'User'
    final String userProfilePicUrl = user?.photoURL ?? '';
    final bool isConnected = ref.watch(isConnectedProvider);

    final app = ref.watch(appStoreProvider);
    final whAsync = ref.watch(warehousesProvider);
    final selectedWarehouseId = ref.watch(selectedWarehouseProvider);

    final userData = app.when(
      data: (appData) => appData,
      loading: () => null,
      error: (e, _) => null,
    );

    final AsyncValue<List<DropdownItem>> dropdownItemsAsync = whAsync.when(
      data: (whMap) {
        final List<DropdownItem> items = whMap.entries
            .map((entry) => DropdownItem(id: entry.value, name: entry.key))
            .toList();
        return AsyncValue.data(items);
      },
      loading: () => const AsyncValue.loading(),
      error: (err, stack) => AsyncValue.error(err, stack),
    );

    final params = (warehouseId: selectedWarehouseId ?? '', categoryId: '');
    final productAsync = ref.watch(productCountProvider(params));

    return Scaffold(
      drawer: app.when(
        data: (appData) => SideDrawer(
          app: appData ?? AppStore.empty(),
          userName: userName, // Pass safely obtained userName
          userProfilePicUrl: userProfilePicUrl, // Pass safely obtained userProfilePicUrl
          ref: ref
        ),
        loading: () => const Drawer(child: Center(child: CircularProgressIndicator())),
        error: (e, _) => Drawer(child: Center(child: Text('Error: $e'))),
      ),
      appBar: AppBar(
        title: Text('Hello, $userName'), // Fixed title as per image
        centerTitle: true, // Center the title
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Warehouse Display (replaces DropdownButtonFormField)
            CustomDropdownField(
              label: 'Select Warehouse',
              hint: 'Choose a warehouse',
              value: selectedWarehouseId, // The currently selected ID
              items: dropdownItemsAsync, // Pass the converted AsyncValue<List<DropdownItem>>
              onChanged: isConnected
                  ? (newValue) {
                      if (newValue != null && newValue != selectedWarehouseId) {
                        ref.read(selectedWarehouseProvider.notifier).state = newValue;
                        // Invalidate productCountProvider to force a reload with the new warehouseId
                        ref.invalidate(productCountProvider);
                      }
                    }
                  : (_) { },
            ),
            const SizedBox(height: 20),
            /// Total Products & Low Stock Tiles
            if (selectedWarehouseId != null)
              productAsync.when(
                data: (stat) => Row(
                  children: [
                    Expanded(
                      child: DashboardPrimaryTile( // Using new primary tile widget
                        value: stat.totalCount.toString(),
                        label: 'In Stock Products',
                        icon: Icons.inventory_2, // Changed icon to match image
                        iconColor: Colors.blueAccent,
                        onTap: () => context.push(AppRoutePaths.stockList, extra: {
                          'warehouseId': selectedWarehouseId,
                          'productIds': stat.allProductIds,
                          'mode': StockListMode.allStock,
                        }),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DashboardPrimaryTile( // Using new primary tile widget
                        value: stat.lowStockCount.toString(),
                        label: 'Low Stock Products',
                        icon: Icons.warning_amber_rounded, // Changed icon to match image
                        iconColor: Colors.orange,
                        onTap: () => context.push(AppRoutePaths.stockList, extra: {
                          'warehouseId': selectedWarehouseId,
                          'productIds': stat.lowStockProductIds,
                          'mode': StockListMode.lowStock,
                        }),
                      ),
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error fetching product count: $e'),
              ),

            const SizedBox(height: 20),

            // Grid for other actions
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                shrinkWrap: true, // Allow GridView to take only necessary space
                physics: const NeverScrollableScrollPhysics(), // Disable GridView's own scrolling
                children: [
                  CommonActionTile( // New smaller tile widget
                    label: 'Recent Transactions',
                    icon: Icons.receipt_long, // Adjusted icon
                    onTap: isConnected
                    ? () {
                        selectedWarehouseId!= null
                          ? context.push(AppRoutePaths.transaction , extra: {'warehouseId': selectedWarehouseId})
                          : ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('First Select a Warehouse'), backgroundColor: SnackBarColor.errorMessage,));
                      }
                    : () {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No internet connection to view transactions.'), backgroundColor: SnackBarColor.errorMessage,));
                    }
                  ),
                  CommonActionTile( // New smaller tile widget
                    label: 'Reports',
                    icon: Icons.bar_chart, // Adjusted icon
                    onTap: isConnected
                        ? () {
                            if(userData?.plan != PlanConstants.freePlan) {
                              if(userData?.role != RoleConstants.adminRole){
                                ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Reports can only be used by Admins'), backgroundColor: SnackBarColor.errorMessage));
                              } else {
                                context.push(AppRoutePaths.reportList);
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Reports Not Available in Free Plan'), backgroundColor: SnackBarColor.errorMessage,));
                            }
                        }
                        : () {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No internet connection to Generate Reports.'), backgroundColor: SnackBarColor.errorMessage,));
                    }
                  ),
                  CommonActionTile( // New smaller tile widget
                    label: 'Inward Movement',
                    icon: Icons.input, // Adjusted icon
                    onTap:  isConnected
                      ? () {
                        selectedWarehouseId != null
                          ? context.push(AppRoutePaths.inwardMovement, extra: {'warehouseId': selectedWarehouseId})
                          : ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('First Select a Warehouse'), backgroundColor: SnackBarColor.errorMessage));
                        }
                      : () {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No internet connection to perform Inward Movement.'), backgroundColor: SnackBarColor.errorMessage));
                      }
                  ),
                  CommonActionTile( // New smaller tile widget
                    label: 'Outward Movement',
                    icon: Icons.output, // Adjusted icon
                      onTap:  isConnected
                          ? () {
                        selectedWarehouseId != null
                            ? context.push(AppRoutePaths.outwardMovement, extra: {'warehouseId': selectedWarehouseId})
                            : ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('First Select a Warehouse'), backgroundColor: SnackBarColor.errorMessage));
                      }
                          : () {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No internet connection to perform Outward Movement.'), backgroundColor: SnackBarColor.errorMessage));
                      }
                  ),
                  // If isAdmin specific tiles are needed, they would go here
                  // using DashboardActionTile
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}