import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wawa_vansales/blocs/sale_history/sale_history_bloc.dart';
import 'package:wawa_vansales/blocs/sale_history/sale_history_event.dart';
import 'package:wawa_vansales/blocs/sale_history/sale_history_state.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/models/sale_history_model.dart';
import 'package:wawa_vansales/ui/screens/sale_history/sale_history_detail_screen.dart';
import 'package:wawa_vansales/ui/screens/warehouse/emty_state_widget.dart';

class SaleHistoryListScreen extends StatefulWidget {
  const SaleHistoryListScreen({super.key});

  @override
  State<SaleHistoryListScreen> createState() => _SaleHistoryListScreenState();
}

class _SaleHistoryListScreenState extends State<SaleHistoryListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _currencyFormat = NumberFormat('#,##0.00', 'th_TH');

  String _searchQuery = '';
  Timer? _debounce;

  // วันที่เริ่มต้นและสิ้นสุด
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    // เมื่อเปิดหน้าจอ ให้โหลดข้อมูลประวัติการขายของวันนี้
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSaleHistory();
    });

    // ตั้งค่า listener สำหรับการค้นหา
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // ตรวจสอบสถานะของ bloc เมื่อกลับมาจากหน้าอื่น
    final state = context.read<SaleHistoryBloc>().state;
    if (state is SaleHistoryDetailLoaded || state is SaleHistoryDetailLoading) {
      // ถ้าอยู่ในสถานะของ detail ให้กลับไปโหลดข้อมูล list ใหม่
      _loadSaleHistory();
    }
  }

  // แยกฟังก์ชันสำหรับโหลดข้อมูลประวัติการขาย
  void _loadSaleHistory() {
    context.read<SaleHistoryBloc>().add(FetchSaleHistory(
          search: _searchQuery,
          fromDate: _fromDate,
          toDate: _toDate,
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
        context.read<SaleHistoryBloc>().add(SetHistorySearchQuery(_searchQuery));
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
      // ignore: use_build_context_synchronously
      context.read<SaleHistoryBloc>().add(SetDateRange(
            fromDate: _fromDate,
            toDate: _toDate,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ประวัติการขาย'),
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
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'ค้นหาประวัติการขาย',
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

          // รายการประวัติการขาย
          Expanded(
            child: BlocBuilder<SaleHistoryBloc, SaleHistoryState>(
              builder: (context, state) {
                if (state is SaleHistoryLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (state is SaleHistoryLoaded) {
                  final sales = state.sales;

                  if (sales.isEmpty) {
                    return Center(
                      child: EmptyStateWidget(
                        icon: Icons.receipt_long,
                        message: 'ไม่พบข้อมูลประวัติการขาย',
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
                      itemCount: sales.length,
                      itemBuilder: (context, index) {
                        final sale = sales[index];
                        return _buildSaleHistoryCard(sale);
                      },
                    ),
                  );
                } else if (state is SaleHistoryError) {
                  return Center(
                    child: EmptyStateWidget(
                      icon: Icons.error_outline,
                      message: 'เกิดข้อผิดพลาด',
                      subMessage: state.message,
                      actionLabel: 'ลองใหม่',
                      onAction: () {
                        context.read<SaleHistoryBloc>().add(FetchSaleHistory(
                              fromDate: _fromDate,
                              toDate: _toDate,
                            ));
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

  Widget _buildSaleHistoryCard(SaleHistoryModel sale) {
    // แปลงวันที่และเวลาจาก string เป็น DateTime
    DateTime? saleDate;
    try {
      // Date format: yyyy-MM-dd
      final dateParts = sale.docDate.split('-');
      if (dateParts.length == 3) {
        saleDate = DateTime(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
        );
      }
    } catch (e) {
      // Handle parsing error
    }

    final formattedDate = saleDate != null ? _dateFormat.format(saleDate) : sale.docDate;

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
              builder: (_) => SaleHistoryDetailScreen(docNo: sale.docNo),
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
                      sale.docNo,
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
                    sale.docTime,
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
                      sale.custName,
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
                    'รหัสลูกค้า: ${sale.custCode}',
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

              // Total Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'ยอดรวม:',
                    style: TextStyle(
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '฿${_currencyFormat.format(sale.totalAmountValue)}',
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
