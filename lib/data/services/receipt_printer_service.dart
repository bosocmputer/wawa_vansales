import 'dart:async';

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';
import 'package:wawa_vansales/data/models/cart_item_model.dart';
import 'package:wawa_vansales/data/models/customer_model.dart';
import 'package:wawa_vansales/data/models/payment_model.dart';
import 'package:wawa_vansales/utils/global.dart';

/// บริการสำหรับการสร้างและพิมพ์ใบเสร็จ
class ReceiptPrinterService {
  final BlueThermalPrinter _printer = BlueThermalPrinter.instance;

  /// สถานะการเชื่อมต่อปัจจุบัน
  bool _isConnected = false;
  bool _isConnecting = false;
  BluetoothDevice? _connectedDevice;

  /// เข้าถึงสถานะการเชื่อมต่อ
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  /// สร้าง singleton instance
  static final ReceiptPrinterService _instance = ReceiptPrinterService._internal();

  factory ReceiptPrinterService() {
    return _instance;
  }

  ReceiptPrinterService._internal();

  /// ตรวจสอบการเชื่อมต่อเครื่องพิมพ์
  Future<bool> checkConnection() async {
    try {
      bool? connectedStatus = await _printer.isConnected;
      if (connectedStatus == true) {
        List<BluetoothDevice> devices = await _printer.getBondedDevices();
        for (var device in devices) {
          if (device.name == "InnerPrinter") {
            _isConnected = true;
            _connectedDevice = device;
            return true;
          }
        }
      }
      _isConnected = false;
      _connectedDevice = null;
      return false;
    } catch (e) {
      _isConnected = false;
      _connectedDevice = null;
      return false;
    }
  }

  /// เชื่อมต่อกับเครื่องพิมพ์อัตโนมัติ
  Future<bool> autoConnect() async {
    if (_isConnected) return true;
    return await connectPrinter();
  }

  /// เชื่อมต่อกับเครื่องพิมพ์
  Future<bool> connectPrinter() async {
    // ถ้ากำลังเชื่อมต่ออยู่ ให้รอจนกว่าจะเสร็จ
    if (_isConnecting) {
      int attempt = 0;
      while (_isConnecting && attempt < 5) {
        await Future.delayed(const Duration(milliseconds: 500));
        attempt++;
      }
      return _isConnected;
    }

    // ถ้าเชื่อมต่ออยู่แล้ว ให้ส่ง true กลับเลย
    if (_isConnected) {
      return true;
    }

    _isConnecting = true;

    try {
      List<BluetoothDevice> devices = await _printer.getBondedDevices();
      BluetoothDevice? innerPrinter;

      for (var device in devices) {
        if (device.name == "InnerPrinter") {
          innerPrinter = device;
          break;
        }
      }

      if (innerPrinter != null) {
        // ลองตัดการเชื่อมต่อก่อน เผื่อกรณี "already connected"
        try {
          await _printer.disconnect();
          await Future.delayed(const Duration(milliseconds: 300));
        } catch (e) {
          // ข้ามไป ถ้าตัดการเชื่อมต่อไม่สำเร็จ
        }

        // ลองเชื่อมต่อใหม่
        await _printer.connect(innerPrinter);
        _isConnected = true;
        _connectedDevice = innerPrinter;
        _isConnecting = false;
        return true;
      }

      _isConnecting = false;
      return false;
    } catch (e) {
      _isConnected = false;
      _connectedDevice = null;
      _isConnecting = false;
      return false;
    }
  }

