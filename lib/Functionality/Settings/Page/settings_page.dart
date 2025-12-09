//setting_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventorytracker/Shared/Constants/size_constants.dart';
import '../Provider/settings_provider.dart';
import '../Widget/company_settings_form.dart';
import '../Widget/user_settings_form.dart';


class SettingsPage extends ConsumerStatefulWidget {

  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}


class _SettingsPageState extends ConsumerState<SettingsPage> with SingleTickerProviderStateMixin  {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }


  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop(); // Takes user back to home
          }
        )
      ),
      body: Padding(
        padding: const EdgeInsets.all(SizeConstants.pageFormPadding), // Adjust padding as needed
        child: Column(
          children: [
            // Custom TabBar Container
            Container(
              height: 48, // Height matching your image
              decoration: BoxDecoration(
                color: Colors.grey[200], // Light grey background
                borderRadius: BorderRadius.circular(12.0), // Rounded corners for the container
                border: Border.all(color: Colors.grey.shade300), // Light border around the whole control
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab, // Makes indicator fill the tab area
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0), // Slightly less rounded for the indicator
                  color: Colors.blue, // Blue color for the selected tab indicator
                ),
                labelColor: Colors.white, // Text color for selected tab
                unselectedLabelColor: Colors.grey[700], // Darker grey for unselected text
                tabs: const [
                  Tab(text: 'User Settings'), // Label matching the image
                  Tab(text: 'Company Settings'), // Label matching the image
                ],
              ),
            ),
            const SizedBox(height: SizeConstants.spaceBetweenFields), // Space between the tab bar and content
            // TabBarView for content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  const UserSettingsForm(),
                  // Only show CompanySettingsForm if isAdmin is true
                  isAdmin ? const CompanySettingsForm() : const Center(child: Text('Access Restricted')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}