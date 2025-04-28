// lib/ui/screens/printtest.dart (แก้ไขเพื่อความมั่นใจว่าทำงานได้)
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
  bool isConnected = false;
  bool isConnecting = false;
  String status = "กำลังเชื่อมต่อเครื่องพิมพ์...";

  @override
  void initState() {
    super.initState();
    _connectToPrinter();
  }

  void _connectToPrinter() async {
    setState(() {
      isConnecting = true;
      status = "กำลังเชื่อมต่อเครื่องพิมพ์...";
    });

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
        setState(() {
          isConnected = true;
          isConnecting = false;
          status = "เชื่อมต่อเครื่องพิมพ์สำเร็จ";
        });
      } else {
        setState(() {
          isConnected = false;
          isConnecting = false;
          status = "ไม่พบเครื่องพิมพ์ที่มีชื่อ: $printerAddress";
        });
        if (kDebugMode) {
          print("❌ ไม่พบเครื่องพิมพ์ที่มี address: $printerAddress");
        }
      }
    } catch (e) {
      setState(() {
        isConnected = false;
        isConnecting = false;
        status = "เกิดข้อผิดพลาดในการเชื่อมต่อ: $e";
      });
      if (kDebugMode) {
        print("❌ ERROR: $e");
      }
    }
  }

  Future<void> _drawTextToImageAndPrint() async {
    if (!isConnected) {
      setState(() {
        status = "กรุณาเชื่อมต่อเครื่องพิมพ์ก่อน";
      });
      return;
    }

    setState(() {
      status = "กำลังสร้างและพิมพ์ภาพ...";
    });

    try {
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
      final textPainter1 = TextPainter(
          text: const TextSpan(text: "Hello World", style: TextStyle(fontSize: 24, color: Colors.black)), textAlign: TextAlign.center, textDirection: TextDirection.ltr);

      final textPainter2 =
          TextPainter(text: const TextSpan(text: "สวัสดีจ้า", style: TextStyle(fontSize: 16, color: Colors.black)), textAlign: TextAlign.left, textDirection: TextDirection.ltr);

      textPainter1.layout(minWidth: width.toDouble());
      textPainter2.layout(minWidth: width.toDouble());

      textPainter1.paint(canvas, const Offset(0, 20));
      textPainter2.paint(canvas, const Offset(0, 70));

      final picture = recorder.endRecording();
      final ui.Image imgFinal = await picture.toImage(width, height);
      final byteData = await imgFinal.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();

        // ส่งไปพิมพ์
        await printer.printImageBytes(pngBytes);

        // เพิ่มบรรทัดว่าง
        await printer.printNewLine();
        await printer.printNewLine();

        setState(() {
          status = "พิมพ์สำเร็จ";
        });
      } else {
        setState(() {
          status = "ไม่สามารถสร้างภาพได้";
        });
      }
    } catch (e) {
      setState(() {
        status = "เกิดข้อผิดพลาดในการพิมพ์: $e";
      });
      if (kDebugMode) {
        print("❌ Print Error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ทดสอบเครื่องพิมพ์")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // แสดงสถานะการเชื่อมต่อ
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isConnected ? Colors.green.shade100 : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isConnected ? Icons.check_circle : Icons.info_outline,
                    color: isConnected ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(status),
                  ),
                  if (isConnecting)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  if (!isConnected && !isConnecting)
                    TextButton(
                      onPressed: _connectToPrinter,
                      child: const Text("เชื่อมต่อใหม่"),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ปุ่มพิมพ์ทดสอบ
            ElevatedButton(
              onPressed: isConnected ? _drawTextToImageAndPrint : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text("พิมพ์ทดสอบ", style: TextStyle(fontSize: 16)),
            ),

            const SizedBox(height: 16),

            const Divider(),

            // ส่วนทดสอบอื่นๆ
            const Text('ทดสอบ Scanner', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                labelText: "กรอกข้อความที่ต้องการพิมพ์",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
