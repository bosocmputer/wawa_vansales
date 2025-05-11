// /lib/ui/screens/pre_order_history/pre_order_history_list_screen.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wawa_vansales/blocs/pre_order_history/pre_order_history_bloc.dart';
import 'package:wawa_vansales/blocs/pre_order_history/pre_order_history_event.dart';
import 'package:wawa_vansales/blocs/pre_order_history/pre_order_history_state.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/models/pre_order_history_model.dart';
import 'package:wawa_vansales/ui/screens/pre_order_history/pre_order_history_detail_screen.dart';
import 'package:wawa_vansales/utils/local_storage.dart';

class PreOrderHistoryListScreen extends StatefulWidget {
  const PreOrderHistoryListScreen({super.key});

  @override
  State<PreOrderHistoryListScreen> createState() => _PreOrderHistoryListScreenState();
}

class _PreOrderHistoryListScreenState extends State<PreOrderHistoryListScreen> {
  // กำหนดสีหลักของหน้าเป็น accentColor เพื่อความแตกต่างจาก SaleHistoryListScreen
  final Color _screenColor = AppTheme.primaryColor;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final _dateFormat = DateFormat('dd/MM/yyyy');
  final currencyFormat = NumberFormat('#,##0.00', 'th_TH');

  String _searchQuery = '';
  Timer? _debounce;

  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPreOrderHistoryList();
    });

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _loadPreOrderHistoryList();

    if (kDebugMode) {
      print('didChangeDependencies called, loading pre-order history');
    }
  }

  void _loadPreOrderHistoryList() async {
    final warehouseCode = await context.read<LocalStorage>().getWarehouseCode();
    // ignore: use_build_context_synchronously
    context.read<PreOrderHistoryBloc>().add(
          FetchPreOrderHistoryList(
            fromDate: _fromDate,
            toDate: _toDate,
            search: _searchQuery,
            warehouseCode: warehouseCode,
          ),
        );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchQuery != _searchController.text) {
        setState(() {
          _searchQuery = _searchController.text;
        });

        _loadPreOrderHistoryList();
      }
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _screenColor,
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

      _loadPreOrderHistoryList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ประวัติการขาย (พรีออเดอร์)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'เลือกช่วงวันที่',
            onPressed: () => _selectDateRange(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateRangeHeader(),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 0),
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
                          setState(() {
                            _searchQuery = '';
                          });
                          _loadPreOrderHistoryList();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<PreOrderHistoryBloc, PreOrderHistoryState>(
              builder: (context, state) {
                if (state is PreOrderHistoryLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (state is PreOrderHistoryListLoaded) {
                  final preOrderHistoryList = state.preOrderHistoryList;

                  final filteredList = _searchQuery.isEmpty
                      ? preOrderHistoryList
                      : preOrderHistoryList
                          .where((order) =>
                              order.docNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                              order.docDate.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                              order.custCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                              order.custName.toLowerCase().contains(_searchQuery.toLowerCase()))
                          .toList();

                  if (filteredList.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'ไม่พบข้อมูลประวัติการขาย (พรีออเดอร์)',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey[700],
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ในช่วงวันที่ ${_dateFormat.format(_fromDate)} - ${_dateFormat.format(_toDate)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8.0),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final preOrderHistory = filteredList[index];
                      return _buildPreOrderHistoryCard(context, preOrderHistory, currencyFormat);
                    },
                  );
                } else if (state is PreOrderHistoryError) {
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
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            _loadPreOrderHistoryList();
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

  Widget _buildDateRangeHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _screenColor.withOpacity(0.1),
      child: Row(
        children: [
          Icon(
            Icons.date_range,
            color: _screenColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'วันที่: ${_dateFormat.format(_fromDate)} - ${_dateFormat.format(_toDate)}',
            style: TextStyle(
              color: _screenColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => _selectDateRange(context),
            icon: Icon(Icons.edit, size: 16, color: _screenColor),
            label: Text('เปลี่ยน', style: TextStyle(color: _screenColor)),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreOrderHistoryCard(BuildContext context, PreOrderHistoryModel preOrderHistory, NumberFormat formatter) {
    final originalDate = preOrderHistory.docDate;
    String formattedDate = originalDate;

    try {
      final date = DateTime.parse(originalDate);
      formattedDate = _dateFormat.format(date);
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing date: $e');
      }
    }

    final docNo = preOrderHistory.docNo;
    final custName = preOrderHistory.custName;
    final custCode = preOrderHistory.custCode;
    final totalAmount = preOrderHistory.totalAmount;
    final docTime = preOrderHistory.docTime;

    // แปลงค่าตัวเลขให้อยู่ในรูปแบบที่ถูกต้อง
    final double totalNetAmount = double.tryParse(preOrderHistory.totalNetAmount ?? '0') ?? 0.0;

    // ใช้ค่าที่ถูกต้องสำหรับการแสดงผล (totalNetAmount มีค่าคือยอดสุทธิรวมค่าธรรมเนียม)
    final displayAmount = totalNetAmount > 0 ? totalNetAmount : totalAmount;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PreOrderHistoryDetailScreen(
                docNo: docNo,
                orderHistory: preOrderHistory,
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
                      color: _screenColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      docNo,
                      style: TextStyle(
                        color: _screenColor,
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
                  if (docTime.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(
                      docTime,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Customer name
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 18,
                    color: _screenColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      custName,
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
                    'รหัสลูกค้า: $custCode',
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

              // Order Status and Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Payment
                  _buildPaymentInfo(preOrderHistory),

                  // Total Amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'มูลค่า:',
                        style: TextStyle(
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '฿${formatter.format(displayAmount)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _screenColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // เพิ่มฟังก์ชันแสดงข้อมูลการชำระเงิน
  Widget _buildPaymentInfo(PreOrderHistoryModel preOrder) {
    // แปลงค่าเป็น double ด้วยวิธีที่ปลอดภัยมากขึ้น
    final double cashAmount = double.tryParse(preOrder.cashAmount) ?? 0;
    final double transferAmount = double.tryParse(preOrder.tranferAmount) ?? 0;
    final double cardAmount = double.tryParse(preOrder.cardAmount) ?? 0;

    // Log เพื่อตรวจสอบข้อมูล
    if (kDebugMode) {
      print("PreOrder Payment - Cash: ${preOrder.cashAmount}, Transfer: ${preOrder.tranferAmount}, Card: ${preOrder.cardAmount}");
    }

    // ถ้าไม่มีการชำระเงินที่ระบุประเภท ให้แสดงข้อความ
    if (cashAmount == 0 && transferAmount == 0 && cardAmount == 0) {
      return Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: _screenColor,
          ),
          const SizedBox(width: 8),
          const Text(
            'ไม่ระบุประเภทการชำระเงิน',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (cashAmount > 0)
          Row(
            children: [
              Icon(
                Icons.money,
                size: 18,
                color: _screenColor,
              ),
              const SizedBox(width: 8),
              Text(
                'เงินสด: ฿${currencyFormat.format(cashAmount)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        if (transferAmount > 0)
          Padding(
            padding: EdgeInsets.only(top: cashAmount > 0 ? 4 : 0),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance,
                  size: 18,
                  color: _screenColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'โอนเงิน: ฿${currencyFormat.format(transferAmount)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        if (cardAmount > 0)
          Padding(
            padding: EdgeInsets.only(top: (cashAmount > 0 || transferAmount > 0) ? 4 : 0),
            child: Row(
              children: [
                Icon(
                  Icons.credit_card,
                  size: 18,
                  color: _screenColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'บัตรเครดิต: ฿${currencyFormat.format(cardAmount)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
