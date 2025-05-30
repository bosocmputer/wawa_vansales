// lib/ui/screens/return_product/return_product_cart_step.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wawa_vansales/blocs/product/product_bloc.dart';
import 'package:wawa_vansales/blocs/product/product_event.dart';
import 'package:wawa_vansales/blocs/product/product_state.dart';
import 'package:wawa_vansales/blocs/return_product/return_product_bloc.dart';
import 'package:wawa_vansales/blocs/return_product/return_product_event.dart';
import 'package:wawa_vansales/blocs/return_product/return_product_state.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/models/cart_item_model.dart';
import 'package:wawa_vansales/data/models/return_product/sale_document_detail_model.dart';
import 'package:wawa_vansales/ui/screens/search_screen/product_search_screen.dart';
import 'package:wawa_vansales/ui/widgets/number_pad_component.dart';
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

    // ส่ง event ไปยัง ProductBloc เพื่อค้นหาสินค้า
    context.read<ProductBloc>().add(
          FetchProductReturns(
            searchQuery: processedBarcode,
            custCode: widget.customerCode,
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

      // ค้นหาข้อมูลสินค้าจาก documentDetails
      final originalItem = widget.documentDetails.firstWhere(
        (detail) => detail.itemCode == result.itemCode && detail.unitCode == result.unitCode,
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
          balanceQty: '0',
          returnQty: '0',
        ),
      );

      // ตรวจสอบ balanceQty เพื่อดูว่ามีสินค้าให้รับคืนได้หรือไม่
      final balanceQty = double.tryParse(originalItem.balanceQty) ?? 0;

      if (balanceQty <= 0) {
        // Reset flag หลังจาก delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _isProcessingItem = false;
            });
          }
        });

        return;
      }

      // เพิ่ม debug log แสดงข้อมูล balanceQty และ originalQty
      if (kDebugMode) {
        final originalQty = double.tryParse(originalItem.qty) ?? 0;
        print('[DEBUG] ${result.itemCode} (${result.unitCode}) - balanceQty: $balanceQty, originalQty: $originalQty');
        print('[DEBUG] Original item: ${originalItem.itemCode}, unit: ${originalItem.unitCode}');
        print('[DEBUG] Result item: ${result.itemCode}, unit: ${result.unitCode}');
      }

      // ใช้จำนวนเริ่มต้นเป็น 1
      var qty = 1.0;

      // ตรวจสอบว่าจำนวนที่จะเพิ่มไม่เกิน balanceQty
      if (qty > balanceQty) {
        qty = balanceQty;
      }

      // สร้าง CartItemModel ใหม่โดยใช้ข้อมูลจาก result โดยตรง แต่ใช้ราคาจากเอกสารเดิม
      final cartItem = CartItemModel(
        itemCode: result.itemCode,
        itemName: result.itemName,
        barcode: result.barcode,
        price: originalItem.price, // ใช้ราคาจากเอกสารเดิม
        sumAmount: originalItem.price, // ใช้ราคาจากเอกสารเดิม
        unitCode: result.unitCode,
        whCode: originalItem.whCode,
        shelfCode: originalItem.shelfCode,
        ratio: result.ratio,
        standValue: result.standValue,
        divideValue: result.divideValue,
        qty: qty.toString(),
        refRow: originalItem.refRow,
      );

      // เพิ่ม debug print เมื่อ balanceQty น้อยกว่า qty ในเอกสารขายเดิม
      if (kDebugMode) {
        final docQty = double.tryParse(originalItem.qty) ?? 0;
        if (balanceQty < docQty) {
          print('[DEBUG] สินค้า ${result.itemCode} มี balanceQty ($balanceQty) < originalQty ($docQty)');
        }
      }

      // ตรวจสอบว่าสินค้านี้มีในตะกร้าแล้วหรือไม่
      final existingItemIndex = widget.returnItems.indexWhere((item) => item.itemCode == result.itemCode && item.unitCode == result.unitCode);

      if (existingItemIndex != -1) {
        // Reset flag
        setState(() {
          _isProcessingItem = false;
        });

        return;
      }

      // ส่ง event เฉพาะเมื่อสินค้ามีในบิลขายเดิม, มี balanceQty มากกว่า 0 และยังไม่มีในตะกร้า
      context.read<ReturnProductBloc>().add(AddItemToReturnCart(cartItem));

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
        // BlocListener สำหรับ ProductBloc
        BlocListener<ProductBloc, ProductState>(
          listenWhen: (previous, current) {
            // เพิ่ม debug logs เพื่อตรวจสอบว่า listenWhen ถูกเรียกหรือไม่
            if (kDebugMode) {
              print('[DEBUG] ProductBloc listener - previous: ${previous.runtimeType}, current: ${current.runtimeType}');
            }
            return current is ProductsLoaded || current is ProductsError;
          },
          listener: (context, state) {
            if (state is ProductsLoaded) {
              // เมื่อได้ผลลัพธ์จากการค้นหาสินค้า
              if (state.products.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('ไม่พบสินค้าที่มีบาร์โค้ด: ${_barcodeScanController.text}'),
                    backgroundColor: AppTheme.errorColor,
                    duration: const Duration(seconds: 2),
                  ),
                );

                // รีเซ็ต _isProcessingItem เพื่อให้สามารถสแกนใหม่ได้
                setState(() {
                  _isProcessingItem = false;
                });

                // Set focus กลับไปที่ช่อง scan barcode
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    _barcodeScanFocusNode.requestFocus();
                  }
                });
                return;
              }

              // นำสินค้าแรกจากผลลัพธ์มาใช้
              final product = state.products.first;

              // เช็คว่าสินค้านี้มีในเอกสารขายเดิมหรือไม่ โดยตรวจสอบทั้ง itemCode และ unitCode
              final existsInDoc = widget.documentDetails.any((detail) => detail.itemCode == product.itemCode && detail.unitCode == product.unitCode);

              if (!existsInDoc) {
                // แสดง SnackBar เพียงครั้งเดียว
                ScaffoldMessenger.of(context).hideCurrentSnackBar(); // ปิด SnackBar ที่แสดงอยู่ก่อน (ถ้ามี)
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('รหัสสินค้า ${product.itemCode} หน่วย ${product.unitCode} ไม่มีในบิลขายเดิม ไม่สามารถรับคืนได้'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );

                // Set focus กลับไปที่ช่อง scan barcode เมื่อไม่พบสินค้าในบิลเดิม
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    _barcodeScanFocusNode.requestFocus();
                  }
                });

                // รีเซ็ต _isProcessingItem เพื่อให้สามารถสแกนใหม่ได้
                setState(() {
                  _isProcessingItem = false;
                });

                return;
              }

              // ค้นหาข้อมูลสินค้าจาก documentDetails ที่มี itemCode และ unitCode ตรงกัน
              final originalItem = widget.documentDetails.firstWhere(
                (detail) => detail.itemCode == product.itemCode && detail.unitCode == product.unitCode,
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
                  balanceQty: '0',
                  returnQty: '0',
                ),
              );

              // ตรวจสอบ balanceQty เพื่อดูว่ามีสินค้าให้รับคืนได้หรือไม่
              final balanceQty = double.tryParse(originalItem.balanceQty) ?? 0;

              if (balanceQty <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('สินค้า ${product.itemName} ไม่สามารถรับคืนได้เนื่องจากมียอดคงเหลือเป็น 0'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );

                // รีเซ็ต _isProcessingItem เพื่อให้สามารถสแกนใหม่ได้
                setState(() {
                  _isProcessingItem = false;
                });

                // Set focus กลับไปที่ช่อง scan barcode
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    _barcodeScanFocusNode.requestFocus();
                  }
                });

                return;
              }

              // ใช้จำนวนที่ผู้ใช้ป้อน (ไม่แปลงหน่วย)
              double qty = double.tryParse(_qtyController.text) ?? 1.0;

              // ตรวจสอบว่าจำนวนที่จะเพิ่มไม่เกิน balanceQty
              if (qty > balanceQty) {
                qty = balanceQty;

                // แจ้งเตือนว่าจำนวนถูกปรับลดลงเพื่อให้ไม่เกิน balanceQty
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('จำนวนถูกปรับให้เป็น ${balanceQty.toStringAsFixed(0)} ตามยอดคงเหลือที่รับคืนได้'),
                    backgroundColor: Colors.orange[700],
                    duration: const Duration(seconds: 3),
                  ),
                );
              }

              // สร้าง CartItemModel จากข้อมูลสินค้า แต่ใช้ราคาจากเอกสารเดิม
              final cartItem = CartItemModel(
                itemCode: product.itemCode,
                itemName: product.itemName,
                barcode: product.barcode,
                price: originalItem.price, // ใช้ราคาจากเอกสารเดิม
                sumAmount: originalItem.price, // ใช้ราคาจากเอกสารเดิม
                unitCode: product.unitCode,
                whCode: originalItem.whCode,
                shelfCode: originalItem.shelfCode,
                ratio: product.ratio,
                standValue: product.standValue,
                divideValue: product.divideValue,
                qty: qty.toString(),
                refRow: originalItem.refRow,
              );

              // ตรวจสอบว่าสินค้านี้มีในตะกร้าแล้วหรือไม่
              final existingItemIndex = widget.returnItems.indexWhere((item) => item.itemCode == product.itemCode && item.unitCode == product.unitCode);

              if (existingItemIndex != -1) {
                // ถ้ามีสินค้านี้ในตะกร้าแล้ว ให้แจ้งเตือน
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('สินค้า ${product.itemName} มีในรายการรับคืนแล้ว กรุณาปรับจำนวนในรายการแทน'),
                    backgroundColor: Colors.orange[700],
                    duration: const Duration(seconds: 3),
                  ),
                );

                // รีเซ็ต _isProcessingItem เพื่อให้สามารถสแกนใหม่ได้
                setState(() {
                  _isProcessingItem = false;
                });

                // Set focus กลับไปที่ช่อง scan barcode
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    _barcodeScanFocusNode.requestFocus();
                  }
                });

                return;
              }

              // ส่ง event เพื่อเพิ่มสินค้า เฉพาะเมื่อสินค้ายังไม่มีในตะกร้า
              context.read<ReturnProductBloc>().add(AddItemToReturnCart(cartItem));
            } else if (state is ProductsError) {
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

              // Set focus กลับไปที่ช่อง scan barcode
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  _barcodeScanFocusNode.requestFocus();
                }
              });
            }
          },
        ),

        // BlocListener สำหรับ ReturnProductBloc
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

              // เพิ่ม debug print เพื่อตรวจสอบการอัพเดทของ state
              if (kDebugMode) {
                print('[DEBUG] STATE UPDATED: ReturnItems count: ${state.returnItems.length}');
                for (int i = 0; i < state.returnItems.length; i++) {
                  print('[DEBUG] STATE ReturnItem $i: ${state.returnItems[i].itemCode}, unit: ${state.returnItems[i].unitCode}');
                }
              }

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

  // แถบค้นหาบาร์โค้ดและปุ่มเลือกสินค้า
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
        balanceQty: '0',
        returnQty: '0',
      ),
    );

    final maxReturnQty = double.tryParse(originalItem.qty) ?? 0;
    final balanceQty = double.tryParse(originalItem.balanceQty) ?? 0;

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
                if (balanceQty > 0 && balanceQty < maxReturnQty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'จำนวนที่สามารถรับคืนได้: ${balanceQty.toStringAsFixed(0)} ${item.unitCode}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
                    // ใช้ค่าที่น้อยกว่าระหว่าง qty และ balanceQty
                    final maxAllowedQty = balanceQty > 0 ? (balanceQty < maxReturnQty ? balanceQty : maxReturnQty) : maxReturnQty;

                    // เช็คว่าจำนวนที่รับคืนไม่เกินจำนวนที่อนุญาต
                    if (qty <= maxAllowedQty) {
                      context.read<ReturnProductBloc>().add(
                            UpdateReturnItemQuantity(
                              itemCode: item.itemCode,
                              barcode: item.barcode,
                              unitCode: item.unitCode,
                              quantity: qty,
                            ),
                          );
                      Navigator.of(context).pop();
                    } else {
                      // แสดงข้อความเตือนเมื่อระบุจำนวนเกิน
                      String errorMessage = '';

                      if (balanceQty > 0 && balanceQty < maxReturnQty) {
                        errorMessage = 'ไม่สามารถรับคืนเกินจำนวนคงเหลือ (${balanceQty.toStringAsFixed(0)})';
                      } else {
                        errorMessage = 'ไม่สามารถรับคืนเกินจำนวนในบิลขาย (${maxReturnQty.toStringAsFixed(0)})';
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(errorMessage),
                          backgroundColor: AppTheme.errorColor,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
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

                          // ตรวจสอบว่าจำนวนที่เพิ่มไม่เกินจำนวนที่มีในบิลขาย และไม่เกิน balanceQty
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
                              balanceQty: '0',
                              returnQty: '0',
                            ),
                          );

                          final originalQty = double.tryParse(originalItem.qty) ?? 0;
                          final balanceQty = double.tryParse(originalItem.balanceQty) ?? 0;

                          // ใช้ค่าที่น้อยกว่าระหว่าง qty และ balanceQty
                          final maxAllowedQty = balanceQty > 0 ? (balanceQty < originalQty ? balanceQty : originalQty) : originalQty;

                          if (currentQty < maxAllowedQty) {
                            context.read<ReturnProductBloc>().add(
                                  UpdateReturnItemQuantity(
                                    itemCode: item.itemCode,
                                    barcode: item.barcode,
                                    unitCode: item.unitCode,
                                    quantity: currentQty + 1,
                                  ),
                                );
                          } else {
                            // แสดงข้อความเตือนเมื่อระบุจำนวนเกิน
                            String errorMessage = '';

                            if (balanceQty > 0 && balanceQty < originalQty) {
                              errorMessage = 'ไม่สามารถรับคืนเกินจำนวนคงเหลือ (${balanceQty.toStringAsFixed(0)})';
                            } else {
                              errorMessage = 'ไม่สามารถรับคืนเกินจำนวนในบิลขาย (${originalQty.toStringAsFixed(0)})';
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(errorMessage),
                                backgroundColor: AppTheme.errorColor,
                              ),
                            );
                          }
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
