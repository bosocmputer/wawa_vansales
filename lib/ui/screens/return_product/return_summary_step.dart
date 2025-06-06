// lib/ui/screens/return_product/return_summary_step.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wawa_vansales/blocs/return_product/return_product_bloc.dart';
import 'package:wawa_vansales/blocs/return_product/return_product_event.dart';
import 'package:wawa_vansales/data/models/cart_item_model.dart';
import 'package:wawa_vansales/data/models/customer_model.dart';
import 'package:wawa_vansales/data/models/payment_model.dart';
import 'package:wawa_vansales/data/models/return_product/sale_document_model.dart';
import 'package:wawa_vansales/ui/screens/return_product/receipt_return_preview_widget.dart';
import 'package:intl/intl.dart';

class ReturnSummaryStep extends StatefulWidget {
  final CustomerModel customer;
  final SaleDocumentModel saleDocument;
  final List<CartItemModel> items;
  final List<PaymentModel> payments;
  final double totalAmount;
  final VoidCallback onBackStep;
  final bool isConnected;
  final bool isConnecting;
  final Future<bool> Function() onReconnectPrinter;
  final String empCode;

  const ReturnSummaryStep({
    super.key,
    required this.customer,
    required this.saleDocument,
    required this.items,
    required this.payments,
    required this.totalAmount,
    required this.onBackStep,
    required this.isConnected,
    required this.isConnecting,
    required this.onReconnectPrinter,
    required this.empCode,
  });

  @override
  State<ReturnSummaryStep> createState() => _ReturnSummaryStepState();
}

class _ReturnSummaryStepState extends State<ReturnSummaryStep> {
  String generatedDocNumber = '';
  String remark = '';
  final TextEditingController _remarkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _generateDocNumber();
  }

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _generateDocNumber() async {
    /// CNVyyyymmddhhii-random4

    final now = DateTime.now();
    final dateFormat = DateFormat('yyyyMMddHHmm');
    final formattedDate = dateFormat.format(now);
    final random = Random();
    final randomNumber = random.nextInt(10000).toString().padLeft(4, '0');
    String docNo = 'CNV$formattedDate-$randomNumber';

    // Check and limit to maximum 25 characters
    if (docNo.length > 25) {
      docNo = docNo.substring(0, 25);
    }

    setState(() {
      generatedDocNumber = docNo;
    });
  }

  Future<void> _showSaveConfirmDialog(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการบันทึก'),
        content: const Text('คุณต้องการบันทึกรายการรับคืนสินค้านี้หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // อ่านค่าหมายเหตุล่าสุด
      remark = _remarkController.text;

      // ส่งคำสั่งบันทึกการรับคืนสินค้า โดยส่ง generatedDocNumber ไปด้วย
      if (context.mounted) {
        context.read<ReturnProductBloc>().add(SubmitReturn(remark: remark, docNo: generatedDocNumber));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // สถานะเครื่องพิมพ์
                _buildPrinterStatus(context),
                const SizedBox(height: 16),

                // แสดงใบรับคืนตัวอย่าง
                const Text(
                  'ตัวอย่างใบรับคืน',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // ใบรับคืนตัวอย่าง
                Container(
                  alignment: Alignment.center,
                  child: ReceiptReturnPreviewWidget(
                    customer: widget.customer,
                    saleDocument: widget.saleDocument,
                    items: widget.items,
                    totalAmount: widget.totalAmount,
                    docNumber: generatedDocNumber,
                    empCode: widget.empCode,
                  ),
                ),

                // ช่องหมายเหตุ
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'หมายเหตุ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _remarkController,
                          decoration: InputDecoration(
                            hintText: 'ระบุหมายเหตุการรับคืนสินค้า (ถ้ามี)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ปุ่มดำเนินการ
        Container(
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
          child: SafeArea(
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: widget.onBackStep,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(80, 44),
                  ),
                  child: const Text('กลับ'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showSaveConfirmDialog(context),
                    icon: const Icon(Icons.save, size: 20),
                    label: const Text('บันทึกการรับคืน'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                      backgroundColor: Colors.green,
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

  Widget _buildPrinterStatus(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.isConnected ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isConnected ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.isConnected ? Icons.print : Icons.print_disabled,
            color: widget.isConnected ? Colors.green : Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.isConnected ? 'เครื่องพิมพ์พร้อมใช้งาน' : 'ไม่พบเครื่องพิมพ์',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.isConnected ? Colors.green : Colors.orange,
                  ),
                ),
                if (widget.isConnecting)
                  const Text(
                    'กำลังพยายามเชื่อมต่อใหม่...',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
          if (!widget.isConnected)
            TextButton(
              onPressed: widget.isConnecting ? null : widget.onReconnectPrinter,
              child: widget.isConnecting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('เชื่อมต่อใหม่'),
            ),
        ],
      ),
    );
  }
}
