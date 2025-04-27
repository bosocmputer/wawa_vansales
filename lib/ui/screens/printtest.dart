import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class PrinterPage extends StatefulWidget {
  const PrinterPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PrinterPageState createState() => _PrinterPageState();
}

class _PrinterPageState extends State<PrinterPage> {
  final BlueThermalPrinter printer = BlueThermalPrinter.instance;
  TextEditingController textController = TextEditingController();
  final String printerAddress = "InnerPrinter";
  @override
  void initState() {
    super.initState();
    _connectToPrinter();
  }

  void _connectToPrinter() async {
    try {
      List<BluetoothDevice> devices = await printer.getBondedDevices();
      BluetoothDevice? deviceToConnect;

      for (var d in devices) {
        if (d.name == printerAddress) {
          deviceToConnect = d;
          break;
        }
      }

      if (deviceToConnect != null) {
        await printer.connect(deviceToConnect);
        // _printTest(); // พิมพ์หลังเชื่อมต่อ
      } else {
        if (kDebugMode) {
          print("❌ ไม่พบเครื่องพิมพ์ที่มี address: $printerAddress");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ ERROR: $e");
      }
    }
  }

  // ignore: unused_element
  void _printTest() {
    printer.printNewLine();
    printer.printCustom("Hello World", 2, 1); // ขนาดตัวอักษร 2, ตรงกลาง
    printer.printNewLine();
    printer.printCustom("This is a test print", 1, 0); // ขนาดตัวอักษร 1, ซ้าย
  }

  Future<void> _drawTextToImageAndPrint() async {
    // กำหนดขนาดภาพ (ความกว้างของเครื่องพิมพ์ thermal 58mm ≈ ~384px)
    const int width = 384;
    const int height = 200;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    // พื้นหลังขาว
    paint.color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), paint);

    // เขียนข้อความ
    final textPainter1 =
        TextPainter(text: const TextSpan(text: "Hello World", style: TextStyle(fontSize: 24, color: Colors.black)), textAlign: TextAlign.center, textDirection: TextDirection.ltr);

    final textPainter2 =
        TextPainter(text: const TextSpan(text: "สวัสดีจ้า", style: TextStyle(fontSize: 16, color: Colors.black)), textAlign: TextAlign.left, textDirection: TextDirection.ltr);

    textPainter1.layout(minWidth: width.toDouble());
    textPainter2.layout(minWidth: width.toDouble());

    textPainter1.paint(canvas, const Offset(0, 20));
    textPainter2.paint(canvas, const Offset(0, 70));

    final picture = recorder.endRecording();
    final ui.Image imgFinal = await picture.toImage(width, height);
    final byteData = await imgFinal.toByteData(format: ui.ImageByteFormat.png);

    final Uint8List pngBytes = byteData!.buffer.asUint8List();

    // ส่งไปพิมพ์
    printer.printImageBytes(pngBytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("เชื่อมต่อ Printer")),
      body: Column(
        children: [
          const Center(child: Text("กำลังเชื่อมต่อกับเครื่องพิมพ์...")),
          ElevatedButton(onPressed: _drawTextToImageAndPrint, child: const Text("พิมพ์ทดสอบ")),
          const Text('ทดสอบScanner'),
          TextField(controller: textController, decoration: const InputDecoration(labelText: "กรอกข้อความที่ต้องการพิมพ์")),
        ],
      ),
    );
  }
}
