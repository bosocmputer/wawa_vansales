// lib/ui/screens/sale/sale_cart_step.dart
import 'package:flutter/foundation.dart';
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
import 'package:wawa_vansales/ui/screens/search_screen/product_search_screen.dart';
import 'package:wawa_vansales/utils/global.dart'; // เพิ่ม import Global
import 'package:intl/intl.dart';

class SaleCartStep extends StatefulWidget {
  final List<CartItemModel> cartItems;
  final double totalAmount;
  final VoidCallback onNextStep;
  final VoidCallback onBackStep;
  final bool isFromPreOrder; // เพิ่มตัวแปรเพื่อระบุว่าสินค้ามาจากพรีออเดอร์หรือไม่

  const SaleCartStep({
    super.key,
    required this.cartItems,
    required this.totalAmount,
    required this.onNextStep,
    required this.onBackStep,
    this.isFromPreOrder = false, // ค่าเริ่มต้นเป็น false
  });

  @override
  State<SaleCartStep> createState() => _SaleCartStepState();
}

class _SaleCartStepState extends State<SaleCartStep> {
  // Controllers สำหรับแต่ละโหมด
  final TextEditingController _barcodeScanController = TextEditingController();

  final NumberFormat _currencyFormat = NumberFormat('#,##0.00', 'th_TH');

  // Focus nodes สำหรับแต่ละโหมด
  final FocusNode _barcodeScanFocusNode = FocusNode();

  bool _isProcessingItem = false;

