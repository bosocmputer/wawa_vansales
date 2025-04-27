// lib/ui/screens/sale/sale_summary_step.dart
// ignore_for_file: use_build_context_synchronously

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wawa_vansales/blocs/cart/cart_bloc.dart';
import 'package:wawa_vansales/blocs/cart/cart_event.dart';
import 'package:wawa_vansales/blocs/cart/cart_state.dart';
import 'package:wawa_vansales/data/models/cart_item_model.dart';
import 'package:wawa_vansales/data/models/customer_model.dart';
import 'package:wawa_vansales/data/models/payment_model.dart';
import 'package:wawa_vansales/ui/screens/sale/receipt_preview_widget.dart';
import 'package:wawa_vansales/ui/widgets/custom_button.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class SaleSummaryStep extends StatefulWidget {
  final CustomerModel customer;
  final List<CartItemModel> items;
  final List<PaymentModel> payments;
  final double totalAmount;
  final VoidCallback onBackStep;
  final String warehouseCode;

  const SaleSummaryStep({
    super.key,
    required this.customer,
    required this.items,
    required this.payments,
    required this.totalAmount,
    required this.onBackStep,
    required this.warehouseCode,
  });

  @override
  State<SaleSummaryStep> createState() => _SaleSummaryStepState();
}

class _SaleSummaryStepState extends State<SaleSummaryStep> {
  final BlueThermalPrinter _printer = BlueThermalPrinter.instance;
  final NumberFormat _currencyFormat = NumberFormat('#,##0.00', 'th_TH');
  // ignore: unused_field
  bool _isPrinting = false;
  bool _isConnecting = false;
  bool _isSaving = false;
  bool _isConnected = false;
  BluetoothDevice? _connectedDevice;

  @override
  void initState() {
    super.initState();
    _checkPrinterConnection();
    _autoConnectPrinter();
  }

  Future<void> _autoConnectPrinter() async {
    // รอสักครู่ให้ widget สร้างเสร็จ
    await Future.delayed(const Duration(milliseconds: 500));

    // ถ้ายังไม่เชื่อมต่อ ให้ลองเชื่อมต่ออัตโนมัติ
    if (!_isConnected && mounted) {
      await _connectPrinter();
    }
  }

  Future<void> _checkPrinterConnection() async {
    try {
      bool? isConnected = await _printer.isConnected;
      if (isConnected == true) {
        List<BluetoothDevice> devices = await _printer.getBondedDevices();
        for (var device in devices) {
          if (device.name == "InnerPrinter") {
            setState(() {
              _isConnected = true;
              _connectedDevice = device;
            });
            break;
          }
        }
      } else {
        setState(() {
          _isConnected = false;
          _connectedDevice = null;
        });
      }
    } catch (e) {
      setState(() {
        _isConnected = false;
        _connectedDevice = null;
      });
    }
  }

