//transaction_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventorytracker/Shared/Constants/movement_constants.dart';
import 'package:inventorytracker/Shared/Constants/size_constants.dart';
import '../widget/movement_list_tab.dart';

class TransactionPage extends ConsumerStatefulWidget {
  final String warehouseId;

  const TransactionPage({super.key, required this.warehouseId});

  @override
  ConsumerState<TransactionPage> createState() => _TransactionPageState();
}


class _TransactionPageState extends ConsumerState<TransactionPage>
    with SingleTickerProviderStateMixin {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Transactions'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(SizeConstants.pageFormPadding),
        child: Column(
          children: [
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color: Colors.blue,
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[700],
                tabs: const [Tab(text: MovementConstants.inwardMovement), Tab(text: MovementConstants.outwardMovement)],
              ),
            ),
            const SizedBox(height: SizeConstants.spaceBetweenFields),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  MovementListTab(
                    warehouseId: widget.warehouseId,
                    type: MovementConstants.inwardMovement,
                  ),
                  MovementListTab(
                    warehouseId: widget.warehouseId,
                    type: MovementConstants.outwardMovement,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}