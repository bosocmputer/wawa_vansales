import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';
import 'package:wawa_vansales/data/models/cart_item_model.dart';
import 'package:wawa_vansales/data/models/customer_model.dart';
import 'package:wawa_vansales/data/models/payment_model.dart';

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
  }) async {
    /// mock data item 50 row
    // สร้าง mock data
    // List<CartItemModel> mockItems = [];

    // for (int i = 0; i < 100; i++) {
    //   mockItems.add(CartItemModel(
    //     itemName: "สินค้า $i",
    //     qty: "1",
    //     price: "100.00",
    //     itemCode: 'สินค้าทดสอบ ${i}',
    //     barcode: 'barcode ทดสอบ ${i}',
    //     sumAmount: '100',
    //     unitCode: 'PAC',
    //     whCode: 'wh001',
    //     shelfCode: 'lo001',
    //     ratio: '1',
    //     standValue: '1',
    //     divideValue: '1',
    //   ));
    // }

    // items = mockItems;

    if (!_isConnected) {
      bool connected = await connectPrinter();
      if (!connected) return false;
    }

    try {
      // ตั้งค่าขนาดตัวอักษรเริ่มต้น
      await _printer.printCustom("ใบเสร็จรับเงิน", 1, 1);
      await _printer.printCustom("WAWA Van Sales", 0, 1);
      await _printer.printCustom("บริษัท วาวา จำกัด", 0, 1);
      await _printer.printNewLine();

      // วันที่และเลขที่เอกสาร
      final now = DateTime.now();
      final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(now);
      await _printer.printLeftRight("เลขที่: $docNumber", "วันที่: $dateStr", 0);

      // ข้อมูลลูกค้า
      await _printer.printCustom("ลูกค้า: ${customer.name}", 0, 0);
      await _printer.printCustom("รหัส: ${customer.code}", 0, 0);
      if (customer.taxId != null && customer.taxId!.isNotEmpty) {
        await _printer.printCustom("เลขประจำตัวผู้เสียภาษี: ${customer.taxId}", 0, 0);
      }

      await _printer.printNewLine();

      // หัวตาราง
      await _printer.print3Column("รายการ", "จำนวน", "ราคา", 0);
      await _printer.printCustom("--------------------------------", 0, 1);

      // รายการสินค้า
      final NumberFormat currencyFormat = NumberFormat('#,##0.00', 'th_TH');
      for (var item in items) {
        // ชื่อสินค้า
        String itemName = item.itemName;
        if (itemName.length > 30) {
          itemName = '${itemName.substring(0, 27)}...';
        }
        await _printer.printCustom(itemName, 0, 0);

        // จำนวนและราคา
        final qtyValue = double.tryParse(item.qty) ?? 0;
        final priceValue = double.tryParse(item.price) ?? 0;
        await _printer.print3Column("", "${qtyValue.toStringAsFixed(0)}x${currencyFormat.format(priceValue)}", "${currencyFormat.format(item.totalAmount)}", 0);
      }

      await _printer.printCustom("--------------------------------", 0, 1);

      // ยอดรวม
      await _printer.printLeftRight("ยอดรวม", "${currencyFormat.format(totalAmount)}", 1);

      // รายละเอียดการชำระเงิน
      await _printer.printNewLine();
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

        await _printer.printLeftRight(paymentText, "${currencyFormat.format(payment.payAmount)}", 0);

        if (payment.transNumber.isNotEmpty) {
          await _printer.printCustom("อ้างอิง: ${payment.transNumber}", 0, 0);
        }
      }

      // ส่วนท้าย
      await _printer.printNewLine();
      await _printer.printCustom("ขอบคุณที่ใช้บริการ", 1, 1);
      await _printer.printCustom("พนักงานขาย: TEST", 0, 1);

      // ตัดกระดาษ
      await _printer.printNewLine();
      await _printer.printNewLine();
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

  /// สร้างภาพใบเสร็จ
  Future<Uint8List?> createReceiptImage({
    required CustomerModel customer,
    required List<CartItemModel> items,
    required List<PaymentModel> payments,
    required double totalAmount,
    required String docNumber,
    String? warehouseCode = 'NA',
    String? remark,
  }) async {
    // กำหนดค่าคงที่สำหรับขนาดกระดาษและขอบ

    /// 58mm = 384px
    /// 80mm = 576px

    const int width = 384; // ความกว้างมาตรฐานของเครื่องพิมพ์ 58mm
    const int padding = 10; // ขอบด้านซ้ายและขวา
    const double lineHeight = 20.0; // ความสูงของแต่ละบรรทัด

    // คำนวณความสูงทั้งหมดของรูปภาพ (ประมาณ)
    int headerHeight = 130;
    int itemsHeight = items.length * 40; // แต่ละรายการใช้พื้นที่ประมาณ 40px
    int paymentsHeight = payments.length * 25; // แต่ละการชำระใช้พื้นที่ประมาณ 25px
    int footerHeight = 50;
    // เผื่อพื้นที่เพิ่มเติม
    int height = headerHeight + itemsHeight + paymentsHeight + footerHeight + 50;

    // สร้าง Canvas สำหรับวาดรูปภาพ
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = Colors.white;

    // วาดพื้นหลังสีขาว
    canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), paint);

    // ฟอร์แมตสำหรับแสดงเงิน
    final NumberFormat currencyFormat = NumberFormat('#,##0.00', 'th_TH');

    // ฟังก์ชันช่วยในการวาดข้อความ
    void drawText(String text, double x, double y, {double fontSize = 14, bool isBold = false, TextAlign align = TextAlign.left, Color color = Colors.black}) {
      // กำหนด font style
      final textStyle = TextStyle(
        fontSize: fontSize,
        color: color,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      );

      final textSpan = TextSpan(
        text: text,
        style: textStyle,
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
        textAlign: align,
      );

      // คำนวณความกว้างสูงสุดที่ใช้ได้
      double maxWidth = width - (padding * 2);
      textPainter.layout(minWidth: 0, maxWidth: maxWidth);

      // คำนวณตำแหน่ง x ตาม alignment
      double xPos = x;
      if (align == TextAlign.center) {
        xPos = (width - textPainter.width) / 2;
      } else if (align == TextAlign.right) {
        xPos = width - padding - textPainter.width;
      }

      // วาดข้อความ
      textPainter.paint(canvas, Offset(xPos, y));
    }

    // ฟังก์ชันวาดเส้นคั่น
    void drawDivider(double y, {bool isDashed = false}) {
      paint.color = Colors.grey.shade300;
      paint.strokeWidth = 1;

      if (isDashed) {
        // วาดเส้นประ
        for (double x = padding.toDouble(); x < width - padding; x += 5) {
          canvas.drawLine(Offset(x, y), Offset(x + 2, y), paint);
        }
      } else {
        // วาดเส้นทึบ
        canvas.drawLine(Offset(padding.toDouble(), y), Offset((width - padding).toDouble(), y), paint);
      }
    }

    // เริ่มต้นวาดใบเสร็จ
    double currentY = padding.toDouble();

    // ----- หัวใบเสร็จ -----
    drawText('ใบเสร็จรับเงิน/ใบกำกับภาษีอย่างย่อ', 0, currentY, fontSize: 16, isBold: true, align: TextAlign.center);
    currentY += lineHeight * 1.2;

    drawText('WAWA Van Sales', 0, currentY, fontSize: 14, align: TextAlign.center);
    currentY += lineHeight;

    drawText('บริษัท วาวา จำกัด', 0, currentY, fontSize: 12, align: TextAlign.center);
    currentY += lineHeight * 1.2;

    // เส้นคั่น
    drawDivider(currentY);
    currentY += 10;

    // ----- ข้อมูลเอกสาร -----
    // หมายเลขเอกสารและวันที่
    final now = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(now);

    drawText('เลขที่: $docNumber', padding.toDouble(), currentY, fontSize: 12);
    drawText(dateStr, 0, currentY, fontSize: 12, align: TextAlign.right);
    currentY += lineHeight;

    // ข้อมูลลูกค้า
    drawText('ลูกค้า: ${customer.name}', padding.toDouble(), currentY, fontSize: 12);
    currentY += lineHeight;

    drawText('รหัส: ${customer.code}', padding.toDouble(), currentY, fontSize: 12);
    currentY += lineHeight;

    if (customer.taxId != null && customer.taxId!.isNotEmpty) {
      drawText('เลขประจำตัวผู้เสียภาษี: ${customer.taxId}', padding.toDouble(), currentY, fontSize: 12);
      currentY += lineHeight;
    }

    // เส้นคั่น
    currentY += 5;
    drawDivider(currentY);
    currentY += 10;

    // ----- หัวตาราง -----
    drawText('รายการ', padding.toDouble(), currentY, fontSize: 12, isBold: true);
    drawText('จำนวน', width * 0.65, currentY, fontSize: 12, isBold: true);
    drawText('ราคา', 0, currentY, fontSize: 12, isBold: true, align: TextAlign.right);
    currentY += lineHeight;

    drawDivider(currentY);
    currentY += 10;

    // ----- รายการสินค้า -----
    for (var item in items) {
      // ชื่อสินค้า (ตัดให้สั้นลงถ้าจำเป็น)
      String itemName = item.itemName;
      if (itemName.length > 30) {
        itemName = '${itemName.substring(0, 27)}...';
      }
      drawText(itemName, padding.toDouble(), currentY, fontSize: 12);
      currentY += lineHeight;

      // จำนวนและราคา
      final qtyValue = double.tryParse(item.qty) ?? 0;
      final priceValue = double.tryParse(item.price) ?? 0;

      drawText('${qtyValue.toStringAsFixed(0)} × ฿${currencyFormat.format(priceValue)}', padding.toDouble() + 10, currentY, fontSize: 12);
      drawText('฿${currencyFormat.format(item.totalAmount)}', 0, currentY, fontSize: 12, align: TextAlign.right);

      currentY += lineHeight + 5; // เพิ่มระยะห่างเล็กน้อย
    }

    // เส้นคั่น
    drawDivider(currentY);
    currentY += 10;

    // ----- ยอดรวม -----
    drawText('ยอดรวม', padding.toDouble(), currentY, fontSize: 14, isBold: true);
    drawText('฿${currencyFormat.format(totalAmount)}', 0, currentY, fontSize: 14, isBold: true, align: TextAlign.right);
    currentY += lineHeight * 1.2;

    // ----- รายละเอียดการชำระเงิน -----
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

      drawText(paymentText, padding.toDouble(), currentY, fontSize: 12);
      drawText('฿${currencyFormat.format(payment.payAmount)}', 0, currentY, fontSize: 12, align: TextAlign.right);
      currentY += lineHeight;

      // แสดงหมายเลขอ้างอิงถ้ามี
      if (payment.transNumber.isNotEmpty) {
        drawText('อ้างอิง: ${payment.transNumber}', padding.toDouble() + 10, currentY, fontSize: 10);
        currentY += lineHeight;
      }
    }

    // เส้นคั่น
    drawDivider(currentY);
    currentY += 15;

    // หมายเหตุ (ถ้ามี)
    if (remark != null && remark.isNotEmpty) {
      drawText('หมายเหตุ: $remark', padding.toDouble(), currentY, fontSize: 11);
      currentY += lineHeight;
    }

    // ----- ส่วนท้าย -----
    drawText('ขอบคุณที่ใช้บริการ', 0, currentY, fontSize: 14, isBold: true, align: TextAlign.center);
    currentY += lineHeight;

    drawText('พนักงานขาย: TEST', 0, currentY, fontSize: 12, align: TextAlign.center);
    currentY += lineHeight;

    // แปลงเป็นรูปภาพ PNG
    final picture = recorder.endRecording();
    final actualHeight = currentY + padding * 2;

    // สร้างรูปภาพตามขนาดจริงที่ใช้ ไม่ใช่ขนาดที่ตั้งไว้ตอนแรก
    final ui.Image img = await picture.toImage(width, actualHeight.ceil());

    // ลองลดคุณภาพรูปภาพเพื่อให้ขนาดไฟล์เล็กลง
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    return byteData?.buffer.asUint8List();
  }
}
