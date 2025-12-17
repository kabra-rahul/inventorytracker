import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventorytracker/Functionality/Dashboard/Provider/dashboard_provider.dart';
import 'package:inventorytracker/Routes/app_router.dart';
import 'package:inventorytracker/Model/app_store_model.dart';
import 'package:inventorytracker/Shared/Constants/snackbar_color.dart';


class SideDrawer extends StatelessWidget {
  final AppStore app;
  final String userName; // Now passed as a required parameter
  final String userProfilePicUrl; // Now passed as a required parameter
  final WidgetRef ref;

  const SideDrawer({
    super.key,
    required this.app,
    required this.userName, // Require userName
    required this.userProfilePicUrl, // Require userProfilePicUrl
    required this.ref
  });

  @override

  Widget build(BuildContext context) {
    final auth = FirebaseAuth.instance; // Still needed for signOut
    //final currentRoutePath = GoRouter.of(context).routerDelegate.currentConfiguration.uri.toString();
    final ScrollController verticalController = ScrollController();

    return Drawer(
      child: Column( // Use Column to place Sign Out at the very bottom
        children: [
          DrawerHeader(
           // decoration: const BoxDecoration(color: Colors.white), // Changed to white background
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: userProfilePicUrl.isNotEmpty
                        ? NetworkImage(userProfilePicUrl) as ImageProvider<Object>?
                        : null, // Use network image if available
                    child: userProfilePicUrl.isEmpty
                        ? const Icon(Icons.person, size: 30, color: Colors.grey)
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    userName,
                    style: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                // You could add app.companyId here if needed, but not in image
              ],
            ),
          ),
          Expanded( // Take remaining space for scrollable list
            child: Scrollbar(
              controller: verticalController,
              thumbVisibility: true,
              thickness: 6.0,
              child: ListView(
                controller: verticalController,
                primary: false,
                padding: EdgeInsets.zero,
                children: [
                  _buildListTile(context, 'Dashboard' , Icons.home       , AppRoutePaths.dashboard    , 'all'),
                  _buildListTile(context, 'Products'  , Icons.inventory_2, AppRoutePaths.productList  , 'all'),
                  _buildListTile(context, 'Category'  , Icons.folder     , AppRoutePaths.categoryList , 'all'),
                  _buildListTile(context, 'HSN Code'  , Icons.numbers    , AppRoutePaths.hsnList      , 'all'),
                  _buildListTile(context, 'Units'     , Icons.balance    , AppRoutePaths.unitList     , 'all'),
                  _buildListTile(context, 'Warehouses', Icons.warehouse  , AppRoutePaths.warehouseList, 'Admin'),
                  _buildListTile(context, 'Suppliers' , Icons.people     , AppRoutePaths.supplierList , 'all'),
                  _buildListTile(context, 'Clients'   , Icons.people     , AppRoutePaths.clientList   , 'all'),
                  _buildListTile(context, 'Users'     , Icons.person     , AppRoutePaths.userList     , 'Admin'),
                  _buildListTile(context, 'Settings'  , Icons.settings   , AppRoutePaths.settings     , 'all'),
                  _buildListTile(context, 'Payments'  , Icons.payment    , AppRoutePaths.payment      , 'Admin'),
                  _buildListTile(context, 'Contact Us', Icons.mail       , AppRoutePaths.contactUs    , 'all'),
                ],
              ),
            ),
          ),
          // Sign Out Button at the very bottom
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                ref.read(selectedWarehouseProvider.notifier).state = null;
                auth.signOut();
                context.go(AppRoutePaths.login); // Navigate to login
              },
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text('Sign Out', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50), // Full width, fixed height
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ListTile _buildListTile(BuildContext context, String title, IconData icon, String route, String access ,{bool isSelected = false}) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.blueAccent : Colors.grey[700]), // Icon
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.blueAccent : Colors.black87,
        ),
      ),
      tileColor: isSelected ? Colors.blue.withAlpha(26) : null, // Highlight selected tile
      onTap: () {
        if(access == 'Admin'){
          if(app.isAdmin){
            Navigator.pop(context); // Close the drawer
            context.push(route);
          } else {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Only Admins can Access.'), backgroundColor: SnackBarColor.errorMessage));
          }
        } else {
          Navigator.pop(context); // Close the drawer
          context.push(route); // Navigate
        }

      },
    );
  }
}