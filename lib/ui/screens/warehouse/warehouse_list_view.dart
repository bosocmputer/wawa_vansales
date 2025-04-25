import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wawa_vansales/blocs/warehouse/warehouse_bloc.dart';
import 'package:wawa_vansales/blocs/warehouse/warehouse_event.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/models/warehouse_model.dart';
import 'package:wawa_vansales/ui/screens/warehouse/emty_state_widget.dart';
import 'package:wawa_vansales/ui/screens/warehouse/search_box.dart';
import 'package:wawa_vansales/ui/screens/warehouse/warehouse_card.dart';

class WarehouseListView extends StatefulWidget {
  final List<WarehouseModel> warehouses;
  final WarehouseModel? selectedWarehouse;
  final Function(WarehouseModel) onWarehouseSelected;
  final bool isLoading;

  const WarehouseListView({
    super.key,
    required this.warehouses,
    required this.selectedWarehouse,
    required this.onWarehouseSelected,
    required this.isLoading,
  });

  @override
  State<WarehouseListView> createState() => _WarehouseListViewState();
}

class _WarehouseListViewState extends State<WarehouseListView> with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<WarehouseModel> get _filteredWarehouses {
    if (_searchQuery.isEmpty) {
      return widget.warehouses;
    }

    final query = _searchQuery.toLowerCase();
    return widget.warehouses.where((warehouse) {
      return warehouse.code.toLowerCase().contains(query) || warehouse.name.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Handle loading state
    if (widget.isLoading && widget.warehouses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('กำลังโหลดข้อมูลคลังสินค้า...'),
          ],
        ),
      );
    }

    // Handle empty state
    if (widget.warehouses.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.inventory_2,
        message: 'ไม่พบข้อมูลคลังสินค้า',
        actionLabel: 'ลองใหม่',
        onAction: () {
          context.read<WarehouseBloc>().add(FetchWarehouses());
        },
      );
    }

    return Column(
      children: [
        // Search box
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SearchBox(
            controller: _searchController,
            hintText: 'ค้นหาคลังสินค้า',
            prefixIcon: Icons.warehouse,
          ),
        ),

        // Results info
        if (_searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  'ผลการค้นหา (${_filteredWarehouses.length})',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('ล้างการค้นหา'),
                ),
              ],
            ),
          ),

        // No results message
        if (_searchQuery.isNotEmpty && _filteredWarehouses.isEmpty)
          Expanded(
            child: EmptyStateWidget(
              icon: Icons.search_off,
              message: 'ไม่พบคลังสินค้าที่ค้นหา',
              actionLabel: 'ล้างการค้นหา',
              onAction: () {
                _searchController.clear();
              },
            ),
          ),

        // Warehouse list
        if (_filteredWarehouses.isNotEmpty)
          Expanded(
            child: RawScrollbar(
              thumbVisibility: true,
              radius: const Radius.circular(5),
              thickness: 5,
              thumbColor: AppTheme.primaryColor.withOpacity(0.3),
              controller: _scrollController,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _filteredWarehouses.length,
                itemBuilder: (context, index) {
                  final warehouse = _filteredWarehouses[index];
                  final isSelected = widget.selectedWarehouse?.code == warehouse.code;

                  return WarehouseCard(
                    warehouse: warehouse,
                    isSelected: isSelected,
                    onSelected: () => widget.onWarehouseSelected(warehouse),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
