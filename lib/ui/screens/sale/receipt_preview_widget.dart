// lib/ui/screens/sale/receipt_preview_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wawa_vansales/data/models/cart_item_model.dart';
import 'package:wawa_vansales/data/models/customer_model.dart';
import 'package:wawa_vansales/data/models/payment_model.dart';
import 'package:intl/intl.dart';
import 'package:wawa_vansales/utils/local_storage.dart';

class ReceiptPreviewWidget extends StatefulWidget {
  final CustomerModel customer;
  final List<CartItemModel> items;
  final List<PaymentModel> payments;
  final double totalAmount;
  final String docNumber;
  final String empCode;
  final bool isFromPreOrder; // เพิ่มพารามิเตอร์สำหรับระบุว่าเป็นการขายจาก Pre-Order หรือไม่
  final double balanceAmount; // เพิ่มพารามิเตอร์สำหรับยอดลดหนี้

  const ReceiptPreviewWidget({
    super.key,
    required this.customer,
    required this.items,
    required this.payments,
    required this.totalAmount,
    required this.docNumber,
    required this.empCode,
    this.isFromPreOrder = false, // ค่าเริ่มต้นเป็น false
    this.balanceAmount = 0, // ค่าเริ่มต้นเป็น 0
  });

  @override
  State<ReceiptPreviewWidget> createState() => _ReceiptPreviewWidgetState();
}

class _ReceiptPreviewWidgetState extends State<ReceiptPreviewWidget> {
  String? warehouseInfo;
  String? locationInfo;

  @override
  void initState() {
    super.initState();
    _loadWarehouseAndLocation();
  }

  Future<void> _loadWarehouseAndLocation() async {
    final localStorage = LocalStorage(
      prefs: await SharedPreferences.getInstance(),
      secureStorage: const FlutterSecureStorage(),
    );
    final warehouse = await localStorage.getWarehouse();
    final location = await localStorage.getLocation();

    if (mounted) {
      setState(() {
        if (warehouse != null) {
          warehouseInfo = "${warehouse.code} - ${warehouse.name}";
        }
        if (location != null) {
          locationInfo = "${location.code} - ${location.name}";
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormat = NumberFormat('#,##0.00', 'th_TH');
    final DateTime now = DateTime.now();
    final String dateStr = DateFormat('dd/MM/yyyy HH:mm').format(now);

    // คำนวณ VAT 7%
    final double vatAmount = widget.totalAmount * 0.07;
    final double priceBeforeVat = widget.totalAmount - vatAmount;

    // คำนวณเงินถอน (เงินทอน) และค่าธรรมเนียมบัตรเครดิต
    double totalPayment = 0;
    double totalCreditCardCharge = 0;

    for (var payment in widget.payments) {
      // ถ้าเป็นบัตรเครดิต คำนวณค่าธรรมเนียม
      if (payment.payType == PaymentModel.paymentTypeToInt(PaymentType.creditCard)) {
        totalCreditCardCharge += payment.charge;
      }
      totalPayment += payment.payAmount;
    }

    // คำนวณยอดสุทธิโดยรวมค่าธรรมเนียมบัตรเครดิต
    double totalNetAmount = widget.totalAmount + totalCreditCardCharge;
    double changeAmount = totalPayment - totalNetAmount > 0 ? totalPayment - totalNetAmount : 0;

    final String staffCode = widget.empCode;

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
              'ใบกำกับภาษีอย่างย่อ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'บจก. วาวา 2559',
              style: TextStyle(
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),

            // เลขที่เอกสารและวันที่
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'เลขที่: ${widget.docNumber}',
                style: const TextStyle(fontSize: 10),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'วันที่: $dateStr',
                style: const TextStyle(fontSize: 10),
              ),
            ),

            // แสดงข้อมูลคลังและพื้นที่เก็บ
            if (warehouseInfo != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'คลัง: $warehouseInfo',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            if (locationInfo != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'พื้นที่เก็บ: $locationInfo',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            const SizedBox(height: 2),
            // เส้นคั่น
            const Divider(
              height: 1,
              color: Colors.grey,
            ),
            const SizedBox(height: 2),
            // ข้อมูลลูกค้า
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ลูกค้า: ${widget.customer.name}',
                    style: const TextStyle(fontSize: 10),
                  ),
                  Text(
                    'รหัส: ${widget.customer.code}',
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),

            // เส้นคั่น
            const SizedBox(height: 2),
            const Divider(
              height: 1,
              color: Colors.grey,
            ),
            const SizedBox(height: 2),

            // ถ้าเป็นการขายจาก pre-order จะไม่แสดงรายการสินค้า
            if (!widget.isFromPreOrder) ...[
              // หัวข้อรายการสินค้า
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'รายการ',
                    style: TextStyle(fontSize: 10),
                  ),
                  Text(
                    'จำนวนเงิน',
                    style: TextStyle(fontSize: 10),
                  ),
                ],
              ),
              const Divider(
                height: 1,
                color: Colors.grey,
              ),

              const SizedBox(height: 4),

              // แสดงรายการสินค้าเฉพาะกรณีที่ไม่ใช่การขายจาก pre-order
              ...widget.items.map((item) {
                final qtyValue = double.tryParse(item.qty) ?? 0;
                final priceValue = double.tryParse(item.price) ?? 0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ชื่อสินค้า
                    Text(
                      item.itemName,
                      style: const TextStyle(fontSize: 10),
                    ),
                    // จำนวน x ราคา = รวม
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${qtyValue.toStringAsFixed(0)} x ${currencyFormat.format(priceValue)} ${item.unitCode}",
                          style: const TextStyle(fontSize: 10),
                        ),
                        Text(
                          currencyFormat.format(item.totalAmount),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                );
              }),

              // เส้นคั่น
              const Divider(
                height: 1,
                color: Colors.grey,
              ),

              const SizedBox(height: 4),
            ],

