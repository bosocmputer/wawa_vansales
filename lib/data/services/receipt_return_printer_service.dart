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
import 'package:wawa_vansales/data/models/return_product/sale_document_model.dart';
import 'package:wawa_vansales/utils/global.dart';
import 'package:wawa_vansales/utils/local_storage.dart';

/// บริการสำหรับการสร้างและพิมพ์ใบรับคืนสินค้าโดยเฉพาะ
class ReceiptReturnPrinterService {
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
  static final ReceiptReturnPrinterService _instance = ReceiptReturnPrinterService._internal();

  factory ReceiptReturnPrinterService() {
    return _instance;
  }

  ReceiptReturnPrinterService._internal();

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

  /// สร้างและพิมพ์ใบรับคืนสินค้า
  Future<bool> printReturnReceipt({
    required CustomerModel customer,
    required SaleDocumentModel saleDocument,
    required List<CartItemModel> items,
    required List<PaymentModel> payments,
    required double totalAmount,
    required String docNumber,
    String? warehouseCode = 'NA',
    String? remark,
    String? empCode,
    String receiptType = 'taxReceipt',
    bool isCopy = false, // เพิ่มพารามิเตอร์สำหรับระบุว่าเป็นใบสำเนาหรือไม่
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

      // คำนวณ VAT 7%
      final double vatAmount = totalAmount * 0.07;
      final double priceBeforeVat = totalAmount - vatAmount;

      // 1. ส่วนหัว - ใบรับคืนสินค้า
      await _printer.printCustom("ใบรับคืนสินค้า", largeSize, 1);

      // เพิ่มข้อความ "สำเนา" เมื่อ isCopy เป็น true
      if (isCopy) {
        await _printer.printCustom("** สำเนา **", mediumSize, 1);
      }

      await _printer.printCustom("บจก. วาวา 2559", smallSize, 1);

      // เพิ่ม delay ระหว่างการพิมพ์หลายบรรทัด
      await Future.delayed(const Duration(milliseconds: 50));

      // 2. เลขที่เอกสารและวันที่
      final now = DateTime.now();
      final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(now);
      await _printer.printCustom("เลขที่: $docNumber", smallSize, 0);
      await _printer.printCustom("วันที่: $dateStr", smallSize, 0);

      // 3. แสดงข้อมูลคลังและพื้นที่เก็บ
      if (warehouse != null) {
        await _printer.printCustom("คลัง: ${warehouse.code} - ${warehouse.name}", smallSize, 0);
      }
      if (location != null) {
        await _printer.printCustom("พื้นที่เก็บ: ${location.code} - ${location.name}", smallSize, 0);
      }

      // 4. แสดงข้อมูลเอกสารขายอ้างอิง
      String saleDocDate = _formatDate(saleDocument.docDate);
      await _printer.printCustom("อ้างอิง: ${saleDocument.docNo}", smallSize, 0);
      await _printer.printCustom("วันที่ขาย: $saleDocDate", smallSize, 0);

      // 5. เส้นคั่น
      await Future.delayed(const Duration(milliseconds: 50));
      await _printer.printCustom("------------------------------", smallSize, 1);

      // 6. ข้อมูลลูกค้า
      await _printer.printCustom("ลูกค้า: ${customer.name}", smallSize, 0);
      await _printer.printCustom("รหัส: ${customer.code}", smallSize, 0);

      // 7. เส้นคั่น
      await Future.delayed(const Duration(milliseconds: 50));
      await _printer.printCustom("------------------------------", smallSize, 1);

      // 8. หัวข้อรายการสินค้า
      await _printer.printLeftRight("รายการ", "จำนวนเงิน", smallSize);
      await _printer.printCustom("------------------------------", smallSize, 1);

      // 9. รายการสินค้า
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

      // 10. เส้นคั่น
      await Future.delayed(const Duration(milliseconds: 50));
      await _printer.printCustom("------------------------------", smallSize, 1);

      // 11. แสดงยอดก่อน VAT และ VAT
      await _printer.printLeftRight("ราคาก่อน VAT", currencyFormat.format(priceBeforeVat), smallSize);
      await _printer.printLeftRight("VAT 7%", currencyFormat.format(vatAmount), smallSize);

      // 12. ยอดรวมสุทธิ
      await Future.delayed(const Duration(milliseconds: 30));
      // เพิ่มเส้นคั่นเพื่อแยกส่วนก่อนยอดรวม
      await _printer.printCustom("------------------------------", smallSize, 1);
      // ปรับขนาดตัวอักษรให้ใหญ่ขึ้นและใช้ตัวหนาสำหรับยอดสุทธิ
      await _printer.printLeftRight("ยอดรับคืนสุทธิ", currencyFormat.format(totalAmount), mediumSize);

      // 13. เส้นคั่น
      await Future.delayed(const Duration(milliseconds: 50));
      await _printer.printCustom("==============================", smallSize, 1);

      // 13.1. แสดงหมายเหตุ (ถ้ามี)
      if (remark != null && remark.trim().isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 30));
        await _printer.printCustom("หมายเหตุ:", smallSize, 0);
        await _printer.printCustom(remark.trim(), smallSize, 0);
        await _printer.printCustom("------------------------------", smallSize, 1);
      }

      // 14. ส่วนลายเซ็น
      await Future.delayed(const Duration(milliseconds: 100));
      await _printer.printNewLine();
      await _printer.printNewLine();
      await _printer.printNewLine();

      // 15. พนักงาน
      final String staffCode = empCode ?? Global.empCode;
      String staffInfo = staffCode != 'NA' ? staffCode : _defaultEmpCode;
      if (warehouse != null && location != null) {
        staffInfo += " (${warehouse.code}/${location.code})";
      }
      await _printer.printCustom(".........................", smallSize, 1);
      await _printer.printCustom("พนักงาน: $staffInfo", smallSize, 1);

      // 16. ลายมือชื่อผู้รับสินค้า
      await _printer.printNewLine();
      await _printer.printNewLine();
      await _printer.printNewLine();
      await _printer.printCustom(".........................", smallSize, 1);
      await _printer.printCustom("ลายมือชื่อผู้รับสินค้า", smallSize, 1);

      // 17. ส่วนท้าย
      await _printer.printNewLine();
      await _printer.printCustom("ขอบคุณที่ใช้บริการ", smallSize, 1);
      await _printer.printNewLine();
      await _printer.printNewLine();
      await _printer.printCustom("", smallSize, 1);

      // 18. ตัดกระดาษ
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

  // Helper method to format date
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
