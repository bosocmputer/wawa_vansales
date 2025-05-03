// lib/ui/screens/return_product/return_summary_step.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wawa_vansales/blocs/return_product/return_product_bloc.dart';
import 'package:wawa_vansales/blocs/return_product/return_product_event.dart';
import 'package:wawa_vansales/data/models/cart_item_model.dart';
import 'package:wawa_vansales/data/models/customer_model.dart';
import 'package:wawa_vansales/data/models/payment_model.dart';
import 'package:wawa_vansales/data/models/return_product/sale_document_model.dart';
import 'package:wawa_vansales/utils/global.dart';
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
  final NumberFormat _currencyFormat = NumberFormat('#,##0.00', 'th_TH');

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
    // สร้างเลขที่เอกสารสำหรับการรับคืนสินค้า
    final warehouse = await Global.whCode;

    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final random = (1000 + DateTime.now().millisecond % 9000).toString();

    final docNo = 'MCN$warehouse$dateStr-$random';

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

      // ส่งคำสั่งบันทึกการรับคืนสินค้า
      if (context.mounted) {
        context.read<ReturnProductBloc>().add(SubmitReturn(remark: remark));
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

                // สรุปข้อมูลการรับคืนสินค้า
                _buildSummaryCard(),
                const SizedBox(height: 16),

                // รายการสินค้าที่รับคืน
                _buildReturnItemsCard(),
                const SizedBox(height: 16),

                // รายการคืนเงิน
                _buildPaymentsCard(),
                const SizedBox(height: 16),

                // ช่องหมายเหตุ
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

  Widget _buildSummaryCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // หัวข้อการ์ด
            const Row(
              children: [
                Icon(Icons.summarize, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'สรุปข้อมูลการรับคืนสินค้า',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            // เลขที่เอกสาร
            _buildInfoRow('เลขที่เอกสารรับคืน:', generatedDocNumber),
            const SizedBox(height: 4),

            // ข้อมูลเอกสารขายอ้างอิง
            _buildInfoRow('เอกสารขายอ้างอิง:', widget.saleDocument.docNo),
            _buildInfoRow(
              'ลงวันที่:',
              DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(widget.saleDocument.docDate) ?? DateTime.now()),
            ),
            const SizedBox(height: 4),

            // ข้อมูลลูกค้า
            _buildInfoRow('ลูกค้า:', widget.customer.name ?? ''),
            _buildInfoRow('รหัสลูกค้า:', widget.customer.code ?? ''),
            const SizedBox(height: 4),

            // ยอดรับคืนรวม
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ยอดรับคืนรวม:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '฿${_currencyFormat.format(widget.totalAmount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnItemsCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // หัวข้อการ์ด
            const Row(
              children: [
                Icon(Icons.list, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'รายการสินค้าที่รับคืน',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            // รายการสินค้า
            ...widget.items.map((item) => _buildItemRow(item)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(CartItemModel item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(item.itemName),
          Text('฿${_currencyFormat.format((double.tryParse(item.price) ?? 0) * (double.tryParse(item.qty) ?? 0))}'),
        ],
      ),
    );
  }

  Widget _buildPaymentsCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // หัวข้อการ์ด
            const Row(
              children: [
                Icon(Icons.payment, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'รายการคืนเงิน',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            // รายการคืนเงิน
            ...widget.payments.map((payment) => _buildPaymentRow(payment)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow(PaymentModel payment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Text(payment.payType),
          // Text('฿${_currencyFormat.format(payment.amount)}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value),
      ],
    );
  }
}
