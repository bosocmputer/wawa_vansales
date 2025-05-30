import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawa_vansales/data/services/printer_status_provider.dart';

class PrinterStatusWidget extends StatelessWidget {
  const PrinterStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PrinterStatusProvider>(
      builder: (context, printerStatus, child) {
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      printerStatus.isConnected ? Icons.print : Icons.print_disabled,
                      color: printerStatus.isConnected ? Colors.green : Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'เครื่องพิมพ์',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            printerStatus.isConnected ? 'เชื่อมต่อแล้ว: ${printerStatus.printerName}' : 'ไม่ได้เชื่อมต่อ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: printerStatus.isConnected ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: printerStatus.isConnecting ? null : () => _showConnectDialog(context, printerStatus),
                      icon: printerStatus.isConnecting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.refresh, size: 18),
                      label: Text(
                        printerStatus.isConnecting ? 'กำลังเชื่อมต่อ...' : 'เชื่อมต่อ',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showConnectDialog(BuildContext context, PrinterStatusProvider printerStatus) async {
    // แสดง dialog กำลังเชื่อมต่อ
    if (context.mounted) {
      bool wasCancelled = false;

      showDialog(
        context: context,
        barrierDismissible: true, // Allow dismissing by clicking outside
        builder: (context) => AlertDialog(
          title: const Text('กำลังเชื่อมต่อเครื่องพิมพ์'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('กำลังค้นหาและเชื่อมต่อเครื่องพิมพ์...'),
              SizedBox(height: 8),
              Text(
                'โปรดตรวจสอบให้แน่ใจว่าเครื่องพิมพ์เปิดอยู่และจับคู่บลูทูธกับอุปกรณ์แล้ว',
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                wasCancelled = true;
                Navigator.of(context).pop();
              },
              child: const Text('ยกเลิก'),
            ),
          ],
        ),
      ).then((_) {
        // If dialog is dismissed by tapping outside
        wasCancelled = true;
      });

      // พยายามเชื่อมต่อ
      final connected = await printerStatus.connectPrinter();

      // ปิด dialog ถ้ายังแสดงอยู่
      if (context.mounted && !wasCancelled) {
        try {
          Navigator.of(context).pop();
        } catch (e) {
          // Dialog already closed
        }
      }

      // แสดงผลการเชื่อมต่อ เฉพาะเมื่อไม่ได้ถูกยกเลิก
      if (context.mounted && !wasCancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(connected ? 'เชื่อมต่อเครื่องพิมพ์สำเร็จ' : 'ไม่สามารถเชื่อมต่อเครื่องพิมพ์ได้'),
            backgroundColor: connected ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}
