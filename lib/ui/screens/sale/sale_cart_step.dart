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
import 'package:wawa_vansales/ui/widgets/number_pad_component.dart'; // เพิ่ม import
import 'package:wawa_vansales/utils/global.dart';
import 'package:intl/intl.dart';

class SaleCartStep extends StatefulWidget {
  final List<CartItemModel> cartItems;
  final double totalAmount;
  final VoidCallback onNextStep;
  final VoidCallback onBackStep;
  final bool isFromPreOrder;

  const SaleCartStep({
    super.key,
    required this.cartItems,
    required this.totalAmount,
    required this.onNextStep,
    required this.onBackStep,
    this.isFromPreOrder = false,
  });

  @override
  State<SaleCartStep> createState() => _SaleCartStepState();
}

class _SaleCartStepState extends State<SaleCartStep> {
  // Controllers
  final TextEditingController _barcodeScanController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController(text: '1'); // เพิ่ม controller จำนวน

  final NumberFormat _currencyFormat = NumberFormat('#,##0.00', 'th_TH');

  // Focus nodes
  final FocusNode _barcodeScanFocusNode = FocusNode();

  bool _isProcessingItem = false;
  bool _showNumPad = false; // เพิ่มควบคุมการแสดง numpad

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
    _qtyController.dispose(); // เพิ่มการ dispose controller
    super.dispose();
  }

  void _processBarcode(String barcode) {
    // ถ้าบาร์โค้ดว่างหรือกำลังประมวลผลอยู่แล้ว ให้ไม่ทำอะไร
    if (barcode.isEmpty || _isProcessingItem) return;

    // ตั้งค่า flag ว่ากำลังประมวลผลอยู่
    setState(() {
      _isProcessingItem = true;
    });

    // แยกจำนวนและบาร์โค้ด กรณีที่มีการใช้ *
    int quantity = 1;
    String processedBarcode = barcode;

    try {
      quantity = int.parse(_qtyController.text);
    } catch (e) {
      quantity = 1;
    }

    // บันทึกค่า quantity ที่ใช้
    _qtyController.text = quantity.toString();

    // ส่ง event ไปยัง ProductDetailBloc เพื่อค้นหาสินค้า
    final cartState = context.read<CartBloc>().state;
    if (cartState is CartLoaded && cartState.selectedCustomer != null) {
      context.read<ProductDetailBloc>().add(
            FetchProductByBarcode(
              barcode: processedBarcode,
              customerCode: cartState.selectedCustomer!.code!,
            ),
          );
    }

    // ล้าง controller หลังจากส่งคำขอค้นหาสินค้า
    _barcodeScanController.clear();
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

        // อัพเดทจำนวนจากค่า _qtyController
        try {
          final qty = int.parse(_qtyController.text);
          if (qty > 0) {
            // สร้าง CartItemModel ใหม่โดยใช้ข้อมูลจาก result แต่ปรับ qty
            final updatedItem = CartItemModel(
              itemCode: result.itemCode,
              itemName: result.itemName,
              barcode: result.barcode,
              price: result.price,
              sumAmount: ((double.tryParse(result.price) ?? 0) * qty).toString(),
              unitCode: result.unitCode,
              whCode: result.whCode,
              shelfCode: result.shelfCode,
              ratio: result.ratio,
              standValue: result.standValue,
              divideValue: result.divideValue,
              qty: qty.toString(),
            );
            context.read<CartBloc>().add(AddItemToCart(updatedItem));
          } else {
            context.read<CartBloc>().add(AddItemToCart(result));
          }
        } catch (e) {
          // ถ้าแปลงเป็นตัวเลขไม่ได้ ให้ใช้ค่าเดิม
          context.read<CartBloc>().add(AddItemToCart(result));
        }

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

  // สร้างฟังก์ชันใหม่สำหรับแสดงช่องค้นหาบาร์โค้ดพร้อมช่อง qty
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // ช่อง QTY
              Container(
                width: 70,
                height: 44,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    TextField(
                      controller: _qtyController,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                      ),
                      keyboardType: TextInputType.none,
                      onTap: () {
                        // เมื่อกดที่ช่อง qty ให้แสดง/ซ่อน numpad
                        setState(() {
                          _showNumPad = !_showNumPad;
                        });
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ],
                ),
              ),

              // ช่องค้นหาบาร์โค้ด
              Expanded(
                child: SizedBox(
                  height: 44,
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
                      // ซ่อน numpad เมื่อกดที่ช่องบาร์โค้ด
                      setState(() {
                        _showNumPad = false;
                      });
                      FocusScope.of(context).unfocus();
                    },
                  ),
                ),
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

          // แสดง NumberPad เมื่อ _showNumPad เป็น true
          if (_showNumPad)
            NumberPadComponent(
              onNumberPressed: (number) {
                // จัดการเมื่อกดปุ่มตัวเลข
                setState(() {
                  final currentQty = _qtyController.text;

                  if (currentQty == '1' && number == '0') {
                    // ถ้าค่าปัจจุบันเป็น 1 และกดปุ่ม 0 ให้กลายเป็น 10
                    _qtyController.text = '10';
                  } else if (currentQty == '10' && number == '0') {
                    // ถ้าค่าปัจจุบันเป็น 10 และกดปุ่ม 0 ให้กลายเป็น 100
                    _qtyController.text = '100';
                  } else if (currentQty == '1') {
                    // ถ้าค่าปัจจุบันเป็น 1 (ค่าเริ่มต้น) ให้แทนที่ด้วยตัวเลขใหม่
                    _qtyController.text = number;
                  } else {
                    // กรณีอื่นๆ ให้ต่อท้าย
                    _qtyController.text += number;
                  }
                });
              },
              onClearPressed: () {
                // จัดการเมื่อกดปุ่ม C
                setState(() {
                  _qtyController.text = '1';
                });
              },
            ),
        ],
      ),
    );
  }

  // เพิ่มเมธอด _showQuantityEditDialog
  void _showQuantityEditDialog(BuildContext context, CartItemModel item) {
    // สร้าง controller สำหรับ TextField ใน dialog
    TextEditingController qtyController = TextEditingController(text: (double.tryParse(item.qty) ?? 0).toStringAsFixed(0));
    // แสดง dialog
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('แก้ไขจำนวน'),
            content: TextField(
              controller: qtyController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'จำนวน',
                hintText: 'ระบุจำนวน',
                suffixText: item.unitCode,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton(
                onPressed: () {
                  double? qty = double.tryParse(qtyController.text);
                  if (qty != null && qty > 0) {
                    context.read<CartBloc>().add(
                          UpdateItemQuantity(
                            itemCode: item.itemCode,
                            barcode: item.barcode,
                            unitCode: item.unitCode,
                            quantity: qty,
                          ),
                        );
                    Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('กรุณาระบุจำนวนให้ถูกต้อง'),
                        backgroundColor: AppTheme.errorColor,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
                child: const Text('บันทึก'),
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ProductDetailBloc, ProductDetailState>(
          listenWhen: (previous, current) {
            if (kDebugMode) {
              print('[DEBUG] ProductDetailBloc listener - previous: ${previous.runtimeType}, current: ${current.runtimeType}');
            }
            return current is ProductDetailLoaded || current is ProductDetailNotFound || current is ProductDetailError;
          },
          listener: (context, state) {
            if (state is ProductDetailLoaded) {
              if (kDebugMode) {
                print('[DEBUG] ProductDetailLoaded triggered - product: ${state.product.itemName}');
              }

              // ดึงจำนวนจาก _qtyController
              int quantity = 1;
              try {
                quantity = int.parse(_qtyController.text);
              } catch (e) {
                // หากแปลงเป็นตัวเลขไม่ได้ ใช้ค่าเริ่มต้น
                quantity = 1;
              }

              // สร้าง cartItem โดยกำหนดจำนวนจาก quantity
              final cartItem = CartItemModel(
                itemCode: state.product.itemCode,
                itemName: state.product.itemName,
                barcode: state.product.barcode,
                price: state.product.price,
                sumAmount: ((double.tryParse(state.product.price) ?? 0) * quantity).toString(), // คำนวณยอดรวมตามจำนวน
                unitCode: state.product.unitCode,
                whCode: Global.whCode,
                shelfCode: Global.shiftCode,
                ratio: state.product.ratio,
                standValue: state.product.standValue,
                divideValue: state.product.divideValue,
                qty: quantity.toString(), // กำหนดจำนวนตามที่ระบุ
              );

              if (kDebugMode) {
                print('[DEBUG] Adding to cart: ${cartItem.itemName}, barcode: ${cartItem.barcode}, qty: $quantity');
              }

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

              setState(() {
                _isProcessingItem = false;
              });

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

              setState(() {
                _isProcessingItem = false;
              });

              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  _barcodeScanFocusNode.requestFocus();
                }
              });
            }
          },
        ),
        BlocListener<CartBloc, CartState>(
          listenWhen: (previous, current) {
            if (kDebugMode) {
              print(
                  '[DEBUG] CartBloc listener - previous items: ${previous is CartLoaded ? (previous).items.length : 0}, current items: ${current is CartLoaded ? (current).items.length : 0}');
            }
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

              setState(() {
                _isProcessingItem = false;
                _qtyController.text = '1'; // รีเซ็ตจำนวนกลับเป็น 1 หลังจากเพิ่มสินค้า
              });

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
          if (!widget.isFromPreOrder) _buildSearchBar(),

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

  Widget _buildCartItemCard(CartItemModel item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
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
                        // แสดงจำนวนแบบเดิม
                        InkWell(
                          onTap: () {
                            // เมื่อกดที่จำนวน ให้แสดง dialog สำหรับป้อนจำนวนใหม่
                            _showQuantityEditDialog(context, item);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                Text(
                                  (double.tryParse(item.qty) ?? 0).toStringAsFixed(0),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(Icons.edit, size: 12, color: Colors.grey[400]),
                              ],
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
