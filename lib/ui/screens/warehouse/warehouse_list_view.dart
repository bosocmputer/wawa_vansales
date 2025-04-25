import 'package:flutter/material.dart';
import 'package:wawa_vansales/data/models/warehouse_model.dart';
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

    // ใช้ cacheExtent เพื่อเพิ่มประสิทธิภาพ
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      cacheExtent: 200.0, // เพิ่ม cacheExtent
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
    );
  }
}
