// lib/ui/screens/sale/sale_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';
import 'package:wawa_vansales/blocs/cart/cart_bloc.dart';
import 'package:wawa_vansales/blocs/cart/cart_event.dart';
import 'package:wawa_vansales/blocs/cart/cart_state.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/models/cart_item_model.dart';
import 'package:wawa_vansales/data/models/customer_model.dart';
import 'package:wawa_vansales/data/models/payment_model.dart';
import 'package:wawa_vansales/ui/screens/home_screen.dart';
import 'package:wawa_vansales/ui/screens/sale/sale_cart_step.dart';
import 'package:wawa_vansales/ui/screens/sale/sale_customer_step.dart';
import 'package:wawa_vansales/ui/screens/sale/sale_payment_step.dart';
import 'package:wawa_vansales/ui/screens/sale/sale_stepper_widget.dart';
import 'package:wawa_vansales/ui/screens/sale/sale_summary_step.dart';
import 'package:wawa_vansales/utils/global.dart';
import 'dart:ui' as ui;

class SaleScreen extends StatefulWidget {
  const SaleScreen({super.key});

  @override
  State<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  final PageController _pageController = PageController();
  final BlueThermalPrinter _printer = BlueThermalPrinter.instance;
  bool _isConnected = false;
  bool _isConnecting = false;
  // ignore: unused_field
  BluetoothDevice? _connectedDevice;
  String _warehouseCode = 'NA';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _warehouseCode = Global.whCode;
      });
    });
    _checkPrinterConnection();
    _autoConnectPrinter();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    final cartState = context.read<CartBloc>().state;
    if (cartState is CartLoaded) {
      if (step == 1 && cartState.selectedCustomer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเลือกลูกค้าก่อน')),
        );
        return;
      }
      if (step == 2 && cartState.items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเพิ่มสินค้าในตะกร้าก่อน')),
        );
        return;
      }
      if (step == 3 && !cartState.isFullyPaid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาชำระเงินให้ครบก่อน')),
        );
        return;
      }
    }
    context.read<CartBloc>().add(UpdateStep(step));
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _connectedDevice = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  Future<void> _autoConnectPrinter() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!_isConnected && mounted) {
      await _connectPrinter();
    }
  }

  Future<Uint8List?> _createReceiptImage(
    CustomerModel customer,
    List<CartItemModel> items,
    List<PaymentModel> payments,
    double totalAmount,
  ) async {
    const int width = 384;
    const int padding = 20;
    const double lineHeight = 22.0;

    int itemsHeight = items.length * 44;
    int paymentsHeight = payments.length * 30;
    int height = 550 + itemsHeight + paymentsHeight;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    paint.color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), paint);

    final NumberFormat currencyFormat = NumberFormat('#,##0.00', 'th_TH');

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

    void drawDivider(double y, {bool isDashed = false}) {
      paint.color = Colors.grey;
      paint.strokeWidth = 1;

      if (isDashed) {
        for (double x = padding.toDouble(); x < width - padding; x += 5) {
          canvas.drawLine(Offset(x, y), Offset(x + 2, y), paint);
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

    drawText('ใบเสร็จรับเงิน/ใบกำกับภาษีอย่างย่อ', 0, currentY, fontSize: 20, isBold: true, align: TextAlign.center);
    currentY += lineHeight * 1.5;

    drawText('WAWA Van Sales', 0, currentY, fontSize: 18, align: TextAlign.center);
    currentY += lineHeight;

    drawText('บริษัท วาวา จำกัด', 0, currentY, fontSize: 14, align: TextAlign.center);
    currentY += lineHeight;

    currentY += 10.0;
    drawDivider(currentY);
    currentY += 15.0;

    final now = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(now);
    drawText('เลขที่: INV${_warehouseCode}${now.microsecondsSinceEpoch}', padding.toDouble(), currentY, fontSize: 14);
    drawText(dateStr, 0, currentY, fontSize: 14, align: TextAlign.right);
    currentY += lineHeight;

    drawText('ลูกค้า: ${customer.name}', padding.toDouble(), currentY, fontSize: 14);
    currentY += lineHeight;
    drawText('รหัส: ${customer.code}', padding.toDouble(), currentY, fontSize: 14);
    currentY += lineHeight;

    currentY += 10.0;
    drawDivider(currentY);
    currentY += 15.0;

    for (var item in items) {
      final qtyValue = double.tryParse(item.qty) ?? 0;
      final priceValue = double.tryParse(item.price) ?? 0;
      drawText(item.itemName, padding.toDouble(), currentY, fontSize: 14);
      currentY += lineHeight;

      drawText('${qtyValue.toStringAsFixed(0)} x ${currencyFormat.format(priceValue)}', width * 0.6, currentY, fontSize: 14);
      drawText(currencyFormat.format(item.totalAmount), 0, currentY, fontSize: 14, align: TextAlign.right);
      currentY += lineHeight * 1.2;
    }

    drawDivider(currentY);
    currentY += 15.0;

    drawText('ยอดรวม', padding.toDouble(), currentY, fontSize: 16, isBold: true);
    drawText(currencyFormat.format(totalAmount), 0, currentY, fontSize: 16, isBold: true, align: TextAlign.right);
    currentY += lineHeight * 1.5;

    for (var payment in payments) {
      drawText('เงินสด', padding.toDouble(), currentY, fontSize: 14);
      drawText(currencyFormat.format(payment.payAmount), 0, currentY, fontSize: 14, align: TextAlign.right);
      currentY += lineHeight;
    }

    currentY += 10.0;
    drawDivider(currentY);
    currentY += 15.0;

    drawText('ขอบคุณที่ใช้บริการ', 0, currentY, fontSize: 16, align: TextAlign.center);

    final picture = recorder.endRecording();
    final img = await picture.toImage(width, height);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    return byteData?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final cartState = context.read<CartBloc>().state;
        if (cartState is CartLoaded && cartState.items.isNotEmpty) {
          final bool shouldPop = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('ยืนยันการออก'),
                  content: const Text('คุณต้องการออกจากหน้านี้หรือไม่? รายการสินค้าในตะกร้าจะถูกล้าง'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('ยกเลิก'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        context.read<CartBloc>().add(ClearCart());
                        Navigator.of(context).pop(true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                      ),
                      child: const Text('ออก', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ) ??
              false;
          return shouldPop;
        } else {
          _goToStep(0);
          context.read<CartBloc>().add(ClearCart());
        }
        return true;
      },
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('ขายสินค้า'),
          ),
          body: BlocConsumer<CartBloc, CartState>(
            // แก้ไขในส่วน BlocConsumer ของ sale_screen.dart
            listener: (context, state) async {
              if (state is CartError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              } else if (state is CartSubmitSuccess) {
                // แจ้งเตือนว่าบันทึกสำเร็จ
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('บันทึกการขายเรียบร้อยแล้ว'),
                    backgroundColor: Colors.green,
                  ),
                );

                // ถามว่าต้องการพิมพ์ใบเสร็จหรือไม่
                final shouldPrint = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    title: const Text('การขายสำเร็จ'),
                    content: Text('เลขที่เอกสาร: ${state.documentNumber}\nคุณต้องการพิมพ์ใบเสร็จหรือไม่?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('ไม่พิมพ์'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('พิมพ์ใบเสร็จ'),
                      ),
                    ],
                  ),
                );

                if (shouldPrint == true) {
                  // แสดง loading dialog
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const AlertDialog(
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('กำลังพิมพ์ใบเสร็จ...'),
                        ],
                      ),
                    ),
                  );

                  // พิมพ์ใบเสร็จ
                  if (_isConnected) {
                    try {
                      final receiptImage = await _createReceiptImage(
                        state.customer,
                        state.items,
                        state.payments,
                        state.totalAmount,
                      );

                      if (receiptImage != null) {
                        await _printer.printImageBytes(receiptImage);

                        // ปิด loading dialog
                        Navigator.of(context).pop();

                        // แสดง dialog ยืนยันการพิมพ์
                        final printResult = await showDialog<String>(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => AlertDialog(
                            title: const Text('พิมพ์ใบเสร็จเสร็จสิ้น'),
                            content: const Text('พิมพ์ใบเสร็จเรียบร้อยแล้ว'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop('reprint'),
                                child: const Text('พิมพ์ใหม่'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(context).pop('done'),
                                child: const Text('ยืนยัน'),
                              ),
                            ],
                          ),
                        );

                        if (printResult == 'reprint') {
                          // พิมพ์ใหม่
                          await _printer.printImageBytes(receiptImage);
                        }
                      }
                    } catch (e) {
                      // ปิด loading dialog
                      Navigator.of(context).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('เกิดข้อผิดพลาดในการพิมพ์: $e'),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                    }
                  } else {
                    // ปิด loading dialog
                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ไม่สามารถพิมพ์ได้ กรุณาเชื่อมต่อเครื่องพิมพ์'),
                        backgroundColor: AppTheme.errorColor,
                      ),
                    );
                  }
                }

                // รีเซ็ตตะกร้าและกลับหน้าหลัก
                context.read<CartBloc>().add(ClearCart());
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              }
            },
            builder: (context, state) {
              if (state is CartLoaded) {
                return Column(
                  children: [
                    // Stepper Widget
                    SaleStepperWidget(
                      currentStep: state.currentStep,
                      isCustomerSelected: state.selectedCustomer != null,
                      hasItems: state.items.isNotEmpty,
                      isFullyPaid: state.isFullyPaid,
                    ),
                    // เนื้อหาแต่ละ Step
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          // Step 1: เลือกลูกค้า
                          SaleCustomerStep(
                            selectedCustomer: state.selectedCustomer,
                            onNextStep: () => _goToStep(1),
                          ),
                          // Step 2: เลือกสินค้า
                          SaleCartStep(
                            cartItems: state.items,
                            totalAmount: state.totalAmount,
                            onNextStep: () => _goToStep(2),
                            onBackStep: () => _goToStep(0),
                          ),
                          // Step 3: ชำระเงิน
                          SalePaymentStep(
                            totalAmount: state.totalAmount,
                            payments: state.payments,
                            remainingAmount: state.remainingAmount,
                            onBackStep: () => _goToStep(1),
                            onNextStep: () => _goToStep(3),
                          ),
                          // Step 4: สรุปรายการ + พิมพ์ใบเสร็จ
                          if (state.selectedCustomer != null)
                            SaleSummaryStep(
                              customer: state.selectedCustomer!,
                              items: state.items,
                              payments: state.payments,
                              totalAmount: state.totalAmount,
                              onBackStep: () => _goToStep(2),
                              isConnected: _isConnected,
                              isConnecting: _isConnecting,
                              onReconnectPrinter: _connectPrinter,
                              createReceiptImage: () => _createReceiptImage(
                                state.selectedCustomer!,
                                state.items,
                                state.payments,
                                state.totalAmount,
                              ),
                            )
                          else
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.warning, size: 48, color: AppTheme.errorColor),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'ไม่พบข้อมูลลูกค้า',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'กรุณากลับไปเลือกลูกค้าก่อน',
                                    style: TextStyle(color: AppTheme.textSecondary),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: () => _goToStep(0),
                                    icon: const Icon(Icons.arrow_back),
                                    label: const Text('กลับไปเลือกลูกค้า'),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              } else if (state is CartSubmitting) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('กำลังบันทึกการขาย...'),
                    ],
                  ),
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
        ),
      ),
    );
  }
}
