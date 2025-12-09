//stock_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventorytracker/Functionality/Stock/Parameters/stock_params.dart';
import 'package:inventorytracker/Routes/app_router.dart';
import 'package:inventorytracker/Shared/Constants/size_constants.dart';
import 'package:inventorytracker/Shared/Widgets/card_list_item.dart';
import '../Provider/stock_provider.dart';
import 'package:inventorytracker/Shared/Constants/enums.dart'; // Assuming StockListMode is defined here
import 'package:inventorytracker/Shared/Widgets/custom_text_field.dart'; // Assuming you have this widget

class StockListPage extends ConsumerStatefulWidget {
  final String warehouseId;
  final List<String> productIds;
  final StockListMode mode;

  const StockListPage({
    super.key,
    required this.warehouseId,
    required this.productIds,
    required this.mode,
  });

  @override
  ConsumerState<StockListPage> createState() => _StockListPageState();
}

class _StockListPageState extends ConsumerState<StockListPage> {
  final TextEditingController _searchController = TextEditingController();

  // Define StockListParams here, since it's used in initState and build
  late StockListParams _params;

  @override
  void initState() {
    super.initState();
    _params = StockListParams(
      warehouseId: widget.warehouseId,
      productIds: widget.productIds,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(stockListModeProvider.notifier).state = widget.mode;
      }
    });

    // Set the initial mode for filtering in the provider
    //ref.read(stockListModeProvider.notifier).state = widget.mode;

    _searchController.addListener(() {
      ref.read(stockSearchQueryProvider.notifier).state = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the filteredStockListProvider, passing the params
    final filteredStocksAsync = ref.watch(filteredStockListProvider(_params));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode == StockListMode.allStock ? 'Stock in Warehouse' : 'Low Stock Products'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: SizeConstants.spaceBeforeAndAfterField),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: CustomTextField(
              controller: _searchController,
              hintText: 'Search by Product Name, HSN, Category',
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
            child: filteredStocksAsync.when(
              data: (stocks) {
                if (stocks.isEmpty) {
                  return const Center(
                    child: Text(
                      'No matching products.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: stocks.length,
                  itemBuilder: (context, index) {
                    final product = stocks[index];
                    return CardListItem(
                      key: ValueKey(product.productId),
                      title: product.name,
                      subtitle: 'Total Qty: ${product.totalQuantity}',
                      textColor: Colors.black87,
                      textFontStyle: FontStyle.normal,
                      onTap: () {
                        context.push(AppRoutePaths.stockDetail, extra: {
                          'warehouseId': widget.warehouseId,
                          'product': product
                        });
                      },
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
    );
  }
}