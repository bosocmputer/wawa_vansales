// lib/ui/screens/sale/sale_summary_step.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wawa_vansales/blocs/cart/cart_bloc.dart';
import 'package:wawa_vansales/blocs/cart/cart_event.dart';
import 'package:wawa_vansales/data/models/cart_item_model.dart';
import 'package:wawa_vansales/data/models/customer_model.dart';
import 'package:wawa_vansales/data/models/payment_model.dart';
import 'package:wawa_vansales/ui/screens/sale/receipt_preview_widget.dart';
import 'package:wawa_vansales/utils/global.dart';
import 'package:wawa_vansales/utils/local_storage.dart';

class SaleSummaryStep extends StatefulWidget {
  final CustomerModel customer;
  final List<CartItemModel> items;
  final List<PaymentModel> payments;
  final double totalAmount;
  final VoidCallback onBackStep;
  final bool isConnected;
  final bool isConnecting;
  final Future<bool> Function() onReconnectPrinter;
  final String empCode;
  final String? preOrderDocNumber; // เพิ่มพารามิเตอร์สำหรับเลขที่เอกสาร pre-order

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
    required this.empCode,
    this.preOrderDocNumber, // พารามิเตอร์เลขที่เอกสาร pre-order (ไม่บังคับ)
  });

  @override
  State<SaleSummaryStep> createState() => _SaleSummaryStepState();
}

class _SaleSummaryStepState extends State<SaleSummaryStep> {
  String generatedDocNumber = '';

  @override
  void initState() {
    super.initState();
    _generateDocNumber();
  }

  Future<void> _generateDocNumber() async {
    // ถ้ามีเลขที่เอกสาร preOrder ให้ใช้เลขที่เอกสารนั้นเลย
    if (widget.preOrderDocNumber != null && widget.preOrderDocNumber!.isNotEmpty) {
      setState(() {
        generatedDocNumber = widget.preOrderDocNumber!;
      });
      return;
    }

    // ถ้าไม่มีเลขที่เอกสาร preOrder ให้สร้างเลขที่เอกสารใหม่
    final localStorage = context.read<LocalStorage>();
    final warehouse = await localStorage.getWarehouse();
    final warehouseCode = warehouse?.code ?? 'NA';

    final docNo = Global.generateDocumentNumber(warehouseCode);

    setState(() {
      generatedDocNumber = docNo;
    });
  }

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
      // ignore: use_build_context_synchronously
      context.read<CartBloc>()
        ..add(SetDocumentNumber(generatedDocNumber))
        ..add(const SubmitSale());
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
                    customer: widget.customer,
                    items: widget.items,
                    payments: widget.payments,
                    totalAmount: widget.totalAmount,
                    docNumber: generatedDocNumber,
                    empCode: widget.empCode,
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
                  onPressed: widget.onBackStep,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(80, 44),
                  ),
                  child: const Text('กลับ'),
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
