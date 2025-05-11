// lib/ui/screens/return_product/sale_document_search_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wawa_vansales/blocs/return_product/return_product_bloc.dart';
import 'package:wawa_vansales/blocs/return_product/return_product_event.dart';
import 'package:wawa_vansales/blocs/return_product/return_product_state.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/models/return_product/sale_document_model.dart';
import 'package:wawa_vansales/ui/screens/warehouse/emty_state_widget.dart';

class SaleDocumentSearchScreen extends StatefulWidget {
  final String customerCode;
  final String customerName;

  const SaleDocumentSearchScreen({
    super.key,
    required this.customerCode,
    required this.customerName,
  });

  @override
  State<SaleDocumentSearchScreen> createState() => _SaleDocumentSearchScreenState();
}

class _SaleDocumentSearchScreenState extends State<SaleDocumentSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _currencyFormat = NumberFormat('#,##0.00', 'th_TH');

  // กำหนดวันที่เริ่มต้นเป็น 1 เดือนย้อนหลัง
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();

  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    // โหลดข้อมูลเอกสารขายเมื่อเปิดหน้าจอ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchSaleDocuments();
    });

    // ตั้งค่าการค้นหา
    _searchController.addListener(_onSearchChanged);
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
        _fetchSaleDocuments();
      }
    });
  }

  // เรียก API ดึงเอกสารขาย
  void _fetchSaleDocuments() {
    context.read<ReturnProductBloc>().add(FetchSaleDocuments(
          customerCode: widget.customerCode,
          search: _searchQuery,
          fromDate: DateFormat('yyyy-MM-dd').format(_fromDate),
          toDate: DateFormat('yyyy-MM-dd').format(_toDate),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'เลือกเอกสารขาย - ${widget.customerName}',
          style: const TextStyle(fontSize: 16),
        ),
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
            padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'ค้นหาเอกสารขาย',
                hintText: 'ค้นหาจากเลขที่เอกสาร',
                labelStyle: const TextStyle(fontSize: 14),
                hintStyle: const TextStyle(fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),

          // รายการเอกสารขาย
          Expanded(
            child: BlocBuilder<ReturnProductBloc, ReturnProductState>(
              builder: (context, state) {
                if (state is ReturnProductLoading) {
                  return const Center(
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                } else if (state is ReturnProductLoaded) {
                  final saleDocuments = state.saleDocuments;

                  if (saleDocuments.isEmpty) {
                    return Center(
                      child: EmptyStateWidget(
                        icon: Icons.receipt_long,
                        message: 'ไม่พบข้อมูลเอกสารขาย',
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
                      padding: const EdgeInsets.all(8),
                      itemCount: saleDocuments.length,
                      itemBuilder: (context, index) {
                        final saleDoc = saleDocuments[index];
                        return _buildSaleDocumentCard(context, saleDoc);
                      },
                    ),
                  );
                } else {
                  return Center(
                    child: EmptyStateWidget(
                      icon: Icons.error_outline,
                      message: 'เกิดข้อผิดพลาด',
                      subMessage: 'ไม่สามารถโหลดข้อมูลเอกสารขายได้',
                      actionLabel: 'ลองใหม่',
                      onAction: () {
                        _fetchSaleDocuments();
                      },
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // เปิด dialog เลือกช่วงวันที่
  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'เลือกช่วงวันที่',
      saveText: 'ตกลง',
      cancelText: 'ยกเลิก',
      confirmText: 'ตกลง',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
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
      _fetchSaleDocuments();
    }
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
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'วันที่: ${_dateFormat.format(_fromDate)} - ${_dateFormat.format(_toDate)}',
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => _selectDateRange(context),
            icon: const Icon(Icons.edit, size: 14),
            label: const Text('เปลี่ยน', style: TextStyle(fontSize: 12)),
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

  // สร้าง widget แสดงรายการเอกสารขาย
  Widget _buildSaleDocumentCard(BuildContext context, SaleDocumentModel saleDoc) {
    // แปลงวันที่จากรูปแบบ API (2025-05-02) เป็นรูปแบบที่อ่านง่าย (02/05/2025)
    final originalDate = saleDoc.docDate;
    String formattedDate = originalDate;

    try {
      final date = DateTime.parse(originalDate);
      formattedDate = _dateFormat.format(date);
    } catch (e) {
      // ถ้าแปลงวันที่ไม่ได้ ให้ใช้ค่าเดิม
    }

    final amount = double.tryParse(saleDoc.totalAmount) ?? 0;
    final cashAmount = double.tryParse(saleDoc.cashAmount!) ?? 0;
    final transferAmount = double.tryParse(saleDoc.transferAmount!) ?? 0;
    final cardAmount = double.tryParse(saleDoc.cardAmount!) ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // เลือกเอกสารขายและกลับไปหน้าที่แล้ว
          context.read<ReturnProductBloc>().add(SelectSaleDocument(saleDoc));
          Navigator.of(context).pop();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
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
                      saleDoc.docNo,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    saleDoc.docTime.length > 5 ? saleDoc.docTime.substring(0, 5) : saleDoc.docTime,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Customer name
              Row(
                children: [
                  const Icon(
                    Icons.person,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      saleDoc.custName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'รหัสลูกค้า: ${saleDoc.custCode}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Divider
              Divider(color: Colors.grey.shade300, height: 1),
              const SizedBox(height: 8),

              // Payment Information and Total Amount
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Payment methods
                  Expanded(
                    child: _buildPaymentInfo(cashAmount, transferAmount, cardAmount),
                  ),

                  // Total Amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '฿${_currencyFormat.format(amount)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
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

  Widget _buildPaymentInfo(double cashAmount, double transferAmount, double cardAmount) {
    // ถ้าไม่มีการชำระเงินที่ระบุประเภท ให้แสดงข้อความ
    if (cashAmount == 0 && transferAmount == 0 && cardAmount == 0) {
      return const Row(
        children: [
          Icon(
            Icons.payment,
            size: 16,
            color: Colors.grey,
          ),
          SizedBox(width: 6),
          Text(
            'ไม่ระบุประเภทการชำระเงิน',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
        ],
      );
    }

    // ถ้ามีประเภทการชำระเงินหลายรูปแบบ ให้แสดงเป็นไอคอน
    if ((cashAmount > 0 ? 1 : 0) + (transferAmount > 0 ? 1 : 0) + (cardAmount > 0 ? 1 : 0) > 1) {
      return Row(
        children: [
          const Icon(
            Icons.payment,
            size: 16,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 6),
          const Text(
            'ชำระแบบผสม:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          if (cashAmount > 0) _buildPaymentIcon(Icons.money, Colors.green, 'เงินสด'),
          if (transferAmount > 0) _buildPaymentIcon(Icons.account_balance, Colors.blue, 'โอนเงิน'),
          if (cardAmount > 0) _buildPaymentIcon(Icons.credit_card, Colors.orange, 'บัตรเครดิต'),
        ],
      );
    }

    // ถ้ามีแค่ประเภทเดียว ให้แสดงทั้งประเภทและจำนวนเงิน
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (cashAmount > 0)
          Row(
            children: [
              const Icon(
                Icons.money,
                size: 16,
                color: Colors.green,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'เงินสด: ฿${_currencyFormat.format(cashAmount)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.green,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        if (transferAmount > 0)
          Row(
            children: [
              const Icon(
                Icons.account_balance,
                size: 16,
                color: Colors.blue,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'โอนเงิน: ฿${_currencyFormat.format(transferAmount)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        if (cardAmount > 0)
          Row(
            children: [
              const Icon(
                Icons.credit_card,
                size: 16,
                color: Colors.orange,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'บัตรเครดิต: ฿${_currencyFormat.format(cardAmount)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildPaymentIcon(IconData icon, Color color, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 14,
          color: color,
        ),
      ),
    );
  }
}
