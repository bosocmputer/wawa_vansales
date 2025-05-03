// lib/ui/screens/return_product/return_product_cart_step.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wawa_vansales/blocs/product_detail/product_detail_bloc.dart';
import 'package:wawa_vansales/blocs/product_detail/product_detail_event.dart';
import 'package:wawa_vansales/blocs/product_detail/product_detail_state.dart';
import 'package:wawa_vansales/blocs/return_product/return_product_bloc.dart';
import 'package:wawa_vansales/blocs/return_product/return_product_event.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/models/cart_item_model.dart';
import 'package:wawa_vansales/data/models/return_product/sale_document_detail_model.dart';
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
  final TextEditingController _barcodeSearchController = TextEditingController();

  final NumberFormat _currencyFormat = NumberFormat('#,##0.00', 'th_TH');

  // Focus nodes สำหรับแต่ละโหมด
  final FocusNode _barcodeScanFocusNode = FocusNode();
  final FocusNode _barcodeSearchFocusNode = FocusNode();

  bool _isProcessingItem = false;

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
    if (barcode.isEmpty || _isProcessingItem) return;

    setState(() {
      _isProcessingItem = true;
    });

    context.read<ProductDetailBloc>().add(
          FetchProductByBarcode(
            barcode: barcode,
            customerCode: widget.customerCode,
          ),
        );

    // รีเซ็ต flag หลังจากระยะเวลาหนึ่ง
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _isProcessingItem = false;
        });
      }
    });
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
          FocusScope.of(context).unfocus();
          await Future.delayed(const Duration(milliseconds: 100));
          SystemChannels.textInput.invokeMethod('TextInput.hide');
          _barcodeScanFocusNode.requestFocus();
        });
      } else {
        // Search Mode
        _barcodeScanController.clear();
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          _barcodeSearchFocusNode.requestFocus();
          await Future.delayed(const Duration(milliseconds: 100));
          SystemChannels.textInput.invokeMethod('TextInput.show');
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductDetailBloc, ProductDetailState>(
      listenWhen: (previous, current) {
        return current is ProductDetailLoaded && previous is! ProductDetailLoaded;
      },
      listener: (context, state) {
        if (state is ProductDetailLoaded) {
          final product = state.product;

          // เช็คว่าสินค้านี้มีในเอกสารขายเดิมหรือไม่
          final existsInDoc = widget.documentDetails.any((detail) => detail.itemCode == product.itemCode);

          if (!existsInDoc) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('รหัสสินค้า ${product.itemCode} ไม่มีในบิลขายเดิม ไม่สามารถรับคืนได้'),
                backgroundColor: AppTheme.errorColor,
              ),
            );

            _barcodeScanController.clear();
            _barcodeSearchController.clear();

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
            whCode: '',
            shelfCode: '',
            ratio: product.ratio,
            standValue: product.standValue,
            divideValue: product.divideValue,
            qty: '1',
          );

          context.read<ReturnProductBloc>().add(AddItemToReturnCart(cartItem));

          // Reset text fields
          _barcodeScanController.clear();
          _barcodeSearchController.clear();

          // Reset product detail state
          if (context.mounted) {
            context.read<ProductDetailBloc>().add(ResetProductDetail());
          }
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
          // เพิ่มข้อความแจ้งเตือนด้านบน
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'เลือกสินค้าที่ต้องการรับคืน โดยสแกนบาร์โค้ดหรือค้นหาสินค้า ระบบจะตรวจสอบว่ามีในบิลการขายเดิมหรือไม่',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // แถบค้นหาบาร์โค้ดและปุ่มเลือกสินค้า
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                // ช่องค้นหาบาร์โค้ด
                Expanded(
                  child: SizedBox(height: 44, child: _isScanMode ? _buildScanTextField() : _buildSearchTextField()),
                ),
                const SizedBox(width: 8),

                // ปุ่มสลับโหมด
                IconButton(
                  onPressed: _switchMode,
                  icon: Icon(_isScanMode ? Icons.search : Icons.qr_code_scanner),
                  tooltip: _isScanMode ? 'สลับเป็นโหมดค้นหา' : 'สลับเป็นโหมดสแกน',
                  color: AppTheme.primaryColor,
                ),
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

          // รายการสินค้าในบิลขายและสินค้าที่เลือกรับคืน
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  // TabBar
                  Material(
                    color: Colors.white,
                    child: TabBar(
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.receipt_long, size: 20),
                              const SizedBox(width: 8),
                              const Text('สินค้าในบิลขาย'),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${widget.documentDetails.length}',
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.shopping_cart, size: 20),
                              const SizedBox(width: 8),
                              const Text('สินค้าที่รับคืน'),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${widget.returnItems.length}',
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // TabBarView
                  Expanded(
                    child: TabBarView(
                      children: [
                        // สินค้าในบิลขาย
                        _buildSaleDocumentItemsList(),

                        // สินค้าที่เลือกรับคืน
                        widget.returnItems.isEmpty ? _buildEmptyReturnCart() : _buildReturnItemsList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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

  Widget _buildEmptyReturnCart() {
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
            'ไม่มีสินค้าในรายการรับคืน',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'สแกนบาร์โค้ดหรือเลือกจากรายการสินค้าในบิลขาย',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleDocumentItemsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: widget.documentDetails.length,
      itemBuilder: (context, index) {
        final item = widget.documentDetails[index];
        return _buildSaleDocumentItemCard(item);
      },
    );
  }

  Widget _buildReturnItemsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: widget.returnItems.length,
      itemBuilder: (context, index) {
        final item = widget.returnItems[index];
        return _buildReturnItemCard(item);
      },
    );
  }

  Widget _buildSaleDocumentItemCard(SaleDocumentDetailModel item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ชื่อสินค้าและปุ่มเพิ่ม
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
                    ],
                  ),
                ),
                // ปุ่มเพิ่มสินค้า
                IconButton(
                  icon: const Icon(Icons.add_circle, size: 22),
                  color: AppTheme.primaryColor,
                  onPressed: () {
                    // Add item to return cart
                    final cartItem = CartItemModel(
                      itemCode: item.itemCode,
                      itemName: item.itemName,
                      barcode: '', // ไม่มีบาร์โค้ดในข้อมูลเอกสารขาย
                      price: item.price,
                      sumAmount: item.price,
                      unitCode: item.unitCode,
                      whCode: item.whCode,
                      shelfCode: item.shelfCode,
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

                // จำนวนที่ซื้อในบิลขาย
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'จำนวน: ${double.tryParse(item.qty)?.toStringAsFixed(0) ?? item.qty}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
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

                          final originalQty = double.tryParse(originalItem.qty) ?? 0;

                          if (currentQty < originalQty) {
                            context.read<ReturnProductBloc>().add(
                                  UpdateReturnItemQuantity(
                                    itemCode: item.itemCode,
                                    barcode: item.barcode,
                                    unitCode: item.unitCode,
                                    quantity: currentQty + 1,
                                  ),
                                );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('ไม่สามารถรับคืนเกินจำนวนในบิลขาย (${originalQty.toStringAsFixed(0)})'),
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
                    color: Colors.red,
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
                    'ยอดรับคืน',
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
                      color: Colors.red,
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
              onPressed: widget.returnItems.isNotEmpty ? widget.onNextStep : null,
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
