// lib/ui/screens/sale/print_receipt_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/models/customer_model.dart';
import 'package:wawa_vansales/data/services/printer_status_provider.dart';

/// Dialog สำหรับถามว่าต้องการพิมพ์ใบเสร็จหรือไม่
/// และเลือกประเภทใบเสร็จ (บิลเงินสด หรือ ใบกำกับภาษีอย่างย่อ)
class PrintReceiptDialog extends StatefulWidget {
  /// หมายเลขเอกสาร
  final String documentNumber;

  /// ข้อมูลลูกค้า
  final CustomerModel customer;

  const PrintReceiptDialog({
    super.key,
    required this.documentNumber,
    required this.customer,
  });

  /// แสดง dialog และคืนค่าการเลือกของผู้ใช้
  ///
  /// คืนค่า Map<String, dynamic> ที่มี key 'print' เป็น boolean และ 'receiptType' เป็น String
  /// หรือ null ถ้าผู้ใช้ปิด dialog
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required String documentNumber,
    required CustomerModel customer,
  }) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PrintReceiptDialog(
        documentNumber: documentNumber,
        customer: customer,
      ),
    );
  }

  @override
  State<PrintReceiptDialog> createState() => _PrintReceiptDialogState();
}

class _PrintReceiptDialogState extends State<PrintReceiptDialog> {
  // ตัวแปรเก็บค่าเลือกประเภทใบเสร็จ
  String _selectedReceiptType = 'taxReceipt'; // default

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.receipt_long, color: AppTheme.primaryColor),
          SizedBox(width: 8),
          Text('พิมพ์ใบเสร็จ',
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
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ข้อมูลเอกสาร',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.blue.shade700,
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
                        color: AppTheme.primaryColor,
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

          const SizedBox(height: 16),

          // เลือกประเภทใบเสร็จ
          // const Text(
          //   'เลือกประเภทใบเสร็จ:',
          //   style: TextStyle(
          //     fontWeight: FontWeight.bold,
          //     fontSize: 14,
          //   ),
          // ),

          // const SizedBox(height: 8),

          // ตัวเลือกแบบการ์ด
          // Container(
          //   decoration: BoxDecoration(
          //     border: Border.all(color: Colors.grey.shade200),
          //     borderRadius: BorderRadius.circular(12),
          //   ),
          //   child: Column(
          //     children: [
          //       // ใบกำกับภาษี
          //       InkWell(
          //         onTap: () {
          //           setState(() => _selectedReceiptType = 'taxReceipt');
          //         },
          //         child: Padding(
          //           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          //           child: Row(
          //             children: [
          //               Container(
          //                 width: 22,
          //                 height: 22,
          //                 decoration: BoxDecoration(
          //                   shape: BoxShape.circle,
          //                   border: Border.all(
          //                     color: _selectedReceiptType == 'taxReceipt' ? AppTheme.primaryColor : Colors.grey.shade400,
          //                     width: 2,
          //                   ),
          //                   color: _selectedReceiptType == 'taxReceipt' ? AppTheme.primaryColor : Colors.white,
          //                 ),
          //                 child: _selectedReceiptType == 'taxReceipt' ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
          //               ),
          //               const SizedBox(width: 12),
          //               const Row(
          //                 children: [
          //                   Icon(Icons.receipt_long, color: Colors.blue, size: 20),
          //                   SizedBox(width: 8),
          //                   Text('ใบกำกับภาษีอย่างย่อ', style: TextStyle(fontSize: 15)),
          //                 ],
          //               ),
          //             ],
          //           ),
          //         ),
          //       ),
          //       Divider(height: 1, color: Colors.grey.shade200),

          //       // บิลเงินสด
          //       InkWell(
          //         onTap: () {
          //           setState(() => _selectedReceiptType = 'cashReceipt');
          //         },
          //         child: Padding(
          //           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          //           child: Row(
          //             children: [
          //               Container(
          //                 width: 22,
          //                 height: 22,
          //                 decoration: BoxDecoration(
          //                   shape: BoxShape.circle,
          //                   border: Border.all(
          //                     color: _selectedReceiptType == 'cashReceipt' ? AppTheme.primaryColor : Colors.grey.shade400,
          //                     width: 2,
          //                   ),
          //                   color: _selectedReceiptType == 'cashReceipt' ? AppTheme.primaryColor : Colors.white,
          //                 ),
          //                 child: _selectedReceiptType == 'cashReceipt' ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
          //               ),
          //               const SizedBox(width: 12),
          //               const Row(
          //                 children: [
          //                   Icon(Icons.receipt, color: Colors.green, size: 20),
          //                   SizedBox(width: 8),
          //                   Text('บิลเงินสด', style: TextStyle(fontSize: 15)),
          //                 ],
          //               ),
          //             ],
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),

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
                          'เครื่องพิมพ์ยังไม่ได้เชื่อมต่อ กรุณาเชื่อมต่อเครื่องพิมพ์ก่อนพิมพ์ใบเสร็จ',
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
              'receiptType': _selectedReceiptType,
            });
          },
          icon: const Icon(Icons.print),
          label: const Text('พิมพ์ใบเสร็จ'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
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
