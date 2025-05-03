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
    final currencyFormat = NumberFormat('#,##0.00', 'th_TH');

    return Scaffold(
      appBar: AppBar(
        title: Text('เลือกเอกสารขาย - ${widget.customerName}'),
      ),
      body: Column(
        children: [
          // ส่วนเลือกช่วงวันที่
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _selectDateRange(context),
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      '${DateFormat('dd/MM/yyyy').format(_fromDate)} - ${DateFormat('dd/MM/yyyy').format(_toDate)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      foregroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ช่องค้นหา
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
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

          const SizedBox(height: 16),

          // รายการเอกสารขาย
          Expanded(
            child: BlocBuilder<ReturnProductBloc, ReturnProductState>(
              builder: (context, state) {
                if (state is ReturnProductLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (state is ReturnProductLoaded && state.saleDocuments.isNotEmpty) {
                  final saleDocuments = state.saleDocuments;

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8.0),
                    itemCount: saleDocuments.length,
                    itemBuilder: (context, index) {
                      final saleDoc = saleDocuments[index];
                      return _buildSaleDocumentCard(context, saleDoc, currencyFormat);
                    },
                  );
                } else {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'ไม่พบข้อมูลเอกสารขาย',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        if (_searchQuery.isNotEmpty)
                          ElevatedButton.icon(
                            onPressed: () {
                              _searchController.clear();
                            },
                            icon: const Icon(Icons.clear),
                            label: const Text('ล้างการค้นหา'),
                          ),
                      ],
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

  // สร้าง widget แสดงรายการเอกสารขาย
  Widget _buildSaleDocumentCard(BuildContext context, SaleDocumentModel saleDoc, NumberFormat formatter) {
    // แปลงวันที่จากรูปแบบ API (2025-05-02) เป็นรูปแบบที่อ่านง่าย (02/05/2025)
    final originalDate = saleDoc.docDate;
    String formattedDate = originalDate;

    try {
      final date = DateTime.parse(originalDate);
      formattedDate = DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      // ถ้าแปลงวันที่ไม่ได้ ให้ใช้ค่าเดิม
    }

    final amount = double.tryParse(saleDoc.totalAmount) ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      elevation: 2,
      child: InkWell(
        onTap: () {
          context.read<ReturnProductBloc>().add(SelectSaleDocument(saleDoc));
          Navigator.of(context).pop();
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
                        saleDoc.docNo,
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
                        '$formattedDate ${saleDoc.docTime}',
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

              // Total Amount and Payment Types
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

              const SizedBox(height: 8),

              // Wrap for payment types
              Wrap(
                spacing: 8,
                children: [
                  if ((double.tryParse(saleDoc.cashAmount) ?? 0) > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'เงินสด: ${formatter.format(double.tryParse(saleDoc.cashAmount) ?? 0)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                  if ((double.tryParse(saleDoc.transferAmount) ?? 0) > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'โอนเงิน: ${formatter.format(double.tryParse(saleDoc.transferAmount) ?? 0)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                  if ((double.tryParse(saleDoc.cardAmount) ?? 0) > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'บัตรเครดิต: ${formatter.format(double.tryParse(saleDoc.cardAmount) ?? 0)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // กดเพื่อเลือก
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.primaryColor),
                  SizedBox(width: 4),
                  Text(
                    'กดเพื่อเลือก',
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
