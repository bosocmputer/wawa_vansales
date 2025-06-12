import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wawa_vansales/blocs/product_balance/product_balance_bloc.dart';
import 'package:wawa_vansales/blocs/product_balance/product_balance_event.dart';
import 'package:wawa_vansales/blocs/product_balance/product_balance_state.dart';
import 'package:wawa_vansales/blocs/warehouse/warehouse_bloc.dart';
import 'package:wawa_vansales/blocs/warehouse/warehouse_state.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/models/product_balance_model.dart';
import 'package:wawa_vansales/ui/widgets/error_dialog.dart';
import 'package:wawa_vansales/ui/widgets/loading_indicator.dart';
import 'package:wawa_vansales/ui/widgets/search_bar_widget.dart';
import 'package:wawa_vansales/utils/formatters.dart';

class ProductBalanceScreen extends StatefulWidget {
  const ProductBalanceScreen({super.key});

  @override
  State<ProductBalanceScreen> createState() => _ProductBalanceScreenState();
}

class _ProductBalanceScreenState extends State<ProductBalanceScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _whCode = '';
  String _shelfCode = '';

  @override
  void initState() {
    super.initState();
    final warehouseState = context.read<WarehouseBloc>().state;
    if (warehouseState is WarehouseSelectionComplete) {
      _whCode = warehouseState.warehouse.code;
      _shelfCode = warehouseState.location.code;

      // ดึงข้อมูลยอดคงเหลือเมื่อเข้าหน้าจอ
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ProductBalanceBloc>().add(
              FetchProductBalance(
                whCode: _whCode,
                shelfCode: _shelfCode,
              ),
            );
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (_whCode.isEmpty || _shelfCode.isEmpty) {
      _showWarehouseErrorDialog();
      return;
    }

    context.read<ProductBalanceBloc>().add(
          SetProductBalanceSearchQuery(query, _whCode, _shelfCode),
        );
  }

  void _showWarehouseErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => const ErrorDialog(
        title: 'ไม่พบข้อมูลคลังสินค้า',
        message: 'กรุณาเลือกคลังสินค้าและพื้นที่เก็บก่อนตรวจสอบยอดคงเหลือ',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ยอดสินค้าคงเหลือ'),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, 1),
                  blurRadius: 4,
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Row(
              children: [
                Expanded(
                  child: SearchBarWidget(
                    controller: _searchController,
                    hintText: 'ค้นหาสินค้า',
                    onSearch: _performSearch,
                    showSearchButton: false,
                    fillColor: Colors.grey.shade50,
                    borderRadius: 30,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  ),
                ),
                const SizedBox(width: 6),
                Material(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(30),
                  child: InkWell(
                    onTap: () => _performSearch(_searchController.text),
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.search,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                BlocBuilder<ProductBalanceBloc, ProductBalanceState>(
                  builder: (context, state) {
                    if (state is ProductBalanceLoaded) {
                      return Text(
                        'พบ ${state.balances.length} รายการ',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary.withOpacity(0.8),
                        ),
                      );
                    }
                    return const Text(
                      'พิมพ์เพื่อค้นหาสินค้า',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocConsumer<ProductBalanceBloc, ProductBalanceState>(
              listener: (context, state) {
                if (state is ProductBalanceError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
              builder: (context, state) {
                if (state is ProductBalanceInitial) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search,
                          size: 60,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'ค้นหาสินค้าเพื่อตรวจสอบยอดคงเหลือ',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (state is ProductBalanceLoading) {
                  return const LoadingIndicator();
                } else if (state is ProductBalanceLoaded) {
                  if (state.balances.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 60,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'ไม่พบข้อมูลสินค้าตามที่ค้นหา\nลองเปลี่ยนคำค้นหาใหม่',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return _buildProductBalanceList(state.balances);
                } else if (state is ProductBalanceError) {
                  return Center(
                    child: Text('เกิดข้อผิดพลาด: ${state.message}'),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductBalanceList(List<ProductBalanceModel> balances) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: balances.length,
      separatorBuilder: (context, index) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final balance = balances[index];
        return _buildProductBalanceCard(balance);
      },
    );
  }

  Widget _buildProductBalanceCard(ProductBalanceModel balance) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // ข้อมูลสินค้า
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        balance.itemName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'รหัส: ${balance.itemCode} | บาร์โค้ด: ${balance.barcode}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            // รายละเอียดจำนวนและราคา
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // หน่วยนับและจำนวน
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.inventory, size: 16, color: AppTheme.primaryColor),
                      const SizedBox(width: 4),
                      Flexible(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'คงเหลือ: ',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                              ),
                              TextSpan(
                                text: balance.qtyWord,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // ราคา
                if (balance.price != '0')
                  Row(
                    children: [
                      const Icon(Icons.monetization_on_outlined, size: 16, color: AppTheme.primaryColorDark),
                      const SizedBox(width: 4),
                      Text(
                        '${Formatters.formatPrice(balance.price)} บาท',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColorDark,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 4),
            // หน่วยนับ
            Row(
              children: [
                const Icon(Icons.category_outlined, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'หน่วยนับ: ${balance.unitCode}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
