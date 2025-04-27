// lib/ui/screens/sale/sale_cart_step.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wawa_vansales/blocs/cart/cart_bloc.dart';
import 'package:wawa_vansales/blocs/cart/cart_event.dart';
import 'package:wawa_vansales/blocs/cart/cart_state.dart';
import 'package:wawa_vansales/blocs/product_detail/product_detail_bloc.dart';
import 'package:wawa_vansales/blocs/product_detail/product_detail_event.dart';
import 'package:wawa_vansales/blocs/product_detail/product_detail_state.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/models/cart_item_model.dart';
import 'package:wawa_vansales/ui/screens/search_screen/product_search_screen.dart';
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
  // Controllers สำหรับแต่ละโหมด
  final TextEditingController _barcodeScanController = TextEditingController();
  final TextEditingController _barcodeSearchController = TextEditingController();

  final NumberFormat _currencyFormat = NumberFormat('#,##0.00', 'th_TH');

  // Focus nodes สำหรับแต่ละโหมด
  final FocusNode _barcodeScanFocusNode = FocusNode();
  final FocusNode _barcodeSearchFocusNode = FocusNode();

  // โหมดปัจจุบัน
  bool _isScanMode = true; // true = scan mode, false = search mode

  @override
  void initState() {
    super.initState();
    // เริ่มต้นด้วยการ focus ที่ช่อง scan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _barcodeScanFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _barcodeScanController.dispose();
    _barcodeSearchController.dispose();
    _barcodeScanFocusNode.dispose();
    _barcodeSearchFocusNode.dispose();
    super.dispose();
  }

  void _processBarcode(String barcode) {
    if (barcode.isNotEmpty) {
      final cartState = context.read<CartBloc>().state;
      if (cartState is CartLoaded && cartState.selectedCustomer != null) {
        context.read<ProductDetailBloc>().add(
              FetchProductByBarcode(
                barcode: barcode,
                customerCode: cartState.selectedCustomer!.code!,
              ),
            );
      }
    }
  }

  void _searchBarcode() {
    _processBarcode(_barcodeSearchController.text);
  }

  void _scanBarcode() {
    _processBarcode(_barcodeScanController.text);
  }

  void _switchMode() {
    setState(() {
      _isScanMode = !_isScanMode;

      if (_isScanMode) {
        // Scan Mode
        _barcodeSearchController.clear();
        _barcodeScanController.clear();

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          FocusScope.of(context).unfocus(); // ละทิ้ง focus ก่อน
          await Future.delayed(const Duration(milliseconds: 100));
          SystemChannels.textInput.invokeMethod('TextInput.hide');
          _barcodeScanFocusNode.requestFocus(); // โฟกัส แต่ไม่เปิดคีย์บอร์ด
        });
      } else {
        // Search Mode
        _barcodeScanController.clear();
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          _barcodeSearchFocusNode.requestFocus(); // โฟกัส TextField
          await Future.delayed(const Duration(milliseconds: 100));
          SystemChannels.textInput.invokeMethod('TextInput.show'); // แล้วค่อยเปิดคีย์บอร์ด
        });
      }
    });
  }

  Future<void> _openProductSearch() async {
    final cartState = context.read<CartBloc>().state;
    if (cartState is CartLoaded && cartState.selectedCustomer != null) {
      final result = await Navigator.of(context).push<CartItemModel?>(
        MaterialPageRoute(
          builder: (_) => ProductSearchScreen(
            customerCode: cartState.selectedCustomer!.code!,
          ),
        ),
      );

      if (result != null && mounted) {
        context.read<CartBloc>().add(AddItemToCart(result));
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
          if (_isScanMode) {
            _barcodeScanController.clear();
            _barcodeScanFocusNode.requestFocus();
          } else {
            _barcodeSearchController.clear();
            _barcodeSearchFocusNode.requestFocus();
          }

          context.read<ProductDetailBloc>().add(ResetProductDetail());
        } else if (state is ProductDetailNotFound) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ไม่พบสินค้าที่มีบาร์โค้ด: ${state.barcode}'),
              backgroundColor: AppTheme.errorColor,
              duration: const Duration(seconds: 2),
            ),
          );

          if (_isScanMode) {
            _barcodeScanController.clear();
            _barcodeScanFocusNode.requestFocus();
          } else {
            _barcodeSearchController.clear();
            _barcodeSearchFocusNode.requestFocus();
          }
        } else if (state is ProductDetailError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: ${state.message}'),
              backgroundColor: AppTheme.errorColor,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Column(
        children: [
          // ช่องค้นหาบาร์โค้ด
          // แถบค้นหาบาร์โค้ดและปุ่มเลือกสินค้า
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: Column(
              children: [
                // แถวบนสุด: ช่องค้นหาและปุ่มเลือกสินค้า
                Row(
                  children: [
                    // ช่องค้นหาบาร์โค้ด
                    Expanded(
                      child: _isScanMode ? _buildScanTextField() : _buildSearchTextField(),
                    ),
                    const SizedBox(width: 8),
                    // ปุ่มเลือกสินค้า (ส่วนที่เพิ่มใหม่)
                    SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: _openProductSearch,
                        icon: const Icon(Icons.search, size: 20),
                        label: const Text('เลือกสินค้า', style: TextStyle(fontSize: 14)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // แถวล่าง: ปุ่มสลับโหมด
                // Row(
                //   children: [
                //     TextButton.icon(
                //       icon: Icon(
                //         _isScanMode ? Icons.keyboard : Icons.qr_code_scanner,
                //         size: 18,
                //       ),
                //       label: Text(
                //         _isScanMode ? 'ค้นหาด้วยคีย์บอร์ด' : 'สแกนบาร์โค้ด',
                //         style: const TextStyle(fontSize: 13),
                //       ),
                //       onPressed: _switchMode,
                //     ),
                //     const Spacer(),
                //     Text(
                //       _isScanMode ? 'โหมดสแกน' : 'โหมดค้นหา',
                //       style: TextStyle(
                //         fontSize: 12,
                //         color: Colors.grey[600],
                //       ),
                //     ),
                //   ],
                // ),
              ],
            ),
          ),
          // แสดงสถานะการค้นหา
          BlocBuilder<ProductDetailBloc, ProductDetailState>(
            builder: (context, state) {
              if (state is ProductDetailLoading) {
                return const LinearProgressIndicator(minHeight: 2);
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

  Widget _buildScanTextField() {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: _barcodeScanController,
        focusNode: _barcodeScanFocusNode,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: 'สแกนบาร์โค้ด',
          labelStyle: const TextStyle(fontSize: 13),
          prefixIcon: const Icon(
            Icons.qr_code_scanner,
            size: 20,
          ),
          suffixIcon: _barcodeScanController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _barcodeScanController.clear();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          isDense: true,
        ),
        keyboardType: TextInputType.none, // ซ่อน keyboard
        onSubmitted: (_) => _scanBarcode(),
        onTap: () {
          // ในโหมดสแกน ซ่อน keyboard
          FocusScope.of(context).unfocus();
        },
      ),
    );
  }

  Widget _buildSearchTextField() {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: _barcodeSearchController,
        focusNode: _barcodeSearchFocusNode,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: 'ค้นหาบาร์โค้ด',
          labelStyle: const TextStyle(fontSize: 13),
          prefixIcon: const Icon(
            Icons.search,
            size: 20,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_barcodeSearchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _barcodeSearchController.clear();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              IconButton(
                icon: const Icon(Icons.search, size: 20),
                onPressed: _searchBarcode,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          isDense: true,
        ),
        keyboardType: TextInputType.text,
        onSubmitted: (_) => _searchBarcode(),
        showCursor: true,
        autofocus: !_isScanMode, // กำหนด autofocus เมื่ออยู่ในโหมดค้นหา
        onTap: () {
          // ทำให้แน่ใจว่า keyboard จะแสดงเมื่อกดที่ช่องค้นหา
          if (!_isScanMode) {
            SystemChannels.textInput.invokeMethod('TextInput.show');
          }
        },
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
            size: 60,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'ไม่มีสินค้าในตะกร้า',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isScanMode ? 'สแกนบาร์โค้ดเพื่อเพิ่มสินค้า' : 'ค้นหาบาร์โค้ดเพื่อเพิ่มสินค้า',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: widget.cartItems.length,
      itemBuilder: (context, index) {
        final item = widget.cartItems[index];
        return _buildCartItemCard(item);
      },
    );
  }

  Widget _buildCartItemCard(CartItemModel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // แถวแรก: ชื่อสินค้าและปุ่มลบ
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
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'รหัส: ${item.itemCode} | บาร์โค้ด: ${item.barcode}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: AppTheme.errorColor,
                  onPressed: () {
                    context.read<CartBloc>().add(RemoveItemFromCart(item.itemCode));
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // แถวที่สอง: ราคา, จำนวน และยอดรวม
            Row(
              children: [
                // ราคาต่อหน่วย
                Expanded(
                  child: Text(
                    '฿${_currencyFormat.format(double.tryParse(item.price) ?? 0)}/${item.unitCode}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                // จำนวนสินค้า
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          final currentQty = double.tryParse(item.qty) ?? 0;
                          if (currentQty > 1) {
                            context.read<CartBloc>().add(
                                  UpdateItemQuantity(item.itemCode, currentQty - 1),
                                );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Icon(Icons.remove, size: 16, color: Colors.grey[700]),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.symmetric(
                            vertical: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Text(
                          (double.tryParse(item.qty) ?? 0).toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          final currentQty = double.tryParse(item.qty) ?? 0;
                          context.read<CartBloc>().add(
                                UpdateItemQuantity(item.itemCode, currentQty + 1),
                              );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Icon(Icons.add, size: 16, color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // ยอดรวม
                Text(
                  '฿${_currencyFormat.format(item.totalAmount)}',
                  style: const TextStyle(
                    fontSize: 14,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
      child: Row(
        children: [
          // ยอดรวมทั้งหมด
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ยอดรวม',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '฿${_currencyFormat.format(widget.totalAmount)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          // ปุ่มกลับ
          SizedBox(
            height: 40,
            child: OutlinedButton(
              onPressed: widget.onBackStep,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('กลับ'),
            ),
          ),
          const SizedBox(width: 8),
          // ปุ่มชำระเงิน
          SizedBox(
            height: 40,
            child: ElevatedButton.icon(
              onPressed: widget.cartItems.isNotEmpty ? widget.onNextStep : null,
              icon: const Icon(Icons.payment, size: 20),
              label: const Text('ชำระเงิน'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
}