  // โหมดปัจจุบัน

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
    _barcodeScanFocusNode.dispose();
    super.dispose();
  }

  void _processBarcode(String barcode) {
    // ถ้าบาร์โค้ดว่างหรือกำลังประมวลผลอยู่แล้ว ให้ไม่ทำอะไร
    if (barcode.isEmpty || _isProcessingItem) return;

    // ตั้งค่า flag ว่ากำลังประมวลผลอยู่
    setState(() {
      _isProcessingItem = true;
    });

    // ส่ง event ไปยัง ProductDetailBloc เพื่อค้นหาสินค้า
    final cartState = context.read<CartBloc>().state;
    if (cartState is CartLoaded && cartState.selectedCustomer != null) {
      context.read<ProductDetailBloc>().add(
            FetchProductByBarcode(
              barcode: barcode,
              customerCode: cartState.selectedCustomer!.code!,
            ),
          );
    }

    // ล้าง controller หลังจากส่งคำขอค้นหาสินค้า
    _barcodeScanController.clear();

    // หมายเหตุ: ไม่รีเซ็ต _isProcessingItem ที่นี่
    // _isProcessingItem จะถูกรีเซ็ตใน BlocListener เมื่อกระบวนการเสร็จสิ้นจริงๆ แล้ว
  }

  void _scanBarcode() {
    _processBarcode(_barcodeScanController.text);
  }

  Future<void> _openProductSearch() async {
    // ถ้ากำลังประมวลผลอยู่ ให้ออกไป
    if (_isProcessingItem) return;

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
        setState(() {
          _isProcessingItem = true;
        });

        if (kDebugMode) {
          print('Returned from search with item: ${result.itemCode}, qty=${result.qty}');
        }

        // ส่ง event และรอให้เสร็จก่อนกำหนด isProcessingItem เป็น false
        context.read<CartBloc>().add(AddItemToCart(result));

        // Reset flag หลังจาก delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _isProcessingItem = false;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ProductDetailBloc, ProductDetailState>(
          listenWhen: (previous, current) {
            // เพิ่ม debug logs เพื่อตรวจสอบว่า listenWhen ถูกเรียกหรือไม่
            if (kDebugMode) {
              print('[DEBUG] ProductDetailBloc listener - previous: ${previous.runtimeType}, current: ${current.runtimeType}');
            }
            // ให้ทำงานกับทั้ง ProductDetailLoaded และ ProductDetailNotFound
            return current is ProductDetailLoaded || current is ProductDetailNotFound || current is ProductDetailError;
          },
          listener: (context, state) {
            if (state is ProductDetailLoaded) {
              if (kDebugMode) {
                print('[DEBUG] ProductDetailLoaded triggered - product: ${state.product.itemName}');
              }

              // เพิ่มสินค้าเข้าตะกร้าทันทีโดยไม่สนใจ isProcessingItem
              final cartItem = CartItemModel(
                itemCode: state.product.itemCode,
                itemName: state.product.itemName,
                barcode: state.product.barcode,
                price: state.product.price,
                sumAmount: state.product.price,
                unitCode: state.product.unitCode,
                whCode: Global.whCode,
                shelfCode: Global.shiftCode,
                ratio: state.product.ratio,
                standValue: state.product.standValue,
                divideValue: state.product.divideValue,
                qty: '1',
              );

              // ส่ง event เพื่อเพิ่มสินค้า
              if (kDebugMode) {
                print('[DEBUG] Adding to cart: ${cartItem.itemName}, barcode: ${cartItem.barcode}');
              }

              // กำหนด flag ป้องกันการสแกนซ้ำในช่วงประมวลผล
              setState(() {
                _isProcessingItem = true;
              });

              context.read<CartBloc>().add(AddItemToCart(cartItem));

              // เรียก ResetProductDetail หลังเพิ่มสินค้าเข้าตะกร้า
              Future.delayed(const Duration(milliseconds: 100), () {
                if (context.mounted) {
                  context.read<ProductDetailBloc>().add(ResetProductDetail());
                }
              });
            } else if (state is ProductDetailNotFound) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('ไม่พบสินค้าที่มีบาร์โค้ด: ${state.barcode}'),
                  backgroundColor: AppTheme.errorColor,
                  duration: const Duration(seconds: 2),
                ),
              );

              // รีเซ็ต _isProcessingItem เพื่อให้สามารถสแกนใหม่ได้
              setState(() {
                _isProcessingItem = false;
              });

              // Set focus กลับไปที่ช่อง scan barcode เมื่อไม่พบสินค้า
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  _barcodeScanFocusNode.requestFocus();
                }
              });
            } else if (state is ProductDetailError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('เกิดข้อผิดพลาด: ${state.message}'),
                  backgroundColor: AppTheme.errorColor,
                  duration: const Duration(seconds: 2),
                ),
              );

              // รีเซ็ต _isProcessingItem เพื่อให้สามารถสแกนใหม่ได้
              setState(() {
                _isProcessingItem = false;
              });

              // Set focus กลับไปที่ช่อง scan barcode เมื่อเกิดข้อผิดพลาด
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  _barcodeScanFocusNode.requestFocus();
                }
              });
            }
          },
        ),

        // เพิ่ม BlocListener สำหรับ CartBloc เพื่อรับรู้การเปลี่ยนแปลงของรายการสินค้า
        BlocListener<CartBloc, CartState>(
          listenWhen: (previous, current) {
            // เพิ่ม debug logs เพื่อตรวจสอบ CartBloc listener
            if (kDebugMode) {
              print(
                  '[DEBUG] CartBloc listener - previous items: ${previous is CartLoaded ? (previous as CartLoaded).items.length : 0}, current items: ${current is CartLoaded ? (current as CartLoaded).items.length : 0}');
            }
            // เช็คเฉพาะเมื่อเป็น CartLoaded ทั้งคู่ และมีการเปลี่ยนแปลงจำนวนไอเทม
            if (previous is CartLoaded && current is CartLoaded) {
              return previous.items.length != current.items.length || previous.totalAmount != current.totalAmount;
            }
            return false;
          },
          listener: (context, state) {
            if (state is CartLoaded) {
              if (kDebugMode) {
                print('[DEBUG] CartLoaded triggered - items: ${state.items.length}, isProcessingItem: $_isProcessingItem');
              }

              // รีเซ็ต flag เมื่อการเปลี่ยนแปลงสินค้าเสร็จสมบูรณ์
              setState(() {
                _isProcessingItem = false;
              });

              // ตั้งโฟกัสกลับไปที่ช่องสแกนบาร์โค้ดเพื่อให้สามารถสแกนรายการต่อไปได้ทันที
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  _barcodeScanFocusNode.requestFocus();
                }
              });
            }
          },
        ),
      ],
      child: Column(
        children: [
          // แถบค้นหาบาร์โค้ดและปุ่มเลือกสินค้า - ซ่อนเมื่อเป็น PreOrder
          if (!widget.isFromPreOrder)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Row(
                children: [
                  // ช่องค้นหาบาร์โค้ด
                  Expanded(
                    child: SizedBox(height: 44, child: _buildScanTextField()),
                  ),
                  const SizedBox(width: 8),

                  // ปุ่มเลือกสินค้า
                  SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: _openProductSearch,
                      icon: const Icon(Icons.search, size: 20),
                      label: const Text('เลือกสินค้า'),
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
            ),
          // แสดงสถานะการค้นหา เฉพาะเมื่อไม่ใช่ PreOrder
          if (!widget.isFromPreOrder)
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
            'สแกนบาร์โค้ดเพื่อเพิ่มสินค้า',
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

// ใน _buildCartItemCard อาจเพิ่มการแสดงข้อมูลบาร์โค้ดและหน่วยนับ
  Widget _buildCartItemCard(CartItemModel item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ชื่อสินค้าและปุ่มลบ
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
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'รหัส: ${item.itemCode}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      // เพิ่มการแสดงบาร์โค้ด
                      Text(
                        'บาร์โค้ด: ${item.barcode}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!widget.isFromPreOrder) // ไม่แสดงปุ่มลบหากมาจากพรีออเดอร์
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 22),
                    color: AppTheme.errorColor,
                    onPressed: () {
                      context.read<CartBloc>().add(RemoveItemFromCart(
                            itemCode: item.itemCode,
                            barcode: item.barcode,
                            unitCode: item.unitCode,
                          ));
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // ราคา, จำนวน และยอดรวม
            Row(
              children: [
                // ราคาต่อหน่วย
                Expanded(
                  child: Text(
                    '฿${_currencyFormat.format(double.tryParse(item.price) ?? 0)}/${item.unitCode}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),

                // ปรับจำนวน
                if (!widget.isFromPreOrder) // ไม่แสดงการปรับจำนวนหากมาจากพรีออเดอร์
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
                                    UpdateItemQuantity(
                                      itemCode: item.itemCode,
                                      barcode: item.barcode,
                                      unitCode: item.unitCode,
                                      quantity: currentQty - 1,
                                    ),
                                  );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(Icons.remove, size: 18, color: Colors.grey[700]),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            (double.tryParse(item.qty) ?? 0).toStringAsFixed(0),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            final currentQty = double.tryParse(item.qty) ?? 0;
                            context.read<CartBloc>().add(
                                  UpdateItemQuantity(
                                    itemCode: item.itemCode,
                                    barcode: item.barcode,
                                    unitCode: item.unitCode,
                                    quantity: currentQty + 1,
                                  ),
                                );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(Icons.add, size: 18, color: Colors.grey[700]),
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
      padding: const EdgeInsets.all(12),
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
      child: SafeArea(
        child: Row(
          children: [
            // ยอดรวม
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ยอดรวม',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '฿${_currencyFormat.format(widget.totalAmount)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            // ปุ่มกลับและถัดไป
            OutlinedButton(
              onPressed: widget.onBackStep,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(80, 44),
              ),
              child: const Text('กลับ'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: widget.cartItems.isNotEmpty ? widget.onNextStep : null,
              icon: const Icon(Icons.payment, size: 20),
              label: const Text('ชำระเงิน'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(120, 44),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
