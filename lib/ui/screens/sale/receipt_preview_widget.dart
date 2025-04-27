// lib/ui/screens/sale/widgets/receipt_preview_widget.dart
import 'package:flutter/material.dart';
import 'package:wawa_vansales/data/models/cart_item_model.dart';
import 'package:wawa_vansales/data/models/customer_model.dart';
import 'package:wawa_vansales/data/models/payment_model.dart';
import 'package:intl/intl.dart';

class ReceiptPreviewWidget extends StatelessWidget {
  final CustomerModel customer;
  final List<CartItemModel> items;
  final List<PaymentModel> payments;
  final double totalAmount;
  final String docNumber;

  const ReceiptPreviewWidget({
    super.key,
    required this.customer,
    required this.items,
    required this.payments,
    required this.totalAmount,
    required this.docNumber,
  });

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormat = NumberFormat('#,##0.00', 'th_TH');
    final DateTime now = DateTime.now();
    final String dateStr = DateFormat('dd/MM/yyyy HH:mm').format(now);

    return Container(
      width: 280, // ประมาณ 58mm
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ส่วนหัว
            const Text(
              'ใบเสร็จรับเงิน/ใบกำกับภาษีอย่างย่อ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'WAWA Van Sales',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'บริษัท วาวา จำกัด',
              style: TextStyle(
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),

            // เลขที่เอกสารและวันที่
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'เลขที่: $docNumber',
                  style: const TextStyle(fontSize: 10),
                ),
                Text(
                  dateStr,
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ข้อมูลลูกค้า
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ลูกค้า: ${customer.name}',
                    style: const TextStyle(fontSize: 10),
                  ),
                  Text(
                    'รหัส: ${customer.code}',
                    style: const TextStyle(fontSize: 10),
                  ),
                  if (customer.taxId!.isNotEmpty)
                    Text(
                      'เลขประจำตัวผู้เสียภาษี: ${customer.taxId}',
                      style: const TextStyle(fontSize: 10),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),

            // หัวตารางรายการสินค้า
            const Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    'รายการ',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'จำนวน',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'ราคา',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const Divider(),

            // รายการสินค้า
            ...items.map((item) {
              final qtyValue = double.tryParse(item.qty) ?? 0;
              final priceValue = double.tryParse(item.price) ?? 0;

              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Text(
                          item.itemName,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          qtyValue.toStringAsFixed(0),
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          currencyFormat.format(priceValue),
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Expanded(flex: 5, child: SizedBox()),
                      Expanded(
                        flex: 5,
                        child: Text(
                          '= ${currencyFormat.format(item.totalAmount)}',
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
              );
            }),
            const Divider(),

            // ยอดรวม
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ยอดรวม',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  currencyFormat.format(totalAmount),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // รายละเอียดการชำระเงิน
            ...payments.map((payment) {
              final paymentType = PaymentModel.intToPaymentType(payment.payType);
              String paymentText = '';

              switch (paymentType) {
                case PaymentType.cash:
                  paymentText = 'เงินสด';
                  break;
                case PaymentType.transfer:
                  paymentText = 'เงินโอน';
                  break;
                case PaymentType.creditCard:
                  paymentText = 'บัตรเครดิต';
                  break;
              }

              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        paymentText,
                        style: const TextStyle(fontSize: 10),
                      ),
                      Text(
                        currencyFormat.format(payment.payAmount),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  if (payment.transNumber.isNotEmpty)
                    Row(
                      children: [
                        Text(
                          'อ้างอิง: ${payment.transNumber}',
                          style: const TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                ],
              );
            }),
            const Divider(),

            // ส่วนท้าย
            const SizedBox(height: 8),
            const Text(
              'ขอบคุณที่ใช้บริการ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'พนักงานขาย: TEST',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
