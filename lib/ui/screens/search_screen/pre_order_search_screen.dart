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
  final _formKey = GlobalKey<FormState>();

  String _searchQuery = '';
  Timer? _debounce;
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (kDebugMode) {
      print('didChangeDependencies called, customer: ${widget.customerCode}');
    }
  }

  // ฟังก์ชันค้นหาพรีออเดอร์ที่มีหมายเลขเอกสารตรงกับที่ระบุ
  void _searchPreOrder() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isSearching = true;
        _searchQuery = _searchController.text.trim();
        _hasSearched = true;
      });

      context.read<PreOrderBloc>().add(FetchPreOrders(widget.customerCode));

      // เพื่อให้มีการแสดง loading ก่อนที่จะแสดงผลลัพธ์
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isSearching = false;
          });
        }
      });
    }
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
      // ไม่ต้องทำอะไร แค่ให้มี debounce
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
          // ส่วนการค้นหาที่ปรับปรุงใหม่
          _buildSearchSection(),

          // รายการพรีออเดอร์
          Expanded(
            child: _hasSearched ? _buildSearchResults(currencyFormat) : _buildInitialState(),
          ),
        ],
      ),
    );
  }

  // ส่วนค้นหาที่ปรับปรุงใหม่
  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'กรุณาระบุเลขที่เอกสารพรีออเดอร์',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'เลขที่เอกสาร',
                      hintText: 'ระบุเลขที่เอกสารพรีออเดอร์',
                      prefixIcon: const Icon(Icons.receipt_long),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'กรุณาระบุเลขที่เอกสาร';
                      }
                      return null;
                    },
                    enabled: !_isSearching,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSearching ? null : _searchPreOrder,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(80, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.search),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'หมายเหตุ: ระบุเลขที่เอกสารพรีออเดอร์ให้ถูกต้องเพื่อดึงข้อมูล',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // สถานะเริ่มต้นเมื่อยังไม่ได้ค้นหา
  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 72,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'ค้นหาเอกสารพรีออเดอร์',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'กรุณาระบุเลขที่เอกสารพรีออเดอร์และกดค้นหา',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              context.read<PreOrderBloc>().add(FetchPreOrders(widget.customerCode));
              setState(() {
                _hasSearched = true;
                _searchQuery = '';
              });
            },
            icon: const Icon(Icons.list),
            label: const Text('แสดงรายการทั้งหมด'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // แสดงผลลัพธ์การค้นหา
  Widget _buildSearchResults(NumberFormat currencyFormat) {
    return BlocBuilder<PreOrderBloc, PreOrderState>(
      builder: (context, state) {
        if (state is PreOrderLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (state is PreOrdersLoaded) {
          final preOrders = state.preOrders;

          // กรองตามคำค้นหา
          final filteredPreOrders = _searchQuery.isEmpty ? preOrders : preOrders.where((order) => order.docNo.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

          if (filteredPreOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'ไม่พบเอกสารหมายเลข $_searchQuery',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'กรุณาตรวจสอบหมายเลขเอกสารและลองใหม่อีกครั้ง',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      context.read<PreOrderBloc>().add(FetchPreOrders(widget.customerCode));
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    icon: const Icon(Icons.list),
                    label: const Text('แสดงรายการทั้งหมด'),
                  ),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // แสดงจำนวนที่พบ
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  _searchQuery.isEmpty ? 'พบทั้งหมด ${filteredPreOrders.length} รายการ' : 'พบ ${filteredPreOrders.length} รายการสำหรับ "$_searchQuery"',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: filteredPreOrders.length,
                  itemBuilder: (context, index) {
                    final preOrder = filteredPreOrders[index];
                    return _buildPreOrderCard(context, preOrder, currencyFormat);
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'ไม่พบข้อมูล',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          );
        }
      },
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

    // ไฮไลท์การ์ดถ้ามีการค้นหาและตรงกับเอกสารนี้
    final bool isHighlighted = _searchQuery.isNotEmpty && preOrder.docNo.toLowerCase().contains(_searchQuery.toLowerCase());

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      elevation: isHighlighted ? 3 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: isHighlighted ? const BorderSide(color: AppTheme.primaryColor, width: 2) : BorderSide.none,
      ),
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
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Document Number and Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.receipt, size: 20, color: AppTheme.primaryColor),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                preOrder.docNo,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isHighlighted ? AppTheme.primaryColor : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    formattedDate,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '฿${formatter.format(amount)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Button to view details
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PreOrderDetailScreen(
                            docNo: preOrder.docNo,
                            customer: preOrder,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('ดูรายละเอียด'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 0),
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
