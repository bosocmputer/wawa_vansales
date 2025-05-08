// lib/ui/screens/return_product_history/return_product_history_list_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wawa_vansales/blocs/return_product_history/return_product_history_bloc.dart';
import 'package:wawa_vansales/blocs/return_product_history/return_product_history_event.dart';
import 'package:wawa_vansales/blocs/return_product_history/return_product_history_state.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/models/return_product/return_product_history_model.dart';
import 'package:wawa_vansales/ui/screens/return_product_history/return_product_history_detail_screen.dart';
import 'package:wawa_vansales/ui/screens/warehouse/emty_state_widget.dart';

class ReturnProductHistoryListScreen extends StatefulWidget {
  const ReturnProductHistoryListScreen({super.key});

  @override
  State<ReturnProductHistoryListScreen> createState() => _ReturnProductHistoryListScreenState();
}

class _ReturnProductHistoryListScreenState extends State<ReturnProductHistoryListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  final _dateFormat = DateFormat('dd/MM/yyyy');

  String _searchQuery = '';
  Timer? _debounce;

  // วันที่เริ่มต้นและสิ้นสุด
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    // เมื่อเปิดหน้าจอ ให้โหลดข้อมูลประวัติการรับคืนสินค้าของวันนี้
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReturnProductHistory();
    });

    // ตั้งค่า listener สำหรับการค้นหา
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // ตรวจสอบว่าหน้านี้คือหน้าปัจจุบันที่กำลังแสดงหรือไม่
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      // โหลดข้อมูลใหม่ทันทีเมื่อกลับมาที่หน้านี้จากหน้าอื่น
      _loadReturnProductHistory();
    }
  }

  // แยกฟังก์ชันสำหรับโหลดข้อมูลประวัติการรับคืนสินค้า
  void _loadReturnProductHistory() {
    context.read<ReturnProductHistoryBloc>().add(FetchReturnProductHistory(
          search: _searchQuery,
          fromDate: DateFormat('yyyy-MM-dd').format(_fromDate),
          toDate: DateFormat('yyyy-MM-dd').format(_toDate),
        ));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ค้นหาด้วย debounce เพื่อลดการเรียก API บ่อยเกินไป
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchQuery != _searchController.text) {
        setState(() {
          _searchQuery = _searchController.text;
        });
        _loadReturnProductHistory();
      }
    });
  }

  // แสดง date picker สำหรับเลือกช่วงวันที่
  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });

      // เรียกดูข้อมูลตามช่วงวันที่ใหม่
      _loadReturnProductHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ประวัติการรับคืนสินค้า'),
        actions: [
          // ปุ่มเลือกวันที่
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'เลือกช่วงวันที่',
            onPressed: () => _selectDateRange(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // ส่วนแสดงช่วงวันที่ที่เลือก
          _buildDateRangeHeader(),

          // ช่องค้นหา
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'ค้นหาประวัติการรับคืนสินค้า',
                hintText: 'ค้นหาจากเลขที่เอกสารหรือชื่อลูกค้า',
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

          // รายการประวัติการรับคืนสินค้า
          Expanded(
            child: BlocBuilder<ReturnProductHistoryBloc, ReturnProductHistoryState>(
              builder: (context, state) {
                if (state is ReturnProductHistoryLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (state is ReturnProductHistoryLoaded) {
                  final history = state.history;

                  if (history.isEmpty) {
                    return Center(
                      child: EmptyStateWidget(
                        icon: Icons.assignment_return,
                        message: 'ไม่พบข้อมูลประวัติการรับคืนสินค้า',
                        subMessage: _searchQuery.isNotEmpty ? 'ลองเปลี่ยนคำค้นหาหรือช่วงวันที่' : 'ในช่วงวันที่ ${_dateFormat.format(_fromDate)} - ${_dateFormat.format(_toDate)}',
                        actionLabel: _searchQuery.isNotEmpty ? 'ล้างการค้นหา' : null,
                        onAction: _searchQuery.isNotEmpty
                            ? () {
                                _searchController.clear();
                              }
                            : null,
                      ),
                    );
                  }

                  return Scrollbar(
                    controller: _scrollController,
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final item = history[index];
                        return _buildReturnHistoryCard(item);
                      },
                    ),
                  );
                } else if (state is ReturnProductHistoryError) {
                  return Center(
                    child: EmptyStateWidget(
                      icon: Icons.error_outline,
                      message: 'เกิดข้อผิดพลาด',
                      subMessage: state.message,
                      actionLabel: 'ลองใหม่',
                      onAction: () {
                        _loadReturnProductHistory();
                      },
                    ),
                  );
                } else {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.primaryColor.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(
            Icons.date_range,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'วันที่: ${_dateFormat.format(_fromDate)} - ${_dateFormat.format(_toDate)}',
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => _selectDateRange(context),
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('เปลี่ยน'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnHistoryCard(ReturnProductHistoryModel returnHistory) {
    // แปลงวันที่และเวลาจาก string เป็น DateTime
    DateTime? returnDate;
    try {
      // Date format: yyyy-MM-dd
      final dateParts = returnHistory.docDate.split('-');
      if (dateParts.length == 3) {
        returnDate = DateTime(
          int.parse(dateParts[0]), // Year
          int.parse(dateParts[1]), // Month
          int.parse(dateParts[2]), // Day
        );
      }
    } catch (e) {
      // Handle parsing error
    }

    final formattedDate = returnDate != null ? _dateFormat.format(returnDate) : returnHistory.docDate;

    // แปลง total_amount จาก String เป็น double
    final double totalAmount = double.tryParse(returnHistory.totalAmount) ?? 0.0;
    // ฟอร์แมตยอดเงิน
    final formattedAmount = NumberFormat('#,##0.00', 'th_TH').format(totalAmount);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ReturnProductHistoryDetailScreen(
                docNo: returnHistory.docNo,
                custCode: returnHistory.custCode,
                custName: returnHistory.custName,
                docDate: formattedDate,
                docTime: returnHistory.docTime,
                invNo: returnHistory.invNo,
                totalAmount: totalAmount, // ส่งค่า totalAmount เข้าไปด้วย
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Document Number and Date
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      returnHistory.docNo,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    returnHistory.docTime,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Customer name
              Row(
                children: [
                  const Icon(
                    Icons.person,
                    size: 18,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      returnHistory.custName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Customer Code
              Row(
                children: [
                  const Icon(
                    Icons.badge,
                    size: 18,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'รหัสลูกค้า: ${returnHistory.custCode}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Divider
              Divider(color: Colors.grey.shade300),
              const SizedBox(height: 4),

              // Invoice Number and Total Amount
              Row(
                children: [
                  const Icon(
                    Icons.receipt_long,
                    size: 18,
                    color: Colors.deepOrange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'เลขที่ใบกำกับภาษี: ${returnHistory.invNo}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Total Amount
              Row(
                children: [
                  const Icon(
                    Icons.monetization_on,
                    size: 18,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'มูลค่ารับคืน: ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    '฿$formattedAmount',
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
      ),
    );
  }
}
