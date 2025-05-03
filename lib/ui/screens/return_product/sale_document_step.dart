// lib/ui/screens/return_product/sale_document_step.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wawa_vansales/blocs/return_product/return_product_bloc.dart';
import 'package:wawa_vansales/blocs/return_product/return_product_event.dart';
import 'package:wawa_vansales/blocs/return_product/return_product_state.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/models/return_product/sale_document_detail_model.dart';
import 'package:wawa_vansales/data/models/return_product/sale_document_model.dart';
import 'package:wawa_vansales/ui/screens/return_product/sale_document_search_screen.dart';

// คลาสสำหรับเก็บข้อมูลสินค้าเพื่อแสดงในหน้าจอ
class ProductDetail {
  final String productCode;
  final String productName;
  final double price;
  final double quantity;
  final String unit;
  final double totalAmount;
  final String refRow;

  ProductDetail({
    required this.productCode,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.unit,
    required this.totalAmount,
    required this.refRow,
  });

  // แปลงข้อมูลจาก SaleDocumentDetailModel
  factory ProductDetail.fromSaleDocumentDetail(SaleDocumentDetailModel detail) {
    return ProductDetail(
      productCode: detail.itemCode,
      productName: detail.itemName,
      price: detail.priceAsDouble,
      quantity: detail.qtyAsDouble,
      unit: detail.unitCode,
      totalAmount: detail.totalAmount,
      refRow: detail.refRow,
    );
  }
}

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
        // หัวข้อและคำอธิบาย (ลดขนาด)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.receipt_long, color: AppTheme.primaryColor, size: 20),
                  SizedBox(width: 6),
                  Text(
                    'เลือกเอกสารขาย',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'เลือกเอกสารขายที่ต้องการรับคืนสินค้า',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // แสดงเอกสารขายที่เลือกหรือปุ่มค้นหาเอกสารขาย
        Expanded(
          child: selectedSaleDocument != null ? _buildSelectedSaleDocumentCard(context, selectedSaleDocument!, currencyFormat) : _buildSelectSaleDocumentButton(context),
        ),

        // ปุ่มกลับและถัดไป (ปรับขนาดให้เล็กลง)
        SafeArea(
          child: Container(
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
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: onBackStep,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(80, 44),
                  ),
                  child: const Text('กลับ'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: selectedSaleDocument != null ? onNextStep : null,
                    icon: const Icon(Icons.arrow_forward, size: 20),
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
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ส่วนหัวของการ์ดและข้อมูลเอกสาร
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
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
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    // ปุ่ม "เปลี่ยน" รูปแบบใหม่
                    InkWell(
                      onTap: () => _searchSaleDocument(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.primaryColor.withOpacity(0.7), AppTheme.primaryColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search,
                              size: 14,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'เปลี่ยน',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),

                // ข้อมูลเอกสาร
                Row(
                  children: [
                    const Icon(Icons.receipt, size: 16, color: AppTheme.primaryColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'เลขที่: ${saleDoc.docNo}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // จัดวันที่และรหัสลูกค้าให้อยู่ในแถวเดียวกัน
                Row(
                  children: [
                    // ข้อมูลวันที่
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${formattedDate} ${saleDoc.docTime}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ข้อมูลลูกค้า
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.person, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              saleDoc.custCode,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // มูลค่าการขาย
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'มูลค่ารวม:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '฿${formatter.format(amount)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // แสดงวิธีชำระเงินแบบประหยัดพื้นที่
                Row(
                  children: [
                    const Text(
                      'วิธีชำระ:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // แสดงไอคอนสำหรับวิธีชำระเงิน
                    if ((double.tryParse(saleDoc.cashAmount) ?? 0) > 0) _buildPaymentIcon('เงินสด', Colors.green),
                    if ((double.tryParse(saleDoc.transferAmount) ?? 0) > 0) _buildPaymentIcon('โอนเงิน', Colors.blue),
                    if ((double.tryParse(saleDoc.cardAmount) ?? 0) > 0) _buildPaymentIcon('บัตรเครดิต', Colors.orange),
                  ],
                ),
                const SizedBox(height: 12),

                // หัวข้อรายการสินค้า
                Row(
                  children: [
                    const Icon(Icons.inventory_2, size: 14, color: AppTheme.primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      'รายการสินค้า',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    BlocBuilder<ReturnProductBloc, ReturnProductState>(
                      builder: (context, state) {
                        if (state is ReturnProductLoaded && state.documentDetails.isNotEmpty) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${state.documentDetails.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // รายการสินค้า (ให้ scroll ได้)
          Expanded(
            child: BlocBuilder<ReturnProductBloc, ReturnProductState>(
              builder: (context, state) {
                if (state is ReturnProductLoaded && state.documentDetails.isNotEmpty) {
                  return _buildProductsList(context, state.documentDetails, formatter);
                } else if (state is ReturnProductLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                } else {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey, size: 14),
                        SizedBox(width: 6),
                        Text('กำลังโหลดรายการสินค้า...', style: TextStyle(color: Colors.grey, fontSize: 12)),
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

  // ไอคอนสำหรับวิธีชำระเงิน
  Widget _buildPaymentIcon(String label, Color color) {
    IconData icon = label == 'เงินสด'
        ? Icons.payments
        : label == 'โอนเงิน'
            ? Icons.account_balance
            : Icons.credit_card;

    return Tooltip(
      message: label,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(
          icon,
          size: 14,
          color: color,
        ),
      ),
    );
  }

  // แสดงรายการสินค้าโดยตรง ไม่ใช้ ExpansionTile
  Widget _buildProductsList(BuildContext context, List<SaleDocumentDetailModel> details, NumberFormat formatter) {
    // แปลง SaleDocumentDetailModel เป็น ProductDetail
    final productDetails = details.map((detail) => ProductDetail.fromSaleDocumentDetail(detail)).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        itemCount: productDetails.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: Colors.grey.shade300,
          indent: 12,
          endIndent: 12,
        ),
        itemBuilder: (context, index) {
          final product = productDetails[index];
          return ListTile(
            dense: true,
            visualDensity: const VisualDensity(horizontal: 0, vertical: -3),
            title: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    product.productName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Row(
                children: [
                  // รหัสสินค้า
                  Text(
                    product.productCode,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // ราคาต่อหน่วย
                  Text(
                    '฿${formatter.format(product.price)}/${product.unit}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  // จำนวน
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Text(
                      'x${product.quantity.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // ราคารวม
                  Text(
                    '฿${formatter.format(product.totalAmount)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          );
        },
      ),
    );
  }

  // ปรับปรุงปุ่มค้นหาเอกสารขาย
  Widget _buildSelectSaleDocumentButton(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ไอคอนใหญ่
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 36,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),

            // ปุ่มค้นหาเอกสารขาย
            ElevatedButton.icon(
              onPressed: () => _searchSaleDocument(context),
              icon: const Icon(Icons.search, size: 16),
              label: const Text('ค้นหาเอกสารขาย', style: TextStyle(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(180, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),

            const SizedBox(height: 10),
            Text(
              'เลือกเอกสารขายเพื่อใช้ในการรับคืนสินค้า',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
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
