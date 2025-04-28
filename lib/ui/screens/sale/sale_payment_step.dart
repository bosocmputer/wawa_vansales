// lib/ui/screens/sale/sale_payment_step.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wawa_vansales/blocs/cart/cart_bloc.dart';
import 'package:wawa_vansales/blocs/cart/cart_event.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/models/payment_model.dart';
import 'package:wawa_vansales/ui/widgets/custom_button.dart';
import 'package:intl/intl.dart';

class SalePaymentStep extends StatefulWidget {
  final double totalAmount;
  final List<PaymentModel> payments;
  final double remainingAmount;
  final VoidCallback onBackStep;
  final VoidCallback? onNextStep;

  const SalePaymentStep({
    super.key,
    required this.totalAmount,
    required this.payments,
    required this.remainingAmount,
    required this.onBackStep,
    this.onNextStep,
  });

  @override
  State<SalePaymentStep> createState() => _SalePaymentStepState();
}

class _SalePaymentStepState extends State<SalePaymentStep> {
  final NumberFormat _currencyFormat = NumberFormat('#,##0.00', 'th_TH');
  final TextEditingController _remarkController = TextEditingController();

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  void _showPaymentDialog(PaymentType type) {
    final paymentName = _getPaymentTypeName(type);
    final existingPayment = widget.payments.firstWhere(
      (p) => PaymentModel.intToPaymentType(p.payType) == type,
      orElse: () => PaymentModel(
        payType: PaymentModel.paymentTypeToInt(type),
        transNumber: '',
        payAmount: 0,
      ),
    );

    final amountController = TextEditingController(
      text: existingPayment.payAmount > 0 ? existingPayment.payAmount.toString() : widget.remainingAmount.toString(),
    );
    final refNumberController = TextEditingController(
      text: existingPayment.transNumber,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              _getPaymentTypeIcon(type),
              color: _getPaymentTypeColor(type),
            ),
            const SizedBox(width: 8),
            Text(
              'ชำระด้วย$paymentName',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ช่องกรอกจำนวนเงิน
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'จำนวนเงิน',
                  prefixText: '฿ ',
                  suffixIcon: TextButton(
                    onPressed: () {
                      amountController.text = widget.remainingAmount.toString();
                    },
                    child: const Text('ชำระเต็ม'),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                autofocus: true,
              ),

              // ช่องอ้างอิง (ถ้ามี)
              if (type != PaymentType.cash) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: refNumberController,
                  decoration: InputDecoration(
                    labelText: type == PaymentType.transfer ? 'หมายเลขอ้างอิง' : 'หมายเลขบัตร',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('กรุณาระบุจำนวนเงิน')),
                );
                return;
              }

              final payment = PaymentModel(
                payType: PaymentModel.paymentTypeToInt(type),
                transNumber: refNumberController.text,
                payAmount: amount,
              );

              context.read<CartBloc>().add(AddPayment(payment));
              Navigator.of(context).pop();
            },
            child: const Text('ตกลง'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentTypeName(PaymentType type) {
    switch (type) {
      case PaymentType.cash:
        return 'เงินสด';
      case PaymentType.transfer:
        return 'เงินโอน';
      case PaymentType.creditCard:
        return 'บัตรเครดิต';
    }
  }

  IconData _getPaymentTypeIcon(PaymentType type) {
    switch (type) {
      case PaymentType.cash:
        return Icons.money;
      case PaymentType.transfer:
        return Icons.account_balance;
      case PaymentType.creditCard:
        return Icons.credit_card;
    }
  }

  Color _getPaymentTypeColor(PaymentType type) {
    switch (type) {
      case PaymentType.cash:
        return Colors.green;
      case PaymentType.transfer:
        return Colors.blue;
      case PaymentType.creditCard:
        return Colors.orange;
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
                // สรุปยอดรวม
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // ยอดรวมทั้งหมด
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'ยอดรวมทั้งหมด',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '฿${_currencyFormat.format(widget.totalAmount)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        // ชำระแล้ว
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'ชำระแล้ว',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              '฿${_currencyFormat.format(widget.totalAmount - widget.remainingAmount)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),

                        // ยังไม่ชำระ
                        if (widget.remainingAmount > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'ยังไม่ชำระ',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.errorColor,
                                ),
                              ),
                              Text(
                                '฿${_currencyFormat.format(widget.remainingAmount)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.errorColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // วิธีการชำระเงิน
                const Text(
                  'เลือกวิธีการชำระเงิน',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // ปุ่มชำระเงิน - แถวเดียว
                Row(
                  children: [
                    Expanded(
                      child: _buildPaymentOptionButton(
                        PaymentType.cash,
                        'เงินสด',
                        Icons.payments,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPaymentOptionButton(
                        PaymentType.transfer,
                        'โอนเงิน',
                        Icons.account_balance,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPaymentOptionButton(
                        PaymentType.creditCard,
                        'บัตรเครดิต',
                        Icons.credit_card,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),

                // รายการชำระเงิน
                if (widget.payments.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'รายการชำระเงิน',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...widget.payments.map((payment) => _buildPaymentItem(payment)),
                ],
              ],
            ),
          ),
        ),

        // แถบปุ่มด้านล่าง
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
                  child: const Text('กลับ'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(80, 44),
                  ),
                ),
                const SizedBox(width: 12),

                // ปุ่มถัดไป
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.remainingAmount <= 0 ? widget.onNextStep : null,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('ตรวจสอบ'),
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

  Widget _buildPaymentOptionButton(
    PaymentType type,
    String label,
    IconData icon,
    Color color,
  ) {
    return InkWell(
      onTap: () => _showPaymentDialog(type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentItem(PaymentModel payment) {
    final type = PaymentModel.intToPaymentType(payment.payType);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          _getPaymentTypeIcon(type),
          color: _getPaymentTypeColor(type),
        ),
        title: Text(_getPaymentTypeName(type)),
        subtitle: payment.transNumber.isNotEmpty ? Text('อ้างอิง: ${payment.transNumber}') : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '฿${_currencyFormat.format(payment.payAmount)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: AppTheme.errorColor,
              onPressed: () {
                context.read<CartBloc>().add(RemovePayment(type));
              },
            ),
          ],
        ),
      ),
    );
  }
}