  /// ตัดการเชื่อมต่อกับเครื่องพิมพ์
  Future<bool> disconnectPrinter() async {
    if (!_isConnected) return true;

    try {
      await _printer.disconnect();
      _isConnected = false;
      _connectedDevice = null;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// สร้างภาพใบเสร็จและส่งไปยังเครื่องพิมพ์
  Future<bool> printReceipt({
    required CustomerModel customer,
    required List<CartItemModel> items,
    required List<PaymentModel> payments,
    required double totalAmount,
    required String docNumber,
    String? warehouseCode = 'NA',
    String? remark,
    String? empCode = 'NA',
  }) async {
    if (!_isConnected) {
      bool connected = await connectPrinter();
      if (!connected) return false;
    }

    try {
      // ขนาดตัวอักษร - ใช้ขนาดเล็กที่สุดเพื่อประหยัดพื้นที่
      final int smallSize = 0; // ขนาดเล็กที่สุด
      final int mediumSize = 0; // ขนาดปกติ
      final int largeSize = 1; // ขนาดใหญ่

      final NumberFormat currencyFormat = NumberFormat('#,##0.00', 'th_TH');

      // ----- ส่วนหัว -----
      // ทำให้กระชับมากขึ้นเพื่อประหยัดพื้นที่กระดาษ
      await _printer.printCustom("ใบกำกับภาษีอย่างย่อ", largeSize, 1);
      await _printer.printCustom("WAWA Van Sales", smallSize, 1);

      // วันที่และเลขที่เอกสาร - รวมบรรทัดเพื่อประหยัดพื้นที่
      final now = DateTime.now();
      final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(now);
      await _printer.printLeftRight("เลขที่: $docNumber", dateStr, smallSize);

      // ข้อมูลลูกค้า - รูปแบบกระชับ
      await _printer.printCustom("ลูกค้า: ${customer.name}", smallSize, 0);
      await _printer.printCustom("รหัส: ${customer.code}", smallSize, 0);
      if (customer.taxId != null && customer.taxId!.isNotEmpty) {
        await _printer.printCustom("เลขภาษี: ${customer.taxId}", smallSize, 0);
      }

      // เส้นคั่นแบบบาง - ประหยัดพื้นที่
      await _printer.printCustom("------------------------------", smallSize, 1);

      // ----- รายการสินค้า -----
      // ไม่ต้องพิมพ์หัวตารางเพื่อประหยัดพื้นที่
      // รายการสินค้าทุกรายการ ออกแบบเน้นการอ่านง่าย
      for (var item in items) {
        // ชื่อสินค้า - แสดงเต็มบรรทัด
        await _printer.printCustom(item.itemName, smallSize, 0);

        // รวมจำนวน x ราคา และยอดรวมไว้ในบรรทัดเดียวกัน
        final qtyValue = double.tryParse(item.qty) ?? 0;
        final priceValue = double.tryParse(item.price) ?? 0;

        String qtyPriceText = "${qtyValue.toStringAsFixed(0)} x ${currencyFormat.format(priceValue)}";
        await _printer.printLeftRight(qtyPriceText, "${currencyFormat.format(item.totalAmount)}", smallSize);

        // ไม่เพิ่มบรรทัดว่างเพื่อประหยัดพื้นที่
      }

      // เส้นคั่นแบบบาง
      await _printer.printCustom("------------------------------", smallSize, 1);

      // ----- ยอดรวม -----
      // แสดงยอดรวมชัดเจน
      await _printer.printLeftRight("ยอดรวม", "${currencyFormat.format(totalAmount)}", mediumSize);

      // ----- การชำระเงิน -----
      for (var payment in payments) {
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

        await _printer.printLeftRight(paymentText, "${currencyFormat.format(payment.payAmount)}", smallSize);

        if (payment.transNumber.isNotEmpty) {
          await _printer.printCustom("อ้างอิง: ${payment.transNumber}", smallSize, 0);
        }
      }

      // ----- ส่วนท้าย -----
      await _printer.printCustom("------------------------------", smallSize, 1);
      // ----- พนักงาน ------
      await _printer.printCustom("ขอบคุณที่ใช้บริการ", smallSize, 1);
      await _printer.printCustom("พนักงานขาย: ${Global.empCode}", smallSize, 1);
      await _printer.printNewLine();

      // ตัดกระดาษ
      await _printer.printNewLine();
      await _printer.printNewLine();
      try {
        await _printer.paperCut();
      } catch (e) {
        // อาจไม่รองรับคำสั่งตัดกระดาษ
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
