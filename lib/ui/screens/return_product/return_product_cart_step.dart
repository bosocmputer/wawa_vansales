// lib/ui/screens/return_product/return_product_cart_step.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wawa_vansales/blocs/product_detail/product_detail_bloc.dart';
import 'package:wawa_vansales/blocs/product_detail/product_detail_event.dart';
import 'package:wawa_vansales/blocs/product_detail/product_detail_state.dart';
import 'package:wawa_vansales/blocs/return_product/return_product_bloc.dart';
import 'package:wawa_vansales/blocs/return_product/return_product_event.dart';
import 'package:wawa_vansales/blocs/return_product/return_product_state.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/models/cart_item_model.dart';
import 'package:wawa_vansales/data/models/return_product/sale_document_detail_model.dart';
import 'package:wawa_vansales/ui/screens/search_screen/product_search_screen.dart';
import 'package:wawa_vansales/ui/widgets/number_pad_component.dart';
import 'package:wawa_vansales/utils/global.dart'; // เพิ่ม import Global
import 'package:intl/intl.dart';

class ReturnProductCartStep extends StatefulWidget {
  final List<CartItemModel> returnItems;
  final List<SaleDocumentDetailModel> documentDetails;
  final double totalAmount;
  final VoidCallback onNextStep;
  final VoidCallback onBackStep;
  final String customerCode;

  const ReturnProductCartStep({
    super.key,
    required this.returnItems,
    required this.documentDetails,
    required this.totalAmount,
    required this.onNextStep,
    required this.onBackStep,
    required this.customerCode,
  });

  @override
  State<ReturnProductCartStep> createState() => _ReturnProductCartStepState();
}

class _ReturnProductCartStepState extends State<ReturnProductCartStep> {
  // Controllers สำหรับแต่ละโหมด
  final TextEditingController _barcodeScanController = TextEditingController();

  final NumberFormat _currencyFormat = NumberFormat('#,##0.00', 'th_TH');

  // Focus nodes สำหรับแต่ละโหมด
  final FocusNode _barcodeScanFocusNode = FocusNode();

  bool _isProcessingItem = false;

  final TextEditingController _qtyController = TextEditingController(text: '1');
  bool _showNumPad = false; // เพิ่ม state ควบคุมการแสดง/ซ่อน numpad

  @override
  void initState() {
    super.initState();
    _qtyController.text = '1'; // ตั้งค่าเริ่มต้นเป็น 1
    // เริ่มต้นด้วยการ focus ที่ช่อง scan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _barcodeScanFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _qtyController.dispose(); // เพิ่มการ dispose controller
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

    // แยกจำนวนและบาร์โค้ด กรณีที่มีการใช้ *
    int quantity = 1;
    String processedBarcode = barcode;

    try {
      quantity = int.parse(_qtyController.text);
    } catch (e) {
      quantity = 1;
    }

    // ใช้ค่า quantity ที่ได้
    _qtyController.text = quantity.toString();

    // ส่ง event ไปยัง ProductDetailBloc เพื่อค้นหาสินค้า
    context.read<ProductDetailBloc>().add(
          FetchProductByBarcode(
            barcode: processedBarcode,
            customerCode: widget.customerCode,
          ),
        );

    _barcodeScanController.clear();
  }

  void _scanBarcode() {
    _processBarcode(_barcodeScanController.text);
  }

  Future<void> _openProductSearch() async {
    // ถ้ากำลังประมวลผลอยู่ ให้ออกไป
    if (_isProcessingItem) return;

    if (widget.customerCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกลูกค้าก่อน'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final result = await Navigator.of(context).push<CartItemModel?>(
      MaterialPageRoute(
        builder: (_) => ProductSearchScreen(
          customerCode: widget.customerCode,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _isProcessingItem = true;
      });

      // เช็คว่าสินค้านี้มีในเอกสารขายเดิมหรือไม่
      final existsInDoc = widget.documentDetails.any((detail) => detail.itemCode == result.itemCode);

      if (!existsInDoc) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('รหัสสินค้า ${result.itemCode} ไม่มีในบิลขายเดิม ไม่สามารถรับคืนได้'),
            backgroundColor: AppTheme.errorColor,
          ),
        );

