// lib/ui/screens/sale/sale_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wawa_vansales/blocs/cart/cart_bloc.dart';
import 'package:wawa_vansales/blocs/cart/cart_event.dart';
import 'package:wawa_vansales/blocs/cart/cart_state.dart';
import 'package:wawa_vansales/blocs/sales_summary/sales_summary_bloc.dart';
import 'package:wawa_vansales/blocs/sales_summary/sales_summary_event.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/services/printer_status_provider.dart';
import 'package:wawa_vansales/data/services/receipt_printer_service.dart';
import 'package:wawa_vansales/ui/screens/home_screen.dart';
import 'package:wawa_vansales/ui/screens/sale/print_receipt_dialog.dart';
import 'package:wawa_vansales/ui/screens/sale/sale_cart_step.dart';
import 'package:wawa_vansales/ui/screens/sale/sale_customer_step.dart';
import 'package:wawa_vansales/ui/screens/sale/sale_payment_step.dart';
import 'package:wawa_vansales/ui/screens/sale/sale_stepper_widget.dart';
import 'package:wawa_vansales/ui/screens/sale/sale_summary_step.dart';
import 'package:wawa_vansales/utils/global.dart';
import 'package:wawa_vansales/utils/local_storage.dart';

class SaleScreen extends StatefulWidget {
  final bool isFromPreOrder;
  final bool startAtCart;
  final String? preOrderDocNo; // เพิ่มพารามิเตอร์สำหรับเลขที่เอกสาร pre-order

  const SaleScreen({
    super.key,
    this.isFromPreOrder = false,
    this.startAtCart = false,
    this.preOrderDocNo,
  });

  @override
  State<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  final PageController _pageController = PageController();
  final ReceiptPrinterService _printerService = ReceiptPrinterService();

  // ignore: unused_field
  BluetoothDevice? _connectedDevice;
  String _warehouseCode = 'NA';
  String _empCode = 'NA';

  // ignore: unused_field
  final bool _isPrinting = false;