  Future<void> _connectPrinter() async {
    setState(() {
      _isConnecting = true;
    });

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
        await _printer.connect(innerPrinter);

        if (mounted) {
          setState(() {
            _isConnected = true;
            _connectedDevice = innerPrinter;
          });
          // แสดงข้อความสำเร็จเฉพาะเมื่อเชื่อมต่อด้วยการกดปุ่ม ไม่ใช่การเชื่อมต่ออัตโนมัติ
          if (!_isConnecting) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('เชื่อมต่อเครื่องพิมพ์สำเร็จ')),
            );
          }
        }
      } else {
        throw Exception('ไม่พบเครื่องพิมพ์');
      }
    } catch (e) {
      if (mounted) {
        // แสดงข้อความแจ้งเตือนเฉพาะเมื่อเชื่อมต่อด้วยการกดปุ่ม
        if (!_isConnecting) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  Future<void> _printReceipt() async {
    setState(() {
      _isPrinting = true;
    });

    try {
      if (!_isConnected || _connectedDevice == null) {
        throw Exception('ไม่ได้เชื่อมต่อเครื่องพิมพ์');
      }

      // สร้างภาพสลิป
      final slipImage = await _createReceiptImage();
      if (slipImage != null) {
        await _printer.printImageBytes(slipImage);
        await _printer.printNewLine();
        await _printer.printNewLine();
        await _printer.printNewLine();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('พิมพ์ใบเสร็จสำเร็จ')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
      }
    }
  }

  Future<void> _showSaveConfirmDialog() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการบันทึก'),
        content: const Text('คุณต้องการบันทึกรายการขายนี้หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isSaving = true;
      });

      context.read<CartBloc>().add(const SubmitSale());
    }
  }

  Future<Uint8List?> _createReceiptImage() async {
    // ขนาดกระดาษ 58mm ≈ 384px
    const int width = 384;
    const int padding = 20;
    const double lineHeight = 22.0;

    // คำนวณความสูงของสลิป
    int itemsHeight = widget.items.length * 44; // แต่ละรายการใช้พื้นที่ประมาณ 44px
    int paymentsHeight = widget.payments.length * 30; // แต่ละการชำระใช้พื้นที่ประมาณ 30px
    int height = 550 + itemsHeight + paymentsHeight; // พื้นที่ส่วนหัว + รายการ + การชำระ + ส่วนท้าย

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    // พื้นหลังขาว
    paint.color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), paint);

    // ฟังก์ชันช่วยในการวาดข้อความ
    void drawText(String text, double x, double y, {double fontSize = 16, bool isBold = false, TextAlign align = TextAlign.left}) {
      final textSpan = TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.black,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
        textAlign: align,
      );
      textPainter.layout(minWidth: 0, maxWidth: (width - (padding * 2)).toDouble());

      double xPos = x;
      if (align == TextAlign.center) {
        xPos = (width - textPainter.width) / 2;
      } else if (align == TextAlign.right) {
        xPos = width - padding - textPainter.width;
      }

      textPainter.paint(canvas, Offset(xPos, y));
    }

    // ฟังก์ชันวาดเส้นคั่น
    void drawDivider(double y, {bool isDashed = false}) {
      paint.color = Colors.grey;
      paint.strokeWidth = 1;

      if (isDashed) {
        for (double x = padding.toDouble(); x < width - padding; x += 5) {
          canvas.drawLine(
            Offset(x, y),
            Offset(x + 2, y),
            paint,
          );
        }
      } else {
        canvas.drawLine(
          Offset(padding.toDouble(), y),
          Offset((width - padding).toDouble(), y),
          paint,
        );
      }
    }

    double currentY = padding.toDouble();

    // ส่วนหัว
    drawText('ใบเสร็จรับเงิน/ใบกำกับภาษีอย่างย่อ', 0, currentY, fontSize: 20, isBold: true, align: TextAlign.center);
    currentY += lineHeight * 1.5;

    drawText('WAWA Van Sales', 0, currentY, fontSize: 18, align: TextAlign.center);
    currentY += lineHeight;

    drawText('บริษัท วาวา จำกัด', 0, currentY, fontSize: 14, align: TextAlign.center);
    currentY += lineHeight;

    // เลขที่เอกสารและวันที่
    currentY += 10.0;
    drawDivider(currentY);
    currentY += 15.0;

    final now = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(now);
    drawText('เลขที่: ${_generateDocNumber()}', padding.toDouble(), currentY, fontSize: 14);
    drawText(dateStr, 0, currentY, fontSize: 14, align: TextAlign.right);
    currentY += lineHeight;

    // ข้อมูลลูกค้า
    currentY += 5.0;
    drawText('ลูกค้า: ${widget.customer.name}', padding.toDouble(), currentY, fontSize: 14);
    currentY += lineHeight;
    drawText('รหัส: ${widget.customer.code}', padding.toDouble(), currentY, fontSize: 14);
    currentY += lineHeight;

    if (widget.customer.taxId!.isNotEmpty) {
      drawText('เลขประจำตัวผู้เสียภาษี: ${widget.customer.taxId}', padding.toDouble(), currentY, fontSize: 14);
      currentY += lineHeight;
    }

    // รายการสินค้า
    currentY += 10.0;
    drawDivider(currentY);
    currentY += 15.0;

    // หัวตาราง
    drawText('รายการ', padding.toDouble(), currentY, fontSize: 14, isBold: true);
    drawText('จำนวน', width * 0.6, currentY, fontSize: 14, isBold: true);
    drawText('ราคา', 0, currentY, fontSize: 14, isBold: true, align: TextAlign.right);
    currentY += lineHeight;
    drawDivider(currentY, isDashed: true);
    currentY += 10.0;

    // รายการสินค้า
    for (var item in widget.items) {
      final qtyValue = double.tryParse(item.qty) ?? 0;
      final priceValue = double.tryParse(item.price) ?? 0;

      // ชื่อสินค้า
      drawText(item.itemName, padding.toDouble(), currentY, fontSize: 14);
      currentY += lineHeight;

      // จำนวนและราคา
      drawText('${qtyValue.toStringAsFixed(0)} x ${_currencyFormat.format(priceValue)}', width * 0.6, currentY, fontSize: 14);
      drawText(_currencyFormat.format(item.totalAmount), 0, currentY, fontSize: 14, align: TextAlign.right);
      currentY += lineHeight * 1.2;
    }

    // ยอดรวม
    drawDivider(currentY);
    currentY += 15.0;

    drawText('ยอดรวม', padding.toDouble(), currentY, fontSize: 16, isBold: true);
    drawText(_currencyFormat.format(widget.totalAmount), 0, currentY, fontSize: 16, isBold: true, align: TextAlign.right);
    currentY += lineHeight * 1.5;

    // รายละเอียดการชำระเงิน
    for (var payment in widget.payments) {
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

      drawText(paymentText, padding.toDouble(), currentY, fontSize: 14);
      drawText(_currencyFormat.format(payment.payAmount), 0, currentY, fontSize: 14, align: TextAlign.right);
      currentY += lineHeight;

      if (payment.transNumber.isNotEmpty) {
        drawText('อ้างอิง: ${payment.transNumber}', (padding + 20).toDouble(), currentY, fontSize: 12);
        currentY += lineHeight;
      }
    }

    // ส่วนท้าย
    currentY += 10.0;
    drawDivider(currentY);
    currentY += 15.0;

    drawText('ขอบคุณที่ใช้บริการ', 0, currentY, fontSize: 16, align: TextAlign.center);
    currentY += lineHeight * 1.5;

    drawText('พนักงานขาย: TEST', 0, currentY, fontSize: 14, align: TextAlign.center);

    // แปลงเป็น image
    final picture = recorder.endRecording();
    final img = await picture.toImage(width, height);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    return byteData?.buffer.asUint8List();
  }

  String _generateDocNumber() {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final random = (1000 + (9999 - 1000) * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000).floor().toString();
    return 'INV${widget.warehouseCode}$dateStr-$random';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CartBloc, CartState>(
      listener: (context, state) {
        if (state is CartSubmitSuccess) {
          setState(() {
            _isSaving = false;
          });

          // ถามว่าต้องการพิมพ์ใบเสร็จหรือไม่
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('บันทึกเรียบร้อย'),
              content: const Text('ต้องการพิมพ์ใบเสร็จหรือไม่?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // กลับไปหน้าหลัก
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('ไม่พิมพ์'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    if (_isConnected) {
                      await _printReceipt();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('กรุณาเชื่อมต่อเครื่องพิมพ์ก่อน')),
                      );
                    }
                    // กลับไปหน้าหลัก
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('พิมพ์ใบเสร็จ'),
                ),
              ],
            ),
          );
        } else if (state is CartError) {
          setState(() {
            _isSaving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: ${state.message}')),
          );
        }
      },
      child: _isSaving
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('กำลังบันทึกรายการขาย...'),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // สถานะการเชื่อมต่อเครื่องพิมพ์
                        _buildPrinterStatus(),
                        const SizedBox(height: 16),

                        // แสดงตัวอย่างใบเสร็จ
                        const Center(
                          child: Text(
                            'ตัวอย่างใบเสร็จ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: ReceiptPreviewWidget(
                            customer: widget.customer,
                            items: widget.items,
                            payments: widget.payments,
                            totalAmount: widget.totalAmount,
                            docNumber: _generateDocNumber(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ปุ่มดำเนินการ
                _buildBottomActions(),
              ],
            ),
    );
  }

  Widget _buildPrinterStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _isConnected ? Icons.print : Icons.print_disabled,
              color: _isConnected ? Colors.green : Colors.red,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isConnected ? 'เชื่อมต่อเครื่องพิมพ์แล้ว' : 'กำลังเชื่อมต่อเครื่องพิมพ์อัตโนมัติ...',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _isConnected ? Colors.green : Colors.orange,
                    ),
                  ),
                  if (_isConnected && _connectedDevice != null)
                    Text(
                      'เครื่องพิมพ์: ${_connectedDevice!.name}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  if (!_isConnected)
                    const Text(
                      'ระบบกำลังค้นหาเครื่องพิมพ์',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
            if (!_isConnected)
              ElevatedButton(
                onPressed: _isConnecting ? null : _connectPrinter,
                child: _isConnecting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('เชื่อมต่อใหม่'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomButton(
              text: 'ย้อนกลับ',
              onPressed: widget.onBackStep,
              buttonType: ButtonType.outline,
              icon: const Icon(Icons.arrow_back),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: CustomButton(
              text: 'บันทึกรายการขาย',
              onPressed: _showSaveConfirmDialog,
              icon: const Icon(Icons.check_circle, color: Colors.white),
              buttonType: ButtonType.primary,
            ),
          ),
        ],
      ),
    );
  }
}
