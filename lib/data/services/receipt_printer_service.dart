import 'dart:async';
import 'dart:io';

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wawa_vansales/data/models/cart_item_model.dart';
import 'package:wawa_vansales/data/models/customer_model.dart';
import 'package:wawa_vansales/data/models/payment_model.dart';
import 'package:wawa_vansales/utils/global.dart';
import 'package:wawa_vansales/utils/local_storage.dart';

/// บริการสำหรับการสร้างและพิมพ์ใบเสร็จ
class ReceiptPrinterService {
  final BlueThermalPrinter _printer = BlueThermalPrinter.instance;
  // เพิ่มค่า default สำหรับรหัสพนักงานที่ไม่มีค่า
  final String _defaultEmpCode = "ไม่ระบุ";

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

  Future<bool> requestBluetoothPermissions() async {
    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
      ].request();

      return statuses.values.every((status) => status.isGranted);
    } else {
      // iOS ขอสิทธิ์อัตโนมัติเมื่อใช้งาน
      return true;
    }
  }

  /// พยายามเชื่อมต่อกับเครื่องพิมพ์อัตโนมัติ
  Future<bool> autoConnect() async {
    // เช็คการเชื่อมต่อก่อน ถ้าเชื่อมต่ออยู่แล้วไม่ต้องเชื่อมต่อใหม่
    bool isCurrentlyConnected = await checkConnection();
    if (isCurrentlyConnected) return true;

    // พยายามเชื่อมต่อ
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

  /// สร้างและพิมพ์ใบเสร็จ
  Future<bool> printReceipt({
    required CustomerModel customer,
    required List<CartItemModel> items,
    required List<PaymentModel> payments,
    required double totalAmount,
    required String docNumber,
    String? warehouseCode = 'NA',
    String? remark,
    String? empCode,
    String receiptType = 'taxReceipt',
    bool isCopy = false, // เพิ่มพารามิเตอร์สำหรับระบุว่าเป็นใบสำเนาหรือไม่
    double? changeAmount, // เพิ่มพารามิเตอร์สำหรับเงินทอน
    bool isFromPreOrder = false, // เพิ่มพารามิเตอร์สำหรับระบุว่าเป็นการขายจาก PreOrder หรือไม่
    double balanceAmount = 0, // เพิ่มพารามิเตอร์สำหรับยอดลดหนี้
  }) async {
    // ตรวจสอบการเชื่อมต่อ
    if (!_isConnected) {
      bool connected = await connectPrinter();
      if (!connected) return false;
    }

    try {
      // ดึงข้อมูลคลังและพื้นที่เก็บจาก LocalStorage
      final localStorage = LocalStorage(
        prefs: await SharedPreferences.getInstance(),
        secureStorage: const FlutterSecureStorage(),
      );
      final warehouse = await localStorage.getWarehouse();
      final location = await localStorage.getLocation();

      // เพิ่ม delay เล็กน้อยเพื่อรอให้เครื่องพิมพ์พร้อม
      await Future.delayed(const Duration(milliseconds: 200));

      const int smallSize = 0;
      const int mediumSize = 0;
      const int largeSize = 1;
      final NumberFormat currencyFormat = NumberFormat('#,##0.00', 'th_TH');

      // คำนวณ VAT 7% (เฉพาะกรณีใบกำกับภาษี)
      final bool isTaxReceipt = receiptType == 'taxReceipt';
      double vatAmount = 0;
      double priceBeforeVat = totalAmount;

      if (isTaxReceipt) {
        vatAmount = totalAmount * 0.07;
        priceBeforeVat = totalAmount - vatAmount;
      }

      // ส่วนหัว - แสดงตามประเภทใบเสร็จ
      if (isTaxReceipt) {
        await _printer.printCustom("ใบเสร็จรับเงิน", largeSize, 1);
      } else {
        await _printer.printCustom("บิลเงินสด", largeSize, 1);
      }

      // เพิ่มข้อความ "สำเนา" เมื่อ isCopy เป็น true
      if (isCopy) {
        await _printer.printCustom("** สำเนา **", mediumSize, 1);
      }

      await _printer.printCustom("บจก. วาวา 2559", smallSize, 1);

      // เพิ่ม delay ระหว่างการพิมพ์หลายบรรทัด
      await Future.delayed(const Duration(milliseconds: 50));

      // วันที่และเลขที่เอกสาร
      final now = DateTime.now();
      final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(now);
      await _printer.printCustom("เลขที่: $docNumber", smallSize, 0);
      await _printer.printCustom("วันที่: $dateStr", smallSize, 0);

      // แสดงข้อมูลคลังและพื้นที่เก็บ
      if (warehouse != null) {
        await _printer.printCustom("คลัง: ${warehouse.code} - ${warehouse.name}", smallSize, 0);
      }
      if (location != null) {
        await _printer.printCustom("พื้นที่เก็บ: ${location.code} - ${location.name}", smallSize, 0);
      }

      // ข้อมูลลูกค้า
      await Future.delayed(const Duration(milliseconds: 50));
      await _printer.printCustom("ลูกค้า: ${customer.name}", smallSize, 0);
      await _printer.printCustom("รหัส: ${customer.code}", smallSize, 0);
      // ถ้าเป็นการขายจาก pre-order จะไม่แสดงรายการสินค้า
      if (!isFromPreOrder) {
        // เส้นคั่น
        await Future.delayed(const Duration(milliseconds: 50));
        await _printer.printCustom("------------------------------", smallSize, 1);

        // พิมพ์แต่ละรายการสินค้า โดยเพิ่ม delay ระหว่างรายการเพื่อป้องกัน buffer overflow
        await _printer.printLeftRight("รายการ", "จำนวนเงิน", smallSize);
        await _printer.printCustom("------------------------------", smallSize, 1);

        for (var item in items) {
          await Future.delayed(const Duration(milliseconds: 30));

          // ชื่อสินค้า
          await _printer.printCustom("${item.itemName}/${item.unitCode}", smallSize, 0);

          // จำนวน x ราคา
          final qtyValue = double.tryParse(item.qty) ?? 0;
          final priceValue = double.tryParse(item.price) ?? 0;
          String qtyPriceText = "${qtyValue.toStringAsFixed(0)} x ${currencyFormat.format(priceValue)}";
          await _printer.printLeftRight(qtyPriceText, currencyFormat.format(item.totalAmount), smallSize);
        }
      }

      // เส้นคั่น
      await Future.delayed(const Duration(milliseconds: 50));
      await _printer.printCustom("------------------------------", smallSize, 1);

      /// แสดงยอดรวม
      await _printer.printLeftRight("ยอดรวม", currencyFormat.format(totalAmount), smallSize);

      // แสดงยอดก่อน VAT และ VAT เฉพาะในใบกำกับภาษี
      if (isTaxReceipt) {
        await _printer.printLeftRight("ราคาก่อน VAT", currencyFormat.format(priceBeforeVat), smallSize);
        await _printer.printLeftRight("VAT 7%", currencyFormat.format(vatAmount), smallSize);
      }

      // แสดงค่าธรรมเนียมบัตรเครดิต (ถ้ามีการชำระด้วยบัตรเครดิต)
      for (var payment in payments) {
        final paymentType = PaymentModel.intToPaymentType(payment.payType);
        if (paymentType == PaymentType.creditCard && payment.charge > 0) {
          await _printer.printLeftRight("Charge 1.5%", currencyFormat.format(payment.charge), smallSize);
        }
      }

      // balanceAmount ถ้า ค่าเป็น - ให้แปลงเป็น ไม่ติดลบ เช่น -123 จะเป็น 123
      if (balanceAmount < 0) {
        balanceAmount = balanceAmount.abs();
      }

      // แสดงยอดลดหนี้ (ถ้ามี)
      if (balanceAmount > 0) {
        // แสดงยอดลดหนี้
        await _printer.printLeftRight("ยอดลดหนี้", "-${currencyFormat.format(balanceAmount)}", smallSize);
      }

      // ยอดรวม
      await _printer.printLeftRight("ยอดรวมสุทธิ", currencyFormat.format(totalAmount - balanceAmount), mediumSize);

      // แสดงการชำระเงิน
      await Future.delayed(const Duration(milliseconds: 50));
      await _printer.printCustom("การชำระเงิน", smallSize, 1);
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
          case PaymentType.qrCode:
            paymentText = 'QR Code';
            break;
        }

        await _printer.printLeftRight(paymentText, currencyFormat.format(payment.payAmount), smallSize);

        // แสดงค่าธรรมเนียมบัตรเครดิต (ถ้ามี)
        if (paymentType == PaymentType.creditCard && payment.charge > 0) {
          await _printer.printLeftRight("Charge 1.5%", currencyFormat.format(payment.charge), smallSize);
          await _printer.printLeftRight("ยอดสุทธิ", currencyFormat.format(payment.payAmount + payment.charge), smallSize);
        }
      }

      // แสดงเงินทอน (ถ้ามี)
      if (changeAmount != null && changeAmount > 0) {
        await _printer.printLeftRight("เงินทอน", currencyFormat.format(changeAmount), smallSize);
      }

      // ส่วนท้าย
      await Future.delayed(const Duration(milliseconds: 50));
      await _printer.printCustom("------------------------------", smallSize, 1);

      final String staffCode = empCode ?? Global.empCode;

      // เพิ่มส่วนพนักงานขายและผู้รับสินค้า
      await Future.delayed(const Duration(milliseconds: 100));

      await _printer.printNewLine();
      await _printer.printNewLine();
      await _printer.printNewLine();
      await _printer.printNewLine();

      // พนักงานขาย
      await _printer.printCustom("พนักงานขาย.....................", smallSize, 0);
      String staffInfo = staffCode != 'NA' ? staffCode : _defaultEmpCode;
      if (warehouse != null && location != null) {
        staffInfo += " (${warehouse.code}/${location.code})";
      }
      await _printer.printCustom(staffInfo, smallSize, 1);

      // เว้นบรรทัด
      await _printer.printNewLine();
      await _printer.printNewLine();
      await _printer.printNewLine();
      await _printer.printNewLine();

      // ผู้รับสินค้า
      await _printer.printCustom("ผู้รับสินค้า.....................", smallSize, 0);

      await _printer.printNewLine();
      await _printer.printNewLine();
      await _printer.printNewLine();

      await _printer.printCustom("ขอบคุณที่ใช้บริการ", smallSize, 1);
      await _printer.printNewLine();
      await _printer.printNewLine();
      await _printer.printNewLine();
      await _printer.printCustom("", smallSize, 1);

      await _printer.paperCut();

      return true;
    } catch (e) {
      // ถ้าเกิดข้อผิดพลาดระหว่างการพิมพ์ ลองตัดการเชื่อมต่อแล้วเชื่อมต่อใหม่
      try {
        await disconnectPrinter();
        await Future.delayed(const Duration(milliseconds: 500));
        await connectPrinter();
      } catch (reconnectError) {
        // ไม่สามารถเชื่อมต่อใหม่ได้
      }
      return false;
    }
  }
}
