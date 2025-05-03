// lib/ui/screens/return_product/return_product_cart_step.dart
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
            // แสดง SnackBar เพียงครั้งเดียว
            ScaffoldMessenger.of(context).hideCurrentSnackBar(); // ปิด SnackBar ที่แสดงอยู่ก่อน (ถ้ามี)
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('รหัสสินค้า ${product.itemCode} ไม่มีในบิลขายเดิม ไม่สามารถรับคืนได้'),
                backgroundColor: AppTheme.errorColor,
              ),
            );

            _barcodeScanController.clear();

            // รีเซ็ต ProductDetailState เพื่อให้ CircularProgressIndicator หายไป
            if (context.mounted) {
              context.read<ProductDetailBloc>().add(ResetProductDetail());
            }

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

          // เพิ่ม debug print เพื่อตรวจสอบการส่ง event
          print('[DEBUG] Adding item to return cart: ${product.itemCode}');
          context.read<ReturnProductBloc>().add(AddItemToReturnCart(cartItem));

          // Reset text fields
          _barcodeScanController.clear();

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

          _barcodeScanController.clear();
          _barcodeScanFocusNode.requestFocus();
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
          // แถบค้นหาบาร์โค้ดและปุ่มเลือกสินค้า (ปรับปรุงดีไซน์)
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

          // แสดง debug แบบง่ายๆ เพื่อตรวจสอบ state ของ ReturnProductBloc
          BlocBuilder<ReturnProductBloc, ReturnProductState>(
            builder: (context, state) {
              if (state is ReturnProductLoaded) {
                print('[DEBUG] Current return items: ${state.returnItems.length}');
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
                  // TabBar (ปรับปรุงการแสดงผล)
                  _buildTabBar(),

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
      child: Row(
        children: [
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
                  // ในโหมดสแกน ซ่อน keyboard
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.search, size: 18, color: Colors.white),
                      const SizedBox(width: 4),
                      const Text(
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
    );
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
          if (isMaxQuantity) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('ไม่สามารถรับคืนเกินจำนวนในบิล (${qty.toInt()})'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
            return;
          }

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

          // แสดงการแจ้งเตือนให้ผู้ใช้รู้ว่าได้เลือกสินค้านี้แล้ว
          _showAddItemSnackbar(item.itemName);
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
                        if (isMaxQuantity) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('ไม่สามารถรับคืนเกินจำนวนในบิล (${qty.toInt()})'),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                          return;
                        }

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

                        // แสดงการแจ้งเตือนให้ผู้ใช้รู้ว่าได้เลือกสินค้านี้แล้ว
                        _showAddItemSnackbar(item.itemName);
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

  // แสดง SnackBar แจ้งเตือนเมื่อเพิ่มสินค้า
  void _showAddItemSnackbar(String itemName) {
    // ปิด SnackBar ที่แสดงอยู่เดิม (ถ้ามี)
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // แสดง SnackBar ใหม่
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.green, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'เพิ่ม $itemName',
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // สินค้าที่เลือกรับคืน (ปรับปรุงการแสดงผล)
  Widget _buildReturnItemCard(CartItemModel item) {
    final price = double.tryParse(item.price) ?? 0;
    final qty = double.tryParse(item.qty) ?? 0;
    final totalAmount = double.tryParse(item.sumAmount) ?? 0;

    return Card(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Colors.red.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วนบน: รหัส ชื่อสินค้า และปุ่มลบ
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // รหัสสินค้า
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  margin: const EdgeInsets.only(top: 2),
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
                const SizedBox(width: 8),

                // ชื่อสินค้า
                Expanded(
                  child: Text(
                    item.itemName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // ปุ่มลบ
                Container(
                  height: 28,
                  width: 28,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 14),
                    color: Colors.red,
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
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ส่วนกลาง: ควบคุมจำนวน
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

                // ปรับจำนวน
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ปุ่มลด
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
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              bottomLeft: Radius.circular(20),
                            ),
                          ),
                          child: Icon(Icons.remove, size: 14, color: Colors.grey[800]),
                        ),
                      ),

                      // จำนวน
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          qty.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // ปุ่มเพิ่ม
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
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                          ),
                          child: Icon(Icons.add, size: 14, color: Colors.grey[800]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // ส่วนล่าง: ยอดรวม
            Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 2, top: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'รวม: ',
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '฿${_currencyFormat.format(totalAmount)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
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
                  Text(
                    'ยอดรับคืน',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
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