            // แสดงยอดรวม, VAT, และยอดสุทธิ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ราคาก่อน VAT',
                  style: TextStyle(fontSize: 10),
                ),
                Text(
                  currencyFormat.format(priceBeforeVat),
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'VAT 7%',
                  style: TextStyle(fontSize: 10),
                ),
                Text(
                  currencyFormat.format(vatAmount),
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (totalCreditCardCharge > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ค่าธรรมเนียมบัตรเครดิต',
                    style: TextStyle(fontSize: 10),
                  ),
                  Text(
                    currencyFormat.format(totalCreditCardCharge),
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],

            if (widget.balanceAmount > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ยอดลดหนี้',
                    style: TextStyle(fontSize: 10),
                  ),
                  Text(
                    "-${currencyFormat.format(widget.balanceAmount)}",
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ยอดรวมสุทธิ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  currencyFormat.format(totalNetAmount - widget.balanceAmount),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // รายละเอียดการชำระเงิน
            const Align(
              alignment: Alignment.center,
              child: Text(
                'การชำระเงิน',
                style: TextStyle(fontSize: 10),
              ),
            ),
            ...widget.payments.map((payment) {
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
                case PaymentType.qrCode:
                  paymentText = 'QR Code';
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
                  // if (payment.transNumber.isNotEmpty)
                  //   Align(
                  //     alignment: Alignment.centerLeft,
                  //     child: Text(
                  //       'อ้างอิง: ${payment.transNumber}',
                  //       style: const TextStyle(fontSize: 8),
                  //     ),
                  //   ),
                  // แสดงค่าธรรมเนียมบัตรเครดิต ถ้าเป็นการจ่ายด้วยบัตรและมีค่าธรรมเนียม
                  if (paymentType == PaymentType.creditCard && payment.charge > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Charge 1.5%',
                          style: TextStyle(fontSize: 10),
                        ),
                        Text(
                          currencyFormat.format(payment.charge),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'รวมบัตร',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          currencyFormat.format(payment.payAmount + payment.charge),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            }),

            // เพิ่มแสดงเงินถอน (เงินทอน)
            if (changeAmount > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'รับเงิน',
                    style: TextStyle(fontSize: 10),
                  ),
                  Text(
                    currencyFormat.format(totalPayment),
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'เงินทอน',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    currencyFormat.format(changeAmount),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],

            // เส้นคั่น
            const SizedBox(height: 8),
            const Divider(
              height: 1,
              color: Colors.grey,
            ),

            // พนักงานขายและผู้รับสินค้า
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'พนักงานขาย.....................',
                        style: TextStyle(fontSize: 10),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$staffCode ${warehouseInfo != null && locationInfo != null ? '($warehouseInfo/$locationInfo)' : ''}',
                        style: const TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.center,
              child: Text(
                'ผู้รับสินค้า.....................',
                style: TextStyle(fontSize: 10),
              ),
            ),
            // ส่วนท้าย
            const SizedBox(height: 8),
            const Text(
              'ขอบคุณที่ใช้บริการ',
              style: TextStyle(
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
