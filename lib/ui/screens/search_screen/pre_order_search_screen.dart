import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wawa_vansales/blocs/pre_order/pre_order_bloc.dart';
import 'package:wawa_vansales/blocs/pre_order/pre_order_event.dart';
import 'package:wawa_vansales/blocs/pre_order/pre_order_state.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/models/pre_order_model.dart';
import 'package:wawa_vansales/ui/screens/pre_order/pre_order_detail_screen.dart';

class PreOrderSearchScreen extends StatefulWidget {
  final String customerCode;
  final String customerName;

  const PreOrderSearchScreen({
    super.key,
    required this.customerCode,
    required this.customerName,
  });

  @override
  State<PreOrderSearchScreen> createState() => _PreOrderSearchScreenState();
}

class _PreOrderSearchScreenState extends State<PreOrderSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    // โหลดข้อมูลพรีออเดอร์เมื่อเปิดหน้าจอ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PreOrderBloc>().add(FetchPreOrders(widget.customerCode));
    });

    // ตั้งค่าการค้นหา
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // โหลดข้อมูลใหม่ทุกครั้งที่เข้าหน้านี้ ไม่ว่าจะเป็น state ใดก็ตาม
    _loadPreOrders();

    // เพิ่ม debug
    if (kDebugMode) {
      print('didChangeDependencies called, loading orders for customer: ${widget.customerCode}');
    }
  }

  // แยกฟังก์ชันสำหรับโหลดข้อมูลพรีออเดอร์
  void _loadPreOrders() {
    context.read<PreOrderBloc>().add(FetchPreOrders(widget.customerCode));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ค้นหาพร้อม debounce เพื่อลดการเรียก API
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchQuery != _searchController.text) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0.00', 'th_TH');

    return Scaffold(
      appBar: AppBar(
        title: Text('ค้นหาพรีออเดอร์ - ${widget.customerName}'),
      ),
      body: Column(
        children: [
          // ช่องค้นหา
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ค้นหาเอกสาร...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // รายการพรีออเดอร์
          Expanded(
            child: BlocBuilder<PreOrderBloc, PreOrderState>(
              builder: (context, state) {
                if (state is PreOrderLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (state is PreOrdersLoaded) {
                  final preOrders = state.preOrders;

                  // กรองตามคำค้นหา
                  final filteredPreOrders = _searchQuery.isEmpty
                      ? preOrders
                      : preOrders
                          .where((order) => order.docNo.toLowerCase().contains(_searchQuery.toLowerCase()) || order.docDate.toLowerCase().contains(_searchQuery.toLowerCase()))
                          .toList();

                  if (filteredPreOrders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'ไม่พบข้อมูลพรีออเดอร์',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey[700],
                                ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8.0),
                    itemCount: filteredPreOrders.length,
                    itemBuilder: (context, index) {
                      final preOrder = filteredPreOrders[index];
                      return _buildPreOrderCard(context, preOrder, currencyFormat);
                    },
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
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.errorColor,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<PreOrderBloc>().add(FetchPreOrders(widget.customerCode));
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
          ),
        ],
      ),
    );
  }

  Widget _buildPreOrderCard(BuildContext context, PreOrderModel preOrder, NumberFormat formatter) {
    // แปลงวันที่จากรูปแบบ API (2025-04-17) เป็นรูปแบบที่อ่านง่าย (17/04/2025)
    final originalDate = preOrder.docDate;
    String formattedDate = originalDate;

    try {
      final date = DateTime.parse(originalDate);
      formattedDate = DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      // ถ้าแปลงวันที่ไม่ได้ ให้ใช้ค่าเดิม
    }

    final amount = double.tryParse(preOrder.totalAmount) ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PreOrderDetailScreen(
                docNo: preOrder.docNo,
                customer: preOrder,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Document Number and Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt, size: 20, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        preOrder.docNo,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Total Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'มูลค่ารวม:',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${formatter.format(amount)} บาท',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // กดเพื่อดูรายละเอียด
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.primaryColor),
                  SizedBox(width: 4),
                  Text(
                    'กดเพื่อดูรายละเอียด',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
