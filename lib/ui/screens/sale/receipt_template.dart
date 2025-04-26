// receipt_template.dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:wawa_vansales/data/models/receipt_model.dart';

class ReceiptTemplate {
  static const int receiptWidth = 384; // ความกว้างเครื่องพิมพ์ 58mm
  static const double padding = 10.0;

  static Future<Uint8List> generateReceiptImage(ReceiptModel receipt) async {
    // คำนวณความสูงของใบเสร็จ
    int receiptHeight = 700 + (receipt.items!.length * 40);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    // พื้นหลังขาว
    paint.color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, receiptWidth.toDouble(), receiptHeight.toDouble()),
      paint,
    );

    double yPosition = 20;

    // ส่วนหัวกระดาษ - ชื่อร้าน
    _drawText(
      canvas,
      "WAWA Shop Service",
      20, // ลดขนาดฟอนต์ลง
      FontWeight.bold,
      TextAlign.center,
      yPosition,
      width: receiptWidth.toDouble(),
    );
    yPosition += 35;

    // ที่อยู่และเบอร์โทร
    _drawText(
      canvas,
      "123 ถ.สุขุมวิท กรุงเทพฯ 10110",
      12, // ลดขนาดฟอนต์ลง
      FontWeight.normal,
      TextAlign.center,
      yPosition,
      width: receiptWidth.toDouble(),
    );
    yPosition += 25;

    _drawText(
      canvas,
      "โทร: 02-123-4567",
      12, // ลดขนาดฟอนต์ลง
      FontWeight.normal,
      TextAlign.center,
      yPosition,
      width: receiptWidth.toDouble(),
    );
    yPosition += 35;

    // เส้นคั่น
    _drawDottedLine(canvas, yPosition, receiptWidth - padding * 2);
    yPosition += 20;

    // เลขที่ใบเสร็จ
    _drawText(
      canvas,
      "ใบเสร็จการขาย",
      14, // ลดขนาดฟอนต์ลง
      FontWeight.bold,
      TextAlign.center,
      yPosition,
      width: receiptWidth.toDouble(),
    );
    yPosition += 30;

    // รายละเอียดอื่นๆ (ลดขนาดฟอนต์ลง)
    _drawText(
      canvas,
      "เลขที่: ${receipt.docNo}",
      12,
      FontWeight.normal,
      TextAlign.left,
      yPosition,
      leftOffset: padding,
    );
    yPosition += 25;

    final formattedDate = _formatDate(receipt.date!);
    _drawText(
      canvas,
      "วันที่: $formattedDate",
      12,
      FontWeight.normal,
      TextAlign.left,
      yPosition,
      leftOffset: padding,
    );
    yPosition += 25;

    _drawText(
      canvas,
      "ลูกค้า: ${receipt.customerName}",
      12,
      FontWeight.normal,
      TextAlign.left,
      yPosition,
      leftOffset: padding,
    );
    yPosition += 25;

    _drawText(
      canvas,
      "รหัส: ${receipt.customerCode}",
      12,
      FontWeight.normal,
      TextAlign.left,
      yPosition,
      leftOffset: padding,
    );
    yPosition += 25;

    // เส้นคั่น
    _drawDottedLine(canvas, yPosition, receiptWidth - padding * 2);
    yPosition += 20;

    // หัวตารางสินค้า (ลดขนาดฟอนต์)
    _drawText(
      canvas,
      "รายการ",
      12,
      FontWeight.bold,
      TextAlign.left,
      yPosition,
      leftOffset: padding,
    );

    _drawText(
      canvas,
      "จำนวน",
      12,
      FontWeight.bold,
      TextAlign.center,
      yPosition,
      leftOffset: receiptWidth - 180,
    );

    _drawText(
      canvas,
      "ราคา",
      12,
      FontWeight.bold,
      TextAlign.center,
      yPosition,
      leftOffset: receiptWidth - 120,
    );

    _drawText(
      canvas,
      "รวม",
      12,
      FontWeight.bold,
      TextAlign.right,
      yPosition,
      width: receiptWidth - padding,
    );
    yPosition += 25;

    // เส้นคั่น
    _drawLine(canvas, yPosition, receiptWidth - padding * 2);
    yPosition += 15;

    // รายการสินค้า
    for (var item in receipt.items!) {
      // ชื่อสินค้า
      _drawText(
        canvas,
        item.itemName ?? '',
        12,
        FontWeight.normal,
        TextAlign.left,
        yPosition,
        leftOffset: padding,
        maxWidth: 160,
      );

      // จำนวน
      _drawText(
        canvas,
        "${item.quantity}",
        12,
        FontWeight.normal,
        TextAlign.center,
        yPosition,
        leftOffset: receiptWidth - 180,
      );

      // ราคา
      _drawText(
        canvas,
        item.price!,
        12,
        FontWeight.normal,
        TextAlign.center,
        yPosition,
        leftOffset: receiptWidth - 120,
      );

      // ราคารวม
      final total = double.parse(item.price!) * double.parse(item.quantity!);
      final numberFormat = NumberFormat('#,##0.00', 'th_TH');
      _drawText(
        canvas,
        numberFormat.format(total),
        12,
        FontWeight.normal,
        TextAlign.right,
        yPosition,
        width: receiptWidth - padding,
      );

      yPosition += 30;
    }

    // เส้นคั่น
    _drawLine(canvas, yPosition, receiptWidth - padding * 2);
    yPosition += 20;

    // ยอดรวม
    _drawText(
      canvas,
      "ยอดรวม",
      14,
      FontWeight.bold,
      TextAlign.left,
      yPosition,
      leftOffset: padding,
    );

    _drawText(
      canvas,
      receipt.totalAmount!,
      14,
      FontWeight.bold,
      TextAlign.right,
      yPosition,
      width: receiptWidth - padding,
    );
    yPosition += 40;

    // ข้อความขอบคุณ
    _drawText(
      canvas,
      "ขอบคุณที่ใช้บริการ",
      12,
      FontWeight.normal,
      TextAlign.center,
      yPosition,
      width: receiptWidth.toDouble(),
    );
    yPosition += 25;

    // เส้นคั่นสุดท้าย
    _drawDottedLine(canvas, yPosition, receiptWidth - padding * 2);

    // แปลงเป็น PNG
    final picture = recorder.endRecording();
    final img = await picture.toImage(receiptWidth, receiptHeight);

    // แปลงเป็น ByteData
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception('Failed to convert image to bytes');
    }

    return byteData.buffer.asUint8List();
  }

  static void _drawText(
    Canvas canvas,
    String text,
    double fontSize,
    FontWeight fontWeight,
    TextAlign textAlign,
    double yPosition, {
    double? width,
    double leftOffset = 0,
    double? maxWidth,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.black,
          fontWeight: fontWeight,
        ),
      ),
      textAlign: textAlign,
      textDirection: ui.TextDirection.ltr,
    );

    textPainter.layout(
      minWidth: width ?? 0,
      maxWidth: maxWidth ?? (width ?? receiptWidth.toDouble()),
    );

    textPainter.paint(canvas, Offset(leftOffset, yPosition));
  }

  static void _drawLine(Canvas canvas, double yPosition, double width) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(padding, yPosition),
      Offset(padding + width, yPosition),
      paint,
    );
  }

  static void _drawDottedLine(Canvas canvas, double yPosition, double width) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0;

    double startX = padding;
    const double dashWidth = 5;
    const double dashSpace = 3;

    while (startX < padding + width) {
      canvas.drawLine(
        Offset(startX, yPosition),
        Offset(startX + dashWidth, yPosition),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  static String _formatDate(String dateStr) {
    try {
      final dateTime = DateTime.parse(dateStr);
      final formatter = DateFormat('dd/MM/yyyy HH:mm', 'th_TH');
      return formatter.format(dateTime);
    } catch (e) {
      return dateStr;
    }
  }
}
