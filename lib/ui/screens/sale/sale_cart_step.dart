// lib/ui/screens/sale/sale_cart_step.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wawa_vansales/blocs/cart/cart_bloc.dart';
import 'package:wawa_vansales/blocs/cart/cart_event.dart';
import 'package:wawa_vansales/blocs/cart/cart_state.dart';
import 'package:wawa_vansales/blocs/product_detail/product_detail_bloc.dart';
import 'package:wawa_vansales/blocs/product_detail/product_detail_event.dart';
import 'package:wawa_vansales/blocs/product_detail/product_detail_state.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/models/cart_item_model.dart';
import 'package:wawa_vansales/ui/widgets/custom_button.dart';
import 'package:intl/intl.dart';

class SaleCartStep extends StatefulWidget {
  final List<CartItemModel> cartItems;
  final double totalAmount;
  final VoidCallback onNextStep;
  final VoidCallback onBackStep;

  const SaleCartStep({
    super.key,
    required this.cartItems,
    required this.totalAmount,
    required this.onNextStep,
    required this.onBackStep,
  });

  @override
  State<SaleCartStep> createState() => _SaleCartStepState();
}

class _SaleCartStepState extends State<SaleCartStep> {
  final TextEditingController _barcodeController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat('#,##0.00', 'th_TH');
  final FocusNode _barcodeFocusNode = FocusNode();

  @override
  void dispose() {
    _barcodeController.dispose();
    _barcodeFocusNode.dispose();
    super.dispose();
  }

  void _searchBarcode() {
    if (_barcodeController.text.isNotEmpty) {
      final cartState = context.read<CartBloc>().state;
      if (cartState is CartLoaded && cartState.selectedCustomer != null) {
        context.read<ProductDetailBloc>().add(
              FetchProductByBarcode(
                barcode: _barcodeController.text,
                customerCode: cartState.selectedCustomer!.code!,
              ),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductDetailBloc, ProductDetailState>(
      listener: (context, state) {
        if (state is ProductDetailLoaded) {
          // เพิ่มสินค้าเข้าตะกร้า
          final cartItem = CartItemModel(
            itemCode: state.product.itemCode,
            itemName: state.product.itemName,
            barcode: state.product.barcode,
            price: state.product.price,
            sumAmount: state.product.price,
            unitCode: state.product.unitCode,
            whCode: '',
            shelfCode: '',
            ratio: state.product.ratio,
            standValue: state.product.standValue,
            divideValue: state.product.divideValue,
            qty: '1',
          );

          context.read<CartBloc>().add(AddItemToCart(cartItem));

          // ล้างช่องค้นหาและ reset state
          _barcodeController.clear();
          context.read<ProductDetailBloc>().add(ResetProductDetail());

          // focus กลับไปที่ช่องค้นหา
          _barcodeFocusNode.requestFocus();
        } else if (state is ProductDetailNotFound) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ไม่พบสินค้าที่มีบาร์โค้ด: ${state.barcode}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
          _barcodeController.clear();
          _barcodeFocusNode.requestFocus();
        } else if (state is ProductDetailError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: ${state.message}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      },
      child: Column(
        children: [
          // ช่องค้นหาบาร์โค้ด
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _barcodeController,
                    focusNode: _barcodeFocusNode,
                    decoration: InputDecoration(
                      labelText: 'สแกนบาร์โค้ด',
                      hintText: 'กรอกหรือสแกนบาร์โค้ดสินค้า',
                      prefixIcon: const Icon(Icons.qr_code_scanner),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _searchBarcode(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.search),
                  color: AppTheme.primaryColor,
                  onPressed: _searchBarcode,
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),

          // แสดงสถานะการค้นหา
          BlocBuilder<ProductDetailBloc, ProductDetailState>(
            builder: (context, state) {
              if (state is ProductDetailLoading) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: const LinearProgressIndicator(),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // รายการสินค้าในตะกร้า
          Expanded(
            child: widget.cartItems.isEmpty ? _buildEmptyCart() : _buildCartItemsList(),
          ),

          // ยอดรวมและปุ่มดำเนินการ
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'ไม่มีสินค้าในตะกร้า',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'สแกนบาร์โค้ดเพื่อเพิ่มสินค้า',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.cartItems.length,
      itemBuilder: (context, index) {
        final item = widget.cartItems[index];
        return _buildCartItemCard(item);
      },
    );
  }

  Widget _buildCartItemCard(CartItemModel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.itemName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'รหัส: ${item.itemCode} | บาร์โค้ด: ${item.barcode}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: AppTheme.errorColor,
                  onPressed: () {
                    context.read<CartBloc>().add(RemoveItemFromCart(item.itemCode));
                  },
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                // ราคาต่อหน่วย
                Expanded(
                  child: Text(
                    'ราคา: ${_currencyFormat.format(double.tryParse(item.price) ?? 0)} ฿/${item.unitCode}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                // จำนวน
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        final currentQty = double.tryParse(item.qty) ?? 0;
                        if (currentQty > 1) {
                          context.read<CartBloc>().add(
                                UpdateItemQuantity(item.itemCode, currentQty - 1),
                              );
                        }
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        (double.tryParse(item.qty) ?? 0).toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () {
                        final currentQty = double.tryParse(item.qty) ?? 0;
                        context.read<CartBloc>().add(
                              UpdateItemQuantity(item.itemCode, currentQty + 1),
                            );
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // ยอดรวม
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'รวม: ${_currencyFormat.format(item.totalAmount)} ฿',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ยอดรวมทั้งหมด
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ยอดรวมทั้งหมด:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_currencyFormat.format(widget.totalAmount)} ฿',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // ปุ่มย้อนกลับและถัดไป
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'ย้อนกลับ',
                  onPressed: widget.onBackStep,
                  buttonType: ButtonType.outline,
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: CustomButton(
                  text: 'ชำระเงิน',
                  onPressed: widget.cartItems.isNotEmpty ? widget.onNextStep : null,
                  icon: const Icon(Icons.payment, color: Colors.white),
                  buttonType: ButtonType.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
