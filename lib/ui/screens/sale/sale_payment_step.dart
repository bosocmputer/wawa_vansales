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
        title: Text('ชำระด้วย$paymentName'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'จำนวนเงิน',
                  prefixText: '฿ ',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              if (type != PaymentType.cash) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: refNumberController,
                  decoration: InputDecoration(
                    labelText: type == PaymentType.transfer ? 'หมายเลขอ้างอิง' : 'หมายเลขบัตร',
                    border: const OutlineInputBorder(),
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
                // ยอดรวมและเงินที่ต้องชำระ
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'ยอดรวมทั้งหมด:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${_currencyFormat.format(widget.totalAmount)} ฿',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'ชำระแล้ว:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${_currencyFormat.format(widget.totalAmount - widget.remainingAmount)} ฿',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'ยังไม่ชำระ:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_currencyFormat.format(widget.remainingAmount)} ฿',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: widget.remainingAmount > 0 ? AppTheme.errorColor : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // วิธีการชำระเงิน
                const Text(
                  'เลือกวิธีการชำระเงิน',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // ปุ่มชำระเงินแต่ละประเภท
                Row(
                  children: [
                    Expanded(
                      child: _buildPaymentButton(PaymentType.cash),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPaymentButton(PaymentType.transfer),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPaymentButton(PaymentType.creditCard),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // รายการชำระเงิน
                if (widget.payments.isNotEmpty) ...[
                  const Text(
                    'รายการชำระเงิน',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...widget.payments.map((payment) => _buildPaymentItem(payment)),
                ],

                // หมายเหตุ
                const SizedBox(height: 24),
                TextField(
                  controller: _remarkController,
                  decoration: const InputDecoration(
                    labelText: 'หมายเหตุ (ถ้ามี)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),

        // ปุ่มดำเนินการ
        _buildBottomActions(),
      ],
    );
  }

  Widget _buildPaymentButton(PaymentType type) {
    final paymentName = _getPaymentTypeName(type);
    final icon = _getPaymentTypeIcon(type);
    final color = _getPaymentTypeColor(type);

    return InkWell(
      onTap: () => _showPaymentDialog(type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              paymentName,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentItem(PaymentModel payment) {
    final type = PaymentModel.intToPaymentType(payment.payType);
    final name = _getPaymentTypeName(type);
    final icon = _getPaymentTypeIcon(type);
    final color = _getPaymentTypeColor(type);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(name),
        subtitle: payment.transNumber.isNotEmpty ? Text('อ้างอิง: ${payment.transNumber}') : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_currencyFormat.format(payment.payAmount)} ฿',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
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

  Widget _buildBottomActions() {
    return Container(
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
          Expanded(
            child: CustomButton(
              text: 'ย้อนกลับ',
              onPressed: widget.onBackStep,
              buttonType: ButtonType.outline,
              icon: const Icon(Icons.arrow_back),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: CustomButton(
              text: 'ถัดไป',
              onPressed: widget.remainingAmount <= 0 ? widget.onNextStep : null,
              icon: const Icon(Icons.arrow_forward, color: Colors.white),
              buttonType: ButtonType.primary,
            ),
          ),
        ],
      ),
    );
  }
}
