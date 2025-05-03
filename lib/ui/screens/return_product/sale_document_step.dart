// lib/ui/screens/return_product/sale_document_step.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wawa_vansales/blocs/return_product/return_product_bloc.dart';
import 'package:wawa_vansales/blocs/return_product/return_product_event.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/models/return_product/sale_document_model.dart';
import 'package:wawa_vansales/ui/screens/return_product/sale_document_search_screen.dart';

class SaleDocumentStep extends StatelessWidget {
  final SaleDocumentModel? selectedSaleDocument;
  final String customerCode;
  final String customerName;
  final List<SaleDocumentModel> saleDocuments;
  final VoidCallback onNextStep;
  final VoidCallback onBackStep;

  const SaleDocumentStep({
    super.key,
    required this.selectedSaleDocument,
    required this.customerCode,
    required this.customerName,
    required this.saleDocuments,
    required this.onNextStep,
    required this.onBackStep,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0.00', 'th_TH');

    return Column(
      children: [
        // หัวข้อและคำอธิบาย
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.receipt_long, color: AppTheme.primaryColor, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'เลือกเอกสารขาย',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'เลือกเอกสารขายที่ต้องการรับคืนสินค้า',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        // แสดงเอกสารขายที่เลือกหรือปุ่มค้นหาเอกสารขาย
        Expanded(
          child: selectedSaleDocument != null ? _buildSelectedSaleDocumentCard(context, selectedSaleDocument!, currencyFormat) : _buildSelectSaleDocumentButton(context),
        ),

        // ปุ่มกลับและถัดไป
        SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
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
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: onBackStep,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(80, 44),
                  ),
                  child: const Text('กลับ'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: selectedSaleDocument != null ? onNextStep : null,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('ถัดไป'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedSaleDocumentCard(BuildContext context, SaleDocumentModel saleDoc, NumberFormat formatter) {
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
      margin: const EdgeInsets.all(16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วนหัวของการ์ด
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'เอกสารขายที่เลือก',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _searchSaleDocument(context),
                  icon: const Icon(Icons.search, size: 16),
                  label: const Text('เปลี่ยน'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            // ข้อมูลเอกสาร
            Row(
              children: [
                const Icon(Icons.receipt, size: 20, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'เลขที่: ${saleDoc.docNo}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'วันที่: $formattedDate ${saleDoc.docTime}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ลูกค้า: ${saleDoc.custName} (${saleDoc.custCode})',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // มูลค่าการขาย
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'มูลค่ารวม:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '฿${formatter.format(amount)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // รูปแบบการชำระเงิน
            const Text(
              'รูปแบบการชำระเงิน:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if ((double.tryParse(saleDoc.cashAmount) ?? 0) > 0)
                  _buildPaymentTag(
                    'เงินสด',
                    '฿${formatter.format(double.tryParse(saleDoc.cashAmount) ?? 0)}',
                    Colors.green,
                  ),
                if ((double.tryParse(saleDoc.transferAmount) ?? 0) > 0)
                  _buildPaymentTag(
                    'โอนเงิน',
                    '฿${formatter.format(double.tryParse(saleDoc.transferAmount) ?? 0)}',
                    Colors.blue,
                  ),
                if ((double.tryParse(saleDoc.cardAmount) ?? 0) > 0)
                  _buildPaymentTag(
                    'บัตรเครดิต',
                    '฿${formatter.format(double.tryParse(saleDoc.cardAmount) ?? 0)}',
                    Colors.orange,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentTag(String label, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            label == 'เงินสด'
                ? Icons.payments
                : label == 'โอนเงิน'
                    ? Icons.account_balance
                    : Icons.credit_card,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '$label: $amount',
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectSaleDocumentButton(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ไอคอนใหญ่
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),

            // ปุ่มค้นหาเอกสารขาย
            ElevatedButton.icon(
              onPressed: () => _searchSaleDocument(context),
              icon: const Icon(Icons.search),
              label: const Text('ค้นหาเอกสารขาย'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 12),
            Text(
              'ค้นหาเอกสารขายเพื่อใช้ในการรับคืนสินค้า',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _searchSaleDocument(BuildContext context) async {
    if (customerCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกลูกค้าก่อน'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // 1. ดึงเอกสารขายล่าสุด 30 วัน
    final now = DateTime.now();
    final fromDate = now.subtract(const Duration(days: 30));
    final toDate = now;

    context.read<ReturnProductBloc>().add(
          FetchSaleDocuments(
            customerCode: customerCode,
            fromDate: DateFormat('yyyy-MM-dd').format(fromDate),
            toDate: DateFormat('yyyy-MM-dd').format(toDate),
          ),
        );

    // 2. เปิดหน้าค้นหาเอกสารขาย
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SaleDocumentSearchScreen(
          customerCode: customerCode,
          customerName: customerName,
        ),
      ),
    );
  }
}