  String preOrderDocNo = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _warehouseCode = Global.whCode;
        _empCode = Global.empCode;
      });

      if (Global.empCode.isEmpty) {
        _loadUserData();
      }

      // ถ้ามาจาก PreOrderDetailScreen ให้ใช้เลขที่เอกสารนั้น
      if (widget.isFromPreOrder && widget.preOrderDocNo != null) {
        preOrderDocNo = widget.preOrderDocNo!;
        // ตั้งค่า preOrderDocNo ใน CartBloc ด้วย
        context.read<CartBloc>().add(SetPreOrderDocument(widget.preOrderDocNo!));
      }

      // กำหนด step ตามพารามิเตอร์
      if (widget.startAtCart) {
        // กำหนด step เป็น 1 ให้แน่ใจว่าจะแสดงหน้าตะกร้าสินค้า
        _pageController.jumpToPage(1); // ใช้ jumpToPage แทน animate เพื่อหลีกเลี่ยงการทำงานไม่ถูกต้อง
        context.read<CartBloc>().add(const UpdateStep(1)); // แน่ใจว่ามีการตั้งค่า step ใน bloc ด้วย
      } else if (widget.isFromPreOrder) {
        _pageController.jumpToPage(2); // ไปที่หน้าชำระเงิน
        context.read<CartBloc>().add(const UpdateStep(2)); // แน่ใจว่ามีการตั้งค่า step ใน bloc ด้วย
      }
    });

    _checkPrinterConnection();
  }

  Future<void> _loadUserData() async {
    // สร้าง Instance ของ LocalStorage
    final prefs = await SharedPreferences.getInstance();
    const secureStorage = FlutterSecureStorage();
    final localStorage = LocalStorage(
      prefs: prefs,
      secureStorage: secureStorage,
    );

    final user = await localStorage.getUserData();
    if (user != null && user.userCode.isNotEmpty) {
      // set ค่าให้ Global
      await Global.setEmpCode(localStorage, user.userCode);
      setState(() {
        _empCode = user.userCode;
      });
    }
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
    bool isConnected = await _printerService.checkConnection();
    if (!isConnected && mounted) {
      _printerService.autoConnect();
    }
  }

  Future<void> _printReceipt(CartSubmitSuccess state, String receiptType) async {
    final printerStatus = Provider.of<PrinterStatusProvider>(context, listen: false);

    // ถ้าเครื่องพิมพ์ไม่ได้เชื่อมต่อ ให้พยายามเชื่อมต่อก่อน
    if (!printerStatus.isConnected) {
      // แสดง dialog กำลังเชื่อมต่อ
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          title: Text('กำลังเชื่อมต่อเครื่องพิมพ์'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('กำลังค้นหาและเชื่อมต่อเครื่องพิมพ์...'),
            ],
          ),
        ),
      );

      // พยายามเชื่อมต่อ
      final connected = await printerStatus.connectPrinter();

      // ปิด dialog
      if (mounted) Navigator.of(context).pop();

      // ถ้าเชื่อมต่อไม่สำเร็จ แสดงข้อความและถามว่าต้องการดำเนินการต่อหรือไม่
      if (!connected && mounted) {
        final continueWithoutPrinter = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('ไม่สามารถเชื่อมต่อเครื่องพิมพ์'),
                content: const Text('ไม่พบเครื่องพิมพ์หรือไม่สามารถเชื่อมต่อได้ คุณต้องการดำเนินการต่อโดยไม่พิมพ์ใบเสร็จหรือไม่?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('ยกเลิก'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('ดำเนินการต่อ'),
                  ),
                ],
              ),
            ) ??
            false;

        if (!continueWithoutPrinter) {
          return;
        }
      }
    }

    // แสดง loading dialog และเริ่มกระบวนการพิมพ์
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => false, // ป้องกันการกดปุ่ม back
          child: AlertDialog(
            title: const Text('กำลังพิมพ์ใบเสร็จ'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('กำลังพิมพ์ใบเสร็จเลขที่: ${state.documentNumber}'),
                const SizedBox(height: 8),
                const Text('โปรดรอสักครู่...', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );

    // เริ่มพิมพ์ใบเสร็จในแบ็คกราวนด์
    try {
      final printerService = ReceiptPrinterService();
      bool printSuccess = await printerService.printReceipt(
        customer: state.customer,
        items: state.items,
        payments: state.payments,
        totalAmount: state.totalAmount,
        docNumber: state.documentNumber,
        warehouseCode: _warehouseCode,
        empCode: _empCode,
        receiptType: receiptType,
      );

      // ปิด loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (printSuccess) {
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

        // ทำการพิมพ์ซ้ำถ้าผู้ใช้เลือก
        if (printResult == 'reprint') {
          // (โค้ดการพิมพ์ซ้ำเหมือนเดิม)
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่สามารถพิมพ์ได้ กรุณาเชื่อมต่อเครื่องพิมพ์'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      // จัดการข้อผิดพลาด
      if (mounted) {
        Navigator.of(context).pop(); // ปิด loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการพิมพ์: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
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

                        /// home screen
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => false,
                        );
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
            listenWhen: (previous, current) {
              // คืนค่า true เมื่อเราต้องการให้ listener ทำงาน
              return current is CartError || current is CartSubmitSuccess || current is CartSubmitting;
            },
            listener: (context, state) async {
              // ปิด dialog กรณีที่มี dialog กำลังแสดงอยู่ เมื่อได้รับ state เป็น CartError
              if (state is CartError) {
                // ตรวจสอบว่ามี dialog ที่กำลังแสดงอยู่หรือไม่
                // แล้วปิด dialog ก่อนแสดง SnackBar
                Navigator.of(context).popUntil((route) => route.isActive);

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

                // รีเฟรชข้อมูลยอดขายวันนี้
                context.read<SalesSummaryBloc>().add(RefreshTodaysSalesSummary());

                // ถามว่าต้องการพิมพ์ใบเสร็จหรือไม่
                final receiptChoice = await PrintReceiptDialog.show(
                  context,
                  documentNumber: state.documentNumber,
                  customer: state.customer,
                );
                final bool shouldPrint = receiptChoice != null && receiptChoice['print'] == true;
                final String receiptType = receiptChoice != null ? receiptChoice['receiptType'] ?? 'taxReceipt' : 'taxReceipt';

                if (shouldPrint) {
                  await _printReceipt(state, receiptType);
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
                            isFromPreOrder: widget.isFromPreOrder, // ส่งค่า isFromPreOrder ไปยัง SaleCartStep
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
                              isConnected: _printerService.isConnected,
                              isConnecting: _printerService.isConnecting,
                              onReconnectPrinter: () async {
                                return await _printerService.connectPrinter();
                              },
                              empCode: _empCode,
                              preOrderDocNumber: preOrderDocNo, // ส่งเลขที่เอกสาร preOrder ถ้ามาจาก PreOrderDetailScreen
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
