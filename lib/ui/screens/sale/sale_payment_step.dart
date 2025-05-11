// lib/ui/screens/sale/sale_payment_step.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wawa_vansales/blocs/cart/cart_bloc.dart';
import 'package:wawa_vansales/blocs/cart/cart_event.dart';
import 'package:wawa_vansales/blocs/cart/cart_state.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/models/balance_detail_model.dart';
import 'package:wawa_vansales/data/models/customer_model.dart';
import 'package:wawa_vansales/data/models/payment_model.dart';
import 'package:wawa_vansales/ui/screens/sale/balance_detail_screen.dart';
import 'package:intl/intl.dart';

class SalePaymentStep extends StatefulWidget {
  final double totalAmount;
  final List<PaymentModel> payments;
  final double remainingAmount;
  final VoidCallback onBackStep;
  final VoidCallback? onNextStep;
  final bool isFromPreOrder;
  final CustomerModel customer;

  const SalePaymentStep({
    super.key,
    required this.totalAmount,
    required this.payments,
    required this.remainingAmount,
    required this.onBackStep,
    this.onNextStep,
    this.isFromPreOrder = false,
    required this.customer,
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

    // ตัวแปรเก็บค่าเงินทอนสำหรับใช้ใน dialog
    double dialogChangeAmount = 0.0;

    // คำนวณเงินทอนเริ่มต้น
    if (type == PaymentType.cash) {
      double initialAmount = double.tryParse(amountController.text) ?? 0.0;
      dialogChangeAmount = initialAmount - widget.remainingAmount;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
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
                  // แสดงยอดที่ต้องชำระ
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ยอดที่ต้องชำระ:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '฿${_currencyFormat.format(widget.remainingAmount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ช่องกรอกจำนวนเงิน
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'รับเงินมา',
                      prefixText: '฿ ',
                      suffixIcon: TextButton(
                        onPressed: () {
                          amountController.text = widget.remainingAmount.toString();
                          // อัปเดตเงินทอนเมื่อกดปุ่ม "ชำระเต็ม"
                          if (type == PaymentType.cash) {
                            setDialogState(() {
                              // เมื่อชำระเต็มจำนวน เงินทอนควรเป็น 0 (รับเงินมา = ยอดที่ต้องชำระพอดี)
                              dialogChangeAmount = 0.0;
                            });
                          }
                        },
                        child: const Text('ชำระเต็ม'),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    autofocus: true,
                    onChanged: (value) {
                      // คำนวณเงินทอนเมื่อมีการเปลี่ยนแปลงค่า
                      if (type == PaymentType.cash) {
                        double amount = double.tryParse(value) ?? 0.0;
                        setDialogState(() {
                          dialogChangeAmount = amount - widget.remainingAmount;
                        });
                      }
                    },
                  ),

                  // เฉพาะการชำระด้วยเงินสด ให้แสดงส่วนเงินทอน
                  if (type == PaymentType.cash) ...[
                    const SizedBox(height: 16),
                    // แสดงเงินทอน
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: dialogChangeAmount >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: dialogChangeAmount >= 0 ? Colors.green.shade300 : Colors.red.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'เงินทอน:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '฿${_currencyFormat.format(dialogChangeAmount)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: dialogChangeAmount >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ช่องอ้างอิง (สำหรับการโอนหรือบัตรเครดิต)
                  if (type != PaymentType.cash) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: refNumberController,
                      decoration: InputDecoration(
                        labelText: type == PaymentType.transfer ? 'หมายเลขอ้างอิง' : 'หมายเลขบัตร',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        // เพิ่มดาวแดงเพื่อแสดงว่าเป็นฟิลด์บังคับกรอก
                        suffix: type == PaymentType.creditCard ? const Text('*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)) : null,
                      ),
                    ),
                    if (type == PaymentType.creditCard) ...[
                      const SizedBox(height: 8),
                      const Text(
                        '* จำเป็นต้องระบุหมายเลขบัตรเมื่อชำระด้วยบัตรเครดิต',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
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

                  // ตรวจสอบว่ากรอกหมายเลขบัตรหรือไม่ในกรณีชำระด้วยบัตรเครดิต
                  if (type == PaymentType.creditCard && refNumberController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('กรุณาระบุหมายเลขบัตรเครดิต')),
                    );
                    return;
                  }

                  // ในกรณีที่เป็นเงินสด ตรวจสอบว่าเงินที่รับมาพอหรือไม่
                  if (type == PaymentType.cash) {
                    final receivedAmount = double.tryParse(amountController.text) ?? 0;
                    if (receivedAmount < widget.remainingAmount) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('เงินที่รับมาไม่พอสำหรับการชำระ')),
                      );
                      return;
                    }
                  }

                  final payment = PaymentModel(
                    payType: PaymentModel.paymentTypeToInt(type),
                    transNumber: refNumberController.text,
                    payAmount: amount,
                  );

                  context.read<CartBloc>().add(AddPayment(payment));
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('ตกลง'),
              ),
            ],
          );
        },
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

  double calculateTotalChange() {
    // หาชำระเงินสด
    final cashPayments = widget.payments.where((p) => PaymentModel.intToPaymentType(p.payType) == PaymentType.cash).toList();

    // คำนวณเงินทอนรวม
    double totalChange = 0;
    for (var payment in cashPayments) {
      if (payment.payAmount > widget.totalAmount) {
        totalChange += payment.payAmount - widget.totalAmount;
      }
    }

    return totalChange;
  }

  List<Widget> _calculateTotalChange() {
    // ใช้ฟังก์ชันที่เพิ่มเข้ามาใหม่
    double totalChange = calculateTotalChange();

    // ถ้ามีเงินทอน ให้แสดง
    if (totalChange > 0) {
      return [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'เงินทอน',
              style: TextStyle(
                fontSize: 16,
                color: Colors.green,
              ),
            ),
            Text(
              '฿${_currencyFormat.format(totalChange)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ];
    }

    return [];
  }

  void _openArBalanceScreen() async {
    // คำนวณยอดคงเหลือที่แท้จริงโดยหักลดหนี้ที่เลือกไว้แล้วออกจาก widget.remainingAmount
    double actualRemainingAmount = widget.remainingAmount;

    // ตรวจสอบ state ของ CartBloc เพื่อเรียกดูยอดลดหนี้ที่เลือกไว้ก่อนหน้า
    final cartState = context.read<CartBloc>().state;
    if (cartState is CartLoaded && cartState.balanceAmount > 0) {
      // ไม่นำยอดลดหนี้ที่เคยเลือกแล้วมาหักออกอีกครั้ง เพราะจะทำให้เกิดการหักซ้ำ
      // actualRemainingAmount = actualRemainingAmount; (คงไว้เหมือนเดิม)
    }

    // เปิดหน้า BalanceDetailScreen แทน ArBalanceScreen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BalanceDetailScreen(
          customerCode: widget.customer.code!,
          customerName: widget.customer.name!,
          remainingAmount: actualRemainingAmount,
        ),
      ),
    );
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

                        // เพิ่มส่วนแสดงเงินทอนในกรณีที่ชำระเต็มจำนวนและมีเงินทอน
                        if (widget.remainingAmount <= 0) ...[
                          // หาเงินทอน - คำนวณจากการชำระด้วยเงินสด
                          ..._calculateTotalChange(),
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

                // ปุ่มชำระเงินแบบลดหนี้ (เฉพาะเมื่อมาจาก Pre-order)
                if (widget.isFromPreOrder) ...[
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _openArBalanceScreen(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_balance_wallet, color: Colors.purple),
                          SizedBox(width: 8),
                          Text(
                            'ชำระด้วยการลดหนี้',
                            style: TextStyle(
                              color: Colors.purple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // รายการลดหนี้ (เฉพาะเมื่อมาจาก Pre-order)
                BlocBuilder<CartBloc, CartState>(
                  builder: (context, state) {
                    if (state is CartLoaded && state.balanceDetail.isNotEmpty && state.balanceAmount > 0) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'รายการลดหนี้',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '฿${_currencyFormat.format(state.balanceAmount)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...state.balanceDetail.map((detail) => _buildBalanceDetailItem(detail)),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
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
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(80, 44),
                  ),
                  child: const Text('กลับ'),
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
      child: Column(
        children: [
          ListTile(
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

          // เพิ่มการแสดงเงินทอนสำหรับการชำระด้วยเงินสด
          if (type == PaymentType.cash && payment.payAmount > widget.totalAmount) ...[
            Divider(height: 1, color: Colors.grey.shade200),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'เงินทอน:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    '฿${_currencyFormat.format(payment.payAmount - widget.totalAmount)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBalanceDetailItem(BalanceDetailModel detail) {
    // แปลงวันที่เป็นรูปแบบที่อ่านง่ายขึ้น
    String formattedDate = detail.docDate;
    try {
      final date = DateTime.parse(detail.docDate);
      formattedDate = DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      // ถ้าแปลงวันที่ไม่ได้ ให้ใช้ค่าเดิม
    }

    final amount = double.tryParse(detail.amount) ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.purple.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // ไอคอนด้านซ้าย
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.receipt_long,
                  color: Colors.purple,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // ข้อมูลเอกสาร
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          detail.docNo,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.purple,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // จำนวนเงิน
                      Text(
                        '฿${_currencyFormat.format(amount)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // วันที่
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
