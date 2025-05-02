// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wawa_vansales/blocs/cart/cart_bloc.dart';
import 'package:wawa_vansales/blocs/cart/cart_event.dart';
import 'package:wawa_vansales/blocs/pre_order/pre_order_bloc.dart';
import 'package:wawa_vansales/blocs/pre_order/pre_order_event.dart';
import 'package:wawa_vansales/blocs/pre_order/pre_order_state.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/models/cart_item_model.dart';
import 'package:wawa_vansales/data/models/customer_model.dart';
import 'package:wawa_vansales/data/models/pre_order_model.dart';
import 'package:wawa_vansales/ui/screens/sale/sale_screen.dart';

class PreOrderDetailScreen extends StatefulWidget {
  final String docNo;
  final PreOrderModel customer;

  const PreOrderDetailScreen({
    super.key,
    required this.docNo,
    required this.customer,
  });

  @override
  State<PreOrderDetailScreen> createState() => _PreOrderDetailScreenState();
}

class _PreOrderDetailScreenState extends State<PreOrderDetailScreen> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PreOrderBloc>().add(FetchPreOrderDetail(widget.docNo));
    });
  }

  List<CartItemModel> _convertToCartItems(List<PreOrderDetailModel> items) {
    return items
        .map((item) => CartItemModel(
              itemCode: item.itemCode,
              itemName: item.itemName,
              barcode: '',
              price: item.price,
              sumAmount: item.totalAmount.toString(),
              unitCode: item.unitCode,
              whCode: item.whCode,
              shelfCode: item.shelfCode,
              ratio: item.ratio,
              standValue: item.standValue,
              divideValue: item.divideValue,
              qty: item.qty,
            ))
        .toList();
  }

  void _selectDocument(BuildContext context, List<CartItemModel> cartItems, CustomerModel customer, String docNo) {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    // เคลียร์ตะกร้า
    context.read<CartBloc>().add(ClearCart());

    // เลือกลูกค้า
    context.read<CartBloc>().add(SelectCustomerForCart(customer));

    // เพิ่มสินค้าทั้งหมดเข้าตะกร้าในครั้งเดียว
    context.read<CartBloc>().add(AddItemsToCart(cartItems));

    // ตั้งค่าเอกสารพรีออเดอร์ - ต้องแน่ใจว่าบรรทัดนี้ทำงานถูกต้อง
    context.read<CartBloc>().add(SetPreOrderDocument(docNo));

    // ใช้ Future.delayed เพื่อให้แน่ใจว่า UpdateStep จะถูกประมวลผลหลังจากเหตุการณ์อื่นๆ
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        // สำคัญ! ตั้งค่า step เป็น 1 (หน้าสินค้า) เพื่อให้แสดงผลหน้าตะกร้า
        context.read<CartBloc>().add(const UpdateStep(1));

        // รีเซ็ตสถานะ
        context.read<PreOrderBloc>().add(ResetPreOrderState());

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SaleScreen(
              isFromPreOrder: true,
              startAtCart: true,
              preOrderDocNo: docNo, // ส่งค่า docNo ไปยัง SaleScreen
            ),
          ),
        );

        // ตรวจสอบเพื่อความแน่ใจว่า preOrderDocNo ถูกส่งไปที่ CartBloc
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            context.read<CartBloc>().add(SetPreOrderDocument(docNo));
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0.00', 'th_TH');

    return WillPopScope(
      onWillPop: () async {
        // รีเซ็ตสถานะของ PreOrderBloc เพื่อให้เมื่อกลับไปหน้า PreOrderSearchScreen จะโหลดข้อมูลใหม่
        context.read<PreOrderBloc>().add(ResetPreOrderState());
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('รายละเอียดเอกสาร ${widget.docNo}'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // สลับลำดับ: นำทางกลับก่อน แล้วค่อยรีเซ็ต
              Navigator.of(context).pop();
              // ใช้ Future.microtask เพื่อให้แน่ใจว่า state ถูกรีเซ็ตหลังจากการนำทาง
              Future.microtask(() {
                if (context.mounted) {
                  // ทำการรีเซ็ตสถานะแล้วโหลดข้อมูลใหม่ทันที
                  context.read<PreOrderBloc>().add(ResetPreOrderState());
                  // เพิ่มการเรียกโหลดข้อมูลใหม่ด้วย
                  context.read<PreOrderBloc>().add(FetchPreOrders(widget.customer.custCode));
                }
              });
            },
          ),
        ),
        body: BlocBuilder<PreOrderBloc, PreOrderState>(
          builder: (context, state) {
            if (state is PreOrderDetailLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (state is PreOrderDetailLoaded) {
              final items = state.items;
              final double totalAmount = state.totalAmount;

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[100],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person, color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.customer.custName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.badge, size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              'รหัสลูกค้า: ${widget.customer.custCode}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              'วันที่: ${widget.customer.docDate}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ยอดรวมทั้งสิ้น',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${currencyFormat.format(totalAmount)} บาท',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: items.isEmpty
                        ? const Center(
                            child: Text('ไม่พบรายการสินค้า'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              final price = double.tryParse(item.price) ?? 0;
                              final qty = double.tryParse(item.qty) ?? 0;
                              final total = price * qty;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
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
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    item.itemCode,
                                                    style: const TextStyle(
                                                      color: AppTheme.primaryColor,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            'คลัง: ${item.whCode} / ${item.shelfCode}',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        item.itemName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'ราคา: ${currencyFormat.format(price)} บาท',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade700,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'จำนวน: $qty ${item.unitCode}',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade700,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '${currencyFormat.format(total)} บาท',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            } else if (state is PreOrderError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
                    const SizedBox(height: 16),
                    Text(
                      'เกิดข้อผิดพลาด: ${state.message}',
                      style: const TextStyle(
                        color: AppTheme.errorColor,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<PreOrderBloc>().add(FetchPreOrderDetail(widget.docNo));
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('ลองใหม่'),
                    ),
                  ],
                ),
              );
            } else {
              return const Center(
                child: Text('ไม่พบข้อมูล'),
              );
            }
          },
        ),
        bottomNavigationBar: BlocBuilder<PreOrderBloc, PreOrderState>(
          builder: (context, state) {
            if (state is PreOrderDetailLoaded) {
              final items = state.items;

              return BottomAppBar(
                padding: EdgeInsets.zero,
                height: 80,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'ยอดรวม',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '${currencyFormat.format(state.totalAmount)} บาท',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isProcessing
                            ? null
                            : () {
                                final customer = CustomerModel(
                                  code: widget.customer.custCode,
                                  name: widget.customer.custName,
                                );

                                final cartItems = _convertToCartItems(items);

                                _selectDocument(context, cartItems, customer, widget.docNo);
                              },
                        icon: const Icon(Icons.shopping_cart),
                        label: Text(_isProcessing ? 'กำลังดำเนินการ...' : 'เลือกเอกสาร'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox(height: 0);
          },
        ),
      ),
    );
  }
}
