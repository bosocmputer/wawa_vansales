// lib/ui/screens/sale/sale_summary_step.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wawa_vansales/blocs/cart/cart_bloc.dart';
import 'package:wawa_vansales/blocs/cart/cart_event.dart';
import 'package:wawa_vansales/data/models/cart_item_model.dart';
import 'package:wawa_vansales/data/models/customer_model.dart';
import 'package:wawa_vansales/data/models/payment_model.dart';
import 'package:wawa_vansales/ui/screens/sale/receipt_preview_widget.dart';

class SaleSummaryStep extends StatelessWidget {
  final CustomerModel customer;
  final List<CartItemModel> items;
  final List<PaymentModel> payments;
  final double totalAmount;
  final VoidCallback onBackStep;
  final bool isConnected;
  final bool isConnecting;
  final Future<bool> Function() onReconnectPrinter;
  final Future<Uint8List?> Function() createReceiptImage;

  const SaleSummaryStep({
    super.key,
    required this.customer,
    required this.items,
    required this.payments,
    required this.totalAmount,
    required this.onBackStep,
    required this.isConnected,
    required this.isConnecting,
    required this.onReconnectPrinter,
    required this.createReceiptImage,
  });

  Future<void> _showSaveConfirmDialog(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการบันทึก'),
        content: const Text('คุณต้องการบันทึกรายการขายนี้หรือไม่?'),
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
      context.read<CartBloc>().add(const SubmitSale());
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

                // แสดงใบเสร็จตัวอย่าง
                const Text(
                  'ตัวอย่างใบเสร็จ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // ใบเสร็จตัวอย่าง
                Container(
                  alignment: Alignment.center,
                  child: ReceiptPreviewWidget(
                    customer: customer,
                    items: items,
                    payments: payments,
                    totalAmount: totalAmount,
                    docNumber: 'ตัวอย่างเลขที่เอกสาร',
                  ),
                ),
              ],
            ),
          ),
        ),

        // ปุ่มดำเนินการ
        Container(
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
          child: SafeArea(
            child: Row(
              children: [
                // ปุ่มกลับ
                OutlinedButton(
                  onPressed: onBackStep,
                  child: const Text('กลับ'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(80, 44),
                  ),
                ),
                const SizedBox(width: 12),

                // ปุ่มบันทึก
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showSaveConfirmDialog(context),
                    icon: const Icon(Icons.save),
                    label: const Text('บันทึกการขาย'),
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
        color: isConnected ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.print : Icons.print_disabled,
            color: isConnected ? Colors.green : Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isConnected ? 'เครื่องพิมพ์พร้อมใช้งาน' : 'ไม่พบเครื่องพิมพ์',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isConnected ? Colors.green : Colors.orange,
                  ),
                ),
                if (isConnecting)
                  const Text(
                    'กำลังพยายามเชื่อมต่อใหม่...',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
          if (!isConnected)
            TextButton(
              onPressed: isConnecting ? null : onReconnectPrinter,
              child: isConnecting
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