        // Reset flag หลังจาก delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _isProcessingItem = false;
            });
          }
        });

        return; // ออกจากฟังก์ชันเลย ไม่ส่ง event
      }

      // ส่ง event เฉพาะเมื่อสินค้ามีในบิลขายเดิม
      context.read<ReturnProductBloc>().add(AddItemToReturnCart(result));

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

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // BlocListener สำหรับ ProductDetailBloc
        BlocListener<ProductDetailBloc, ProductDetailState>(
          listenWhen: (previous, current) {
            // เพิ่ม debug logs เพื่อตรวจสอบว่า listenWhen ถูกเรียกหรือไม่
            if (kDebugMode) {
              print('[DEBUG] ProductDetailBloc listener - previous: ${previous.runtimeType}, current: ${current.runtimeType}');
            }
            // ให้ทำงานกับทั้ง ProductDetailLoaded, ProductDetailNotFound และ ProductDetailError
            return current is ProductDetailLoaded || current is ProductDetailNotFound || current is ProductDetailError;
          },
          listener: (context, state) {
            if (state is ProductDetailLoaded) {
              final product = state.product;

              // เช็คว่าสินค้านี้มีในเอกสารขายเดิมหรือไม่
              final existsInDoc = widget.documentDetails.any((detail) => detail.itemCode == product.itemCode);

              if (!existsInDoc) {
                // แสดง SnackBar เพียงครั้งเดียว
                ScaffoldMessenger.of(context).hideCurrentSnackBar(); // ปิด SnackBar ที่แสดงอยู่ก่อน (ถ้ามี)
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('รหัสสินค้า ${product.itemCode} ไม่มีในบิลขายเดิม ไม่สามารถรับคืนได้'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );

                // Set focus กลับไปที่ช่อง scan barcode เมื่อไม่พบสินค้าในบิลเดิม
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    _barcodeScanFocusNode.requestFocus();
                  }
                });

                // รีเซ็ต ProductDetailState เพื่อให้ CircularProgressIndicator หายไป
                if (context.mounted) {
                  context.read<ProductDetailBloc>().add(ResetProductDetail());
                }

                // รีเซ็ต _isProcessingItem เพื่อให้สามารถสแกนใหม่ได้
                setState(() {
                  _isProcessingItem = false;
                });

                return;
              }

              // เพิ่มสินค้าเข้าตะกร้า
              final cartItem = CartItemModel(
                itemCode: product.itemCode,
                itemName: product.itemName,
                barcode: product.barcode,
                price: product.price,
                sumAmount: product.price,
                unitCode: product.unitCode,
                whCode: Global.whCode, // ใช้ค่า whCode จาก Global
                shelfCode: Global.shiftCode, // ใช้ค่า shiftCode จาก Global
                ratio: product.ratio,
                standValue: product.standValue,
                divideValue: product.divideValue,
                qty: '1',
              );

              // เพิ่ม debug print เพื่อตรวจสอบการส่ง event (เฉพาะใน debug mode)
              if (kDebugMode) {
                print('[DEBUG] Adding item to return cart: ${product.itemCode}');
              }

              // ส่ง event เพื่อเพิ่มสินค้า
              context.read<ReturnProductBloc>().add(AddItemToReturnCart(cartItem));

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

        // BlocListener สำหรับ ReturnProductBloc เพื่อติดตามการเปลี่ยนแปลงของรายการสินค้า
        BlocListener<ReturnProductBloc, ReturnProductState>(
          listenWhen: (previous, current) {
            // ตรวจสอบเมื่อเป็น ReturnProductLoaded ทั้งคู่ และมีการเปลี่ยนแปลงจำนวนไอเทมหรือยอดรวม
            if (previous is ReturnProductLoaded && current is ReturnProductLoaded) {
              return previous.returnItems.length != current.returnItems.length || previous.totalAmount != current.totalAmount;
            }
            return false;
          },
          listener: (context, state) {
            if (state is ReturnProductLoaded) {
              // รีเซ็ต flag เพื่อให้สามารถสแกนสินค้าถัดไปได้
              setState(() {
                _isProcessingItem = false;
              });

              // ตั้งโฟกัสกลับไปที่ช่องสแกนบาร์โค้ด
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  _barcodeScanFocusNode.requestFocus();
                }
              });

              // อาจเพิ่มการแสดง Snackbar เมื่อเพิ่มสินค้าสำเร็จ (เป็นตัวเลือก)
              if (kDebugMode) {
                print('[DEBUG] ReturnCart updated: ${state.returnItems.length} items, total: ${state.totalAmount}');
              }
            }
          },
        ),
      ],
      child: Column(
        children: [
          // แถบค้นหาบาร์โค้ดและปุ่มเลือกสินค้า
          _buildSearchBar(),

          // แสดงสถานะการค้นหา
          BlocBuilder<ProductDetailBloc, ProductDetailState>(
            builder: (context, state) {
              if (state is ProductDetailLoading) {
                return const LinearProgressIndicator(minHeight: 2);
              }
              return const SizedBox.shrink();
            },
          ),
          // แสดง debug แบบง่ายๆ เพื่อตรวจสอบ state ของ ReturnProductBloc เฉพาะใน debug mode
          if (kDebugMode)
            BlocBuilder<ReturnProductBloc, ReturnProductState>(
              builder: (context, state) {
                if (state is ReturnProductLoaded) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
                    color: Colors.grey[200],
                    child: Text(
                      '[DEBUG] รายการรับคืน: ${state.returnItems.length} รายการ',
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

          // รายการสินค้าที่เลือกรับคืน
          Expanded(
            child: widget.returnItems.isEmpty ? _buildEmptyReturnCart() : _buildReturnItemsList(),
          ),

          // ยอดรวมและปุ่มดำเนินการ (ปรับปรุงดีไซน์)
          _buildBottomActions(),
        ],
      ),
    );
  }

  // แถบค้นหาบาร์โค้ดและปุ่มเลือกสินค้า (ปรับปรุง)
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // ช่อง QTY
              Container(
                width: 70,
                height: 40,
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

              // ช่องค้นหาบาร์โค้ด (ปรับปรุงการแสดงผล)
              Expanded(
                child: SizedBox(
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
                        size: 18,
                      ),
                      suffixIcon: _barcodeScanController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _barcodeScanController.clear();
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
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

              // ปุ่มเลือกสินค้า (ปรับปรุงรูปแบบปุ่ม)
              Container(
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor.withOpacity(0.9), AppTheme.primaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _openProductSearch,
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Icon(Icons.search, size: 18, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'เลือกสินค้า',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
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

  // เพิ่มเมธอด _showQuantityEditDialog ใน ReturnProductCartStep
  void _showQuantityEditDialog(BuildContext context, CartItemModel item) {
    // สร้าง controller สำหรับ TextField ใน dialog
    TextEditingController qtyController = TextEditingController(text: (double.tryParse(item.qty) ?? 0).toStringAsFixed(0));

    // ค้นหารายการในเอกสารขายเดิมเพื่อเช็คจำนวนสูงสุดที่รับคืนได้
    final originalItem = widget.documentDetails.firstWhere(
      (detail) => detail.itemCode == item.itemCode && detail.unitCode == item.unitCode,
      orElse: () => SaleDocumentDetailModel(
        itemCode: '',
        itemName: '',
        unitCode: '',
        price: '0',
        qty: '0',
        whCode: '',
        shelfCode: '',
        standValue: '0',
        divideValue: '0',
        ratio: '0',
        refRow: '0',
      ),
    );

    final maxReturnQty = double.tryParse(originalItem.qty) ?? 0;

    // แสดง dialog
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('แก้ไขจำนวนรับคืน'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'สินค้า: ${item.itemName}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'จำนวนในบิลขาย: ${maxReturnQty.toStringAsFixed(0)} ${item.unitCode}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'จำนวนรับคืน',
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
              ],
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
                    context.read<ReturnProductBloc>().add(
                          UpdateReturnItemQuantity(
                            itemCode: item.itemCode,
                            barcode: item.barcode,
                            unitCode: item.unitCode,
                            quantity: qty,
                          ),
                        );
                    Navigator.of(context).pop();
                    // เช็คว่าจำนวนที่รับคืนไม่เกินจำนวนในบิลขาย
                    // if (qty <= maxReturnQty) {
                    //   context.read<ReturnProductBloc>().add(
                    //         UpdateReturnItemQuantity(
                    //           itemCode: item.itemCode,
                    //           barcode: item.barcode,
                    //           unitCode: item.unitCode,
                    //           quantity: qty,
                    //         ),
                    //       );
                    //   Navigator.of(context).pop();
                    // } else {
                    //   // แสดงข้อความเตือนเมื่อระบุจำนวนเกิน
                    //   ScaffoldMessenger.of(context).showSnackBar(
                    //     SnackBar(
                    //       content: Text('ไม่สามารถรับคืนเกินจำนวนในบิลขาย (${maxReturnQty.toStringAsFixed(0)})'),
                    //       backgroundColor: AppTheme.errorColor,
                    //       duration: const Duration(seconds: 2),
                    //     ),
                    // );
                    // }
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

  // TabBar (ปรับปรุง)
  Widget _buildTabBar() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: TabBar(
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: AppTheme.primaryColor,
        indicatorWeight: 3,
        dividerHeight: 0,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.receipt_long, size: 16),
                const SizedBox(width: 6),
                const Text('สินค้าในบิล', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.documentDetails.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_cart, size: 16),
                const SizedBox(width: 6),
                const Text('รับคืน', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.returnItems.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyReturnCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 10),
          Text(
            'ไม่มีสินค้าในรายการรับคืน',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'สแกนบาร์โค้ดหรือเลือกจากรายการสินค้าในบิลขาย',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSaleDocumentItemsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: widget.documentDetails.length,
      itemBuilder: (context, index) {
        final item = widget.documentDetails[index];
        return _buildSaleDocumentItemCard(item);
      },
    );
  }

  Widget _buildReturnItemsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: widget.returnItems.length,
      itemBuilder: (context, index) {
        final item = widget.returnItems[index];
        return _buildReturnItemCard(item);
      },
    );
  }

  // สินค้าในบิลขาย (ปรับปรุงการแสดงผล)
  Widget _buildSaleDocumentItemCard(SaleDocumentDetailModel item) {
    final price = double.tryParse(item.price) ?? 0;
    final qty = double.tryParse(item.qty) ?? 0;

    // เช็คว่าสินค้านี้ถูกเลือกอยู่ในรายการรับคืนหรือไม่ (เช็คทั้งรหัสสินค้าและหน่วยนับ)
    bool isInReturnCart = widget.returnItems.any((returnItem) => returnItem.itemCode == item.itemCode && returnItem.unitCode == item.unitCode);

    // จำนวนที่เลือกไปแล้ว
    int selectedQty = 0;
    if (isInReturnCart) {
      final selectedItem = widget.returnItems.firstWhere(
        (returnItem) => returnItem.itemCode == item.itemCode && returnItem.unitCode == item.unitCode,
        orElse: () => CartItemModel(
          itemCode: '',
          itemName: '',
          barcode: '',
          price: '',
          sumAmount: '',
          unitCode: '',
          whCode: '',
          shelfCode: '',
          ratio: '',
          standValue: '',
          divideValue: '',
          qty: '0',
        ),
      );
      selectedQty = (double.tryParse(selectedItem.qty) ?? 0).toInt();
    }

    // เช็คว่าเลือกครบจำนวนในบิลแล้วหรือยัง
    bool isMaxQuantity = selectedQty >= qty.toInt();

    return Card(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      elevation: 1,
      // เปลี่ยนสีขอบการ์ดถ้าถูกเลือกแล้ว
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isInReturnCart ? BorderSide(color: Colors.green.shade300, width: 1.5) : BorderSide.none,
      ),
      // เพิ่มสีพื้นหลังอ่อนๆ ถ้าถูกเลือกแล้ว
      color: isInReturnCart ? Colors.green.shade50 : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          // เพิ่มสินค้าเข้าตะกร้าเมื่อกดที่การ์ด (เช็คก่อนว่าเลือกเกินหรือยัง)
          // if (isMaxQuantity) {
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     SnackBar(
          //       content: Text('ไม่สามารถรับคืนเกินจำนวนในบิล (${qty.toInt()})'),
          //       backgroundColor: AppTheme.errorColor,
          //     ),
          //   );
          //   return;
          // }

          final cartItem = CartItemModel(
            itemCode: item.itemCode,
            itemName: item.itemName,
            barcode: '', // ไม่มีบาร์โค้ดในข้อมูลเอกสารขาย
            price: item.price,
            sumAmount: item.price,
            unitCode: item.unitCode,
            whCode: Global.whCode, // ใช้ค่า whCode จาก Global
            shelfCode: Global.shiftCode, // ใช้ค่า shiftCode จาก Global
            ratio: item.ratio,
            standValue: item.standValue,
            divideValue: item.divideValue,
            qty: '1',
          );

          context.read<ReturnProductBloc>().add(AddItemToReturnCart(cartItem));
        },
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ส่วนซ้าย: ปุ่มเพิ่ม (เปลี่ยนไอคอนถ้าถูกเลือกแล้ว)
                  Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      color: isInReturnCart ? Colors.green.withOpacity(0.2) : AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        isInReturnCart ? Icons.add_shopping_cart : Icons.add,
                        size: 16,
                      ),
                      color: isInReturnCart ? Colors.green : AppTheme.primaryColor,
                      onPressed: () {
                        // เพิ่มสินค้าเข้าตะกร้า (เช็คก่อนว่าเลือกเกินหรือยัง)
                        // if (isMaxQuantity) {
                        //   ScaffoldMessenger.of(context).showSnackBar(
                        //     SnackBar(
                        //       content: Text('ไม่สามารถรับคืนเกินจำนวนในบิล (${qty.toInt()})'),
                        //       backgroundColor: AppTheme.errorColor,
                        //     ),
                        //   );
                        //   return;
                        // }

                        final cartItem = CartItemModel(
                          itemCode: item.itemCode,
                          itemName: item.itemName,
                          barcode: '', // ไม่มีบาร์โค้ดในข้อมูลเอกสารขาย
                          price: item.price,
                          sumAmount: item.price,
                          unitCode: item.unitCode,
                          whCode: Global.whCode, // ใช้ค่า whCode จาก Global
                          shelfCode: Global.shiftCode, // ใช้ค่า shiftCode จาก Global
                          ratio: item.ratio,
                          standValue: item.standValue,
                          divideValue: item.divideValue,
                          qty: '1',
                        );

                        context.read<ReturnProductBloc>().add(AddItemToReturnCart(cartItem));
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // ส่วนกลาง: รายละเอียดสินค้า
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // รหัสสินค้า
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                item.itemCode,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            const Spacer(),
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
                        const SizedBox(height: 4),

                        // ชื่อสินค้า
                        Text(
                          item.itemName,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            // เปลี่ยนสีข้อความถ้าถูกเลือกแล้ว
                            color: isInReturnCart ? Colors.green.shade700 : Colors.black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // ราคาและจำนวน
                        Row(
                          children: [
                            // ราคาต่อหน่วย
                            Text(
                              '฿${_currencyFormat.format(price)}/${item.unitCode}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const Spacer(),
                            // จำนวน
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade100, width: 1),
                              ),
                              child: Text(
                                'จำนวน: ${qty.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // แสดงจำนวนที่เลือกไปแล้วที่มุมขวาบน
            if (isInReturnCart)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isMaxQuantity ? Colors.red : Colors.green,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                  child: Text(
                    'เลือกแล้ว $selectedQty/${qty.toInt()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // สินค้าที่เลือกรับคืน (ปรับปรุงการแสดงผล)
  Widget _buildReturnItemCard(CartItemModel item) {
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
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 22),
                  color: AppTheme.errorColor,
                  onPressed: () {
                    context.read<ReturnProductBloc>().add(RemoveItemFromReturnCart(
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
                            context.read<ReturnProductBloc>().add(
                                  UpdateReturnItemQuantity(
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
                      // แสดงจำนวนและไอคอนแก้ไข
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

                          // ตรวจสอบว่าจำนวนที่เพิ่มไม่เกินจำนวนที่มีในบิลขาย
                          final originalItem = widget.documentDetails.firstWhere(
                            (detail) => detail.itemCode == item.itemCode && detail.unitCode == item.unitCode,
                            orElse: () => SaleDocumentDetailModel(
                              itemCode: '',
                              itemName: '',
                              unitCode: '',
                              price: '0',
                              qty: '0',
                              whCode: '',
                              shelfCode: '',
                              standValue: '0',
                              divideValue: '0',
                              ratio: '0',
                              refRow: '0',
                            ),
                          );

                          context.read<ReturnProductBloc>().add(
                                UpdateReturnItemQuantity(
                                  itemCode: item.itemCode,
                                  barcode: item.barcode,
                                  unitCode: item.unitCode,
                                  quantity: currentQty + 1,
                                ),
                              );

                          // final originalQty = double.tryParse(originalItem.qty) ?? 0;

                          // if (currentQty < originalQty) {
                          //   context.read<ReturnProductBloc>().add(
                          //         UpdateReturnItemQuantity(
                          //           itemCode: item.itemCode,
                          //           barcode: item.barcode,
                          //           unitCode: item.unitCode,
                          //           quantity: currentQty + 1,
                          //         ),
                          //       );
                          // } else {
                          //   ScaffoldMessenger.of(context).showSnackBar(
                          //     SnackBar(
                          //       content: Text('ไม่สามารถรับคืนเกินจำนวนในบิลขาย (${originalQty.toStringAsFixed(0)})'),
                          //       backgroundColor: AppTheme.errorColor,
                          //     ),
                          //   );
                          // }
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

  // ส่วนล่าง: ยอดรวมและปุ่มดำเนินการ (ปรับปรุง)
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
                  Row(
                    children: [
                      Text(
                        'ยอดรับคืน',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 4),
                      // แสดงจำนวนรายการ
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${widget.returnItems.length} รายการ',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '฿${_currencyFormat.format(widget.totalAmount)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
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
              onPressed: widget.returnItems.isNotEmpty ? widget.onNextStep : null,
              icon: const Icon(Icons.arrow_forward, size: 20),
              label: const Text('ถัดไป'),
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
