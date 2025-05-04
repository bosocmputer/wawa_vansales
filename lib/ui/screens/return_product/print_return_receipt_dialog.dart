// lib/ui/screens/return_product/print_return_receipt_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawa_vansales/data/models/customer_model.dart';
import 'package:wawa_vansales/data/services/printer_status_provider.dart';

/// Dialog สำหรับถามว่าต้องการพิมพ์ใบรับคืนสินค้าหรือไม่
class PrintReturnReceiptDialog extends StatefulWidget {
  /// หมายเลขเอกสาร
  final String documentNumber;

  /// ข้อมูลลูกค้า
  final CustomerModel customer;

  const PrintReturnReceiptDialog({
    super.key,
    required this.documentNumber,
    required this.customer,
  });

  /// แสดง dialog และคืนค่าการเลือกของผู้ใช้
  ///
  /// คืนค่า Map<String, dynamic> ที่มี key 'print' เป็น boolean
  /// หรือ null ถ้าผู้ใช้ปิด dialog
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required String documentNumber,
    required CustomerModel customer,
  }) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PrintReturnReceiptDialog(
        documentNumber: documentNumber,
        customer: customer,
      ),
    );
  }

  @override
  State<PrintReturnReceiptDialog> createState() => _PrintReturnReceiptDialogState();
}

class _PrintReturnReceiptDialogState extends State<PrintReturnReceiptDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.receipt_long, color: Colors.red),
          SizedBox(width: 8),
          Text('พิมพ์ใบรับคืนสินค้า',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              )),
        ],
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ข้อมูลเอกสาร
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ข้อมูลเอกสารรับคืน',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('เลขที่: ', style: TextStyle(fontSize: 13, color: Colors.black87)),
                    Text(
                      widget.documentNumber,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('ลูกค้า: ', style: TextStyle(fontSize: 13, color: Colors.black87)),
                    Expanded(
                      child: Text(
                        widget.customer.name ?? '',
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ข้อความแจ้งเตือน
          Consumer<PrinterStatusProvider>(
            builder: (context, printerStatus, _) {
              if (!printerStatus.isConnected) {
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade100),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'เครื่องพิมพ์ยังไม่ได้เชื่อมต่อ กรุณาเชื่อมต่อเครื่องพิมพ์ก่อนพิมพ์ใบรับคืนสินค้า',
                          style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      actions: [
        // ปุ่มไม่พิมพ์
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pop({'print': false}),
          icon: const Icon(Icons.close),
          label: const Text('ไม่พิมพ์'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        // ปุ่มพิมพ์
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop({
              'print': true,
              'receiptType': 'returnReceipt', // ประเภทใบเสร็จคงที่คือรับคืน
            });
          },
          icon: const Icon(Icons.print),
          label: const Text('พิมพ์ใบรับคืน'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
