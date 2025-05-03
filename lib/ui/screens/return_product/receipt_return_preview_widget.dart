// lib/ui/screens/return_product/receipt_return_preview_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wawa_vansales/data/models/cart_item_model.dart';
import 'package:wawa_vansales/data/models/customer_model.dart';
import 'package:wawa_vansales/data/models/return_product/sale_document_model.dart';
import 'package:intl/intl.dart';
import 'package:wawa_vansales/utils/local_storage.dart';

class ReceiptReturnPreviewWidget extends StatefulWidget {
  final CustomerModel customer;
  final SaleDocumentModel saleDocument; // เอกสารขายที่อ้างอิง
  final List<CartItemModel> items;
  final double totalAmount;
  final String docNumber;
  final String empCode;

  const ReceiptReturnPreviewWidget({
    super.key,
    required this.customer,
    required this.saleDocument,
    required this.items,
    required this.totalAmount,
    required this.docNumber,
    required this.empCode,
  });

  @override
  State<ReceiptReturnPreviewWidget> createState() => _ReceiptReturnPreviewWidgetState();
}

class _ReceiptReturnPreviewWidgetState extends State<ReceiptReturnPreviewWidget> {
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
              'ใบรับคืนสินค้า',
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

            // แสดงข้อมูลเอกสารขายอ้างอิง
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'อ้างอิงเอกสารขาย: ${widget.saleDocument.docNo}',
                style: const TextStyle(fontSize: 10),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'วันที่ขาย: ${_formatDate(widget.saleDocument.docDate)}',
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

            // หัวข้อรายการสินค้า
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'รายการสินค้ารับคืน',
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

            // แสดงรายการสินค้า
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ยอดรับคืนสุทธิ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  currencyFormat.format(widget.totalAmount),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // เส้นคั่น
            const SizedBox(height: 8),
            const Divider(
              height: 1,
              color: Colors.grey,
            ),

            // พนักงานขายและผู้คืนสินค้า
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'พนักงาน: ',
                  style: TextStyle(fontSize: 10),
                ),
                Text(
                  staffCode,
                  style: const TextStyle(fontSize: 10),
                ),
                if (warehouseInfo != null)
                  Text(
                    ' ($warehouseInfo)',
                    style: const TextStyle(fontSize: 10),
                  ),
              ],
            ),

            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 40),
                  Expanded(
                    child: Divider(
                      thickness: 0.5,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: 40),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'ลายมือชื่อผู้คืนสินค้า',
              style: TextStyle(
                fontSize: 10,
              ),
            ),

            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 40),
                  Expanded(
                    child: Divider(
                      thickness: 0.5,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: 40),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'ลายมือชื่อผู้รับสินค้า',
              style: TextStyle(
                fontSize: 10,
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

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
