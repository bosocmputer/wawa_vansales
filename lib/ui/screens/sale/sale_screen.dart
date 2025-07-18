// lib/ui/screens/sale/sale_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:wawa_vansales/blocs/cart/cart_bloc.dart';
import 'package:wawa_vansales/blocs/cart/cart_event.dart';
import 'package:wawa_vansales/blocs/cart/cart_state.dart';
import 'package:wawa_vansales/blocs/sales_summary/sales_summary_bloc.dart';
import 'package:wawa_vansales/blocs/sales_summary/sales_summary_event.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/models/payment_model.dart';
import 'package:wawa_vansales/data/services/printer_status_provider.dart';
import 'package:wawa_vansales/data/services/receipt_printer_service.dart';
import 'package:wawa_vansales/ui/screens/home_screen.dart';
import 'package:wawa_vansales/ui/screens/sale/print_receipt_dialog.dart';
import 'package:wawa_vansales/ui/screens/sale/sale_cart_step.dart';
import 'package:wawa_vansales/ui/screens/sale/sale_customer_step.dart';
import 'package:wawa_vansales/ui/screens/sale/sale_payment_step.dart';
import 'package:wawa_vansales/ui/screens/sale/sale_stepper_widget.dart';
import 'package:wawa_vansales/ui/screens/sale/sale_summary_step.dart';
import 'package:wawa_vansales/ui/widgets/dialogs/confirm_exit_dialog.dart';
import 'package:wawa_vansales/ui/widgets/dialogs/printing_dialog.dart';
import 'package:wawa_vansales/utils/global.dart';
import 'package:wawa_vansales/utils/local_storage.dart';

class SaleScreen extends StatefulWidget {
  final bool isFromPreOrder;
  final bool startAtCart;
  final String? preOrderDocNo; // เพิ่มพารามิเตอร์สำหรับเลขที่เอกสาร pre-order
  final double? preOrderTotalAmount; // เพิ่มพารามิเตอร์สำหรับยอดเงินจาก API

  const SaleScreen({
    super.key,
    this.isFromPreOrder = false,
    this.startAtCart = false,
    this.preOrderDocNo,
    this.preOrderTotalAmount,
  });

  @override
  State<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  final PageController _pageController = PageController();
  final ReceiptPrinterService _printerService = ReceiptPrinterService();

  String _warehouseCode = 'NA';
  String _empCode = 'NA';
  String preOrderDocNo = '';
  bool _isTransactionCompleted = false; // เพิ่มตัวแปรสำหรับติดตามสถานะการทำงาน

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
        context.read<CartBloc>().add(SetPreOrderDocument(preOrderDocNo));

        // ตั้งค่ายอด total_amount จาก API หากมีการส่งมา
        if (widget.preOrderTotalAmount != null && widget.preOrderTotalAmount! > 0) {
          context.read<CartBloc>().add(SetPreOrderApiTotalAmount(widget.preOrderTotalAmount!));
        }
      }

      // ถ้าเริ่มจากหน้าตะกร้าให้ไปที่หน้าตะกร้าเลย
      if (widget.startAtCart) {
        _pageController.jumpToPage(1); // ไปที่หน้าตะกร้า
        context.read<CartBloc>().add(const UpdateStep(1)); // แน่ใจว่ามีการตั้งค่า step ใน bloc ด้วย
      } else if (widget.isFromPreOrder) {
        _pageController.jumpToPage(2); // ไปที่หน้าชำระเงิน
        context.read<CartBloc>().add(const UpdateStep(2)); // แน่ใจว่ามีการตั้งค่า step ใน bloc ด้วย
      }
    });

    _checkPrinterConnection();
  }

  Future<void> _loadUserData() async {
    // ใช้ localStorage จากที่สร้างไว้แล้วใน main.dart แทนการสร้างใหม่
    final localStorage = context.read<LocalStorage>();

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
      // ตรวจสอบการชำระเงินก่อนไปขั้นตอนที่ 3 โดยให้ยกเว้นกรณี PreOrder และ partial_pay=1
      if (step == 3 && !cartState.isFullyPaid) {
        // ถ้าเป็น PreOrder และเป็นการชำระเงินบางส่วน ไม่ต้องตรวจสอบความครบถ้วนของเงิน
        final bool isPartialPayPreOrder = widget.isFromPreOrder && cartState.partialPay == '1';

        // ถ้าไม่ใช่การชำระบางส่วนของ PreOrder ให้ตรวจสอบการชำระเงินตามปกติ
        if (!isPartialPayPreOrder) {
          // ถ้าเป็นการชำระบางส่วน ต้องมีการชำระเงินอย่างน้อย 1 รายการ
          if (cartState.partialPay == '1' && cartState.payments.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('กรุณาชำระเงินอย่างน้อย 1 รายการ')),
            );
            return;
          } else if (cartState.partialPay == '0') {
            // ถ้าต้องชำระเต็มจำนวน
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('กรุณาชำระเงินให้ครบก่อน')),
            );
            return;
          }
        } else if (cartState.payments.isEmpty) {
          // กรณี PreOrder ชำระบางส่วน ต้องมีการชำระเงินอย่างน้อย 1 รายการ
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('กรุณาชำระเงินอย่างน้อย 1 รายการ')),
          );
          return;
        }
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

    // คำนวณเงินทอนจากข้อมูล payments โดยตรง
    double? changeAmount;
    // ค้นหาการชำระเงินแบบเงินสด
    final cashPayments = state.payments.where((payment) => PaymentModel.intToPaymentType(payment.payType) == PaymentType.cash).toList();

    // คำนวณเงินทอนจากการชำระด้วยเงินสด
    for (var payment in cashPayments) {
      if (payment.payAmount > state.totalAmount) {
        // กรณีจ่ายเงินสดมากกว่ายอดรวม จะมีเงินทอน
        changeAmount = (changeAmount ?? 0) + (payment.payAmount - state.totalAmount);
      }
    }

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
    PrintingDialog.show(
      context: context,
      title: 'กำลังพิมพ์ใบเสร็จ',
      documentNumber: state.documentNumber,
      additionalMessage: 'โปรดรอสักครู่...',
    );

    await Future.delayed(const Duration(seconds: 1));

    // เริ่มพิมพ์ในแบ็คกราวนด์
    try {
      bool printSuccess = await _printerService.printReceipt(
        customer: state.customer,
        items: state.items,
        payments: state.payments,
        totalAmount: state.totalAmount,
        docNumber: state.documentNumber,
        warehouseCode: _warehouseCode,
        empCode: _empCode,
        receiptType: receiptType,
        changeAmount: changeAmount, // เพิ่มการส่งค่าเงินทอน
        isFromPreOrder: widget.isFromPreOrder, // ส่งค่า isFromPreOrder ไปด้วย
        balanceAmount: state.balanceAmount, // ส่งค่า balanceAmount ถ้ามี
      );

      // ปิด dialog
      if (mounted) Navigator.of(context).pop();

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
          // พิมพ์ซ้ำโดยกำหนด isCopy เป็น true (ไม่ส่งค่าเงินทอนไปในสำเนา)
          await _printerService.printReceipt(
            customer: state.customer,
            items: state.items,
            payments: state.payments,
            totalAmount: state.totalAmount,
            docNumber: state.documentNumber,
            warehouseCode: _warehouseCode,
            empCode: _empCode,
            receiptType: receiptType,
            isCopy: true, // ระบุว่าเป็นสำเนา
            isFromPreOrder: widget.isFromPreOrder, // ส่งค่า isFromPreOrder ไปด้วย
            balanceAmount: state.balanceAmount, // ส่งค่า balanceAmount ถ้ามี
          );
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

  // ฟังก์ชั่นช่วยในการค้นหา SalePaymentStep
  List<Element> findPaymentStepState(BuildContext context) {
    final List<Element> elements = <Element>[];
    void visitor(Element element) {
      if (element.widget is SalePaymentStep) {
        elements.add(element);
      }
      element.visitChildren(visitor);
    }

    context.visitChildElements(visitor);
    return elements;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

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

          if (shouldPop && mounted) {
            Navigator.of(context).pop();
          }
        } else {
          _goToStep(0);
          context.read<CartBloc>().add(ClearCart());
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: SafeArea(
        child: Scaffold(
          // เพิ่มชื่อ route เพื่อให้สามารถอ้างอิงได้ใน Navigator.popUntil
          restorationId: 'SaleScreen',
          appBar: AppBar(
            title: const Text('ขายสินค้า'),
            leading: BlocBuilder<CartBloc, CartState>(
              buildWhen: (previous, current) {
                // สร้าง widget ใหม่เมื่อ step เปลี่ยน
                return previous is CartLoaded && current is CartLoaded && (previous).currentStep != (current).currentStep;
              },
              builder: (context, state) {
                if (state is CartLoaded) {
                  return IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () async {
                      // ถ้าอยู่ที่ step 0 แสดง ConfirmExitDialog
                      if (state.currentStep == 0) {
                        final shouldExit = await ConfirmExitDialog.show(context);
                        if (shouldExit == true) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const HomeScreen()),
                            (route) => false,
                          );
                        }
                      }
                      // ถ้าอยู่ที่ step 1, 2, 3 ให้ย้อนกลับทีละ step
                      else {
                        _goToStep(state.currentStep - 1);
                      }
                    },
                  );
                }
                return IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                );
              },
            ),
          ),
          body: BlocConsumer<CartBloc, CartState>(
            listenWhen: (previous, current) {
              // คืนค่า true เมื่อเราต้องการให้ listener ทำงาน
              // ถ้าเป็น CartSubmitSuccess และเคยทำงานแล้ว จะไม่ทำซ้ำอีก
              if (current is CartSubmitSuccess && _isTransactionCompleted) {
                return false;
              }
              return current is CartError || current is CartSubmitSuccess || current is CartSubmitting;
            },
            listener: (context, state) async {
              // ปิด dialog กรณีที่มี dialog กำลังแสดงอยู่ เมื่อได้รับ state เป็น CartError
              if (state is CartError) {
                // ตรวจสอบว่ามี dialog ที่กำลังแสดงอยู่หรือไม่
                // แล้วปิด dialog ก่อนแสดง dialog ข้อผิดพลาด
                Navigator.of(context).popUntil((route) => route.isActive);

                // แสดง dialog แจ้งข้อผิดพลาด
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    title: const Text('เกิดข้อผิดพลาด'),
                    content: Text(state.message),
                    actions: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // ปิด dialog

                          // รอให้ dialog ปิดก่อนจึงนำทางกลับไปหน้า summary step
                          Future.delayed(Duration.zero, () {
                            if (mounted && _pageController.hasClients) {
                              // ใช้ currentStep จาก bloc state แทนการใช้ค่าคงที่ 3
                              final cartState = context.read<CartBloc>().state;
                              if (cartState is CartLoaded) {
                                // ตั้งค่า current step ให้เป็น 3 ก่อน
                                context.read<CartBloc>().add(const UpdateStep(3));
                                // แล้วค่อยเลื่อนหน้าไปที่ step 3
                                _pageController.jumpToPage(3);
                              }
                            }
                          });
                        },
                        child: const Text('ตกลง'),
                      ),
                    ],
                  ),
                );
              } else if (state is CartSubmitSuccess && !_isTransactionCompleted) {
                if (kDebugMode) {
                  print("SaleScreen: ได้รับ CartSubmitSuccess state - กำลังแสดง PrintReceiptDialog");
                }

                // ตั้งค่า flag เพื่อป้องกันการทำงานซ้ำซ้อน
                setState(() {
                  _isTransactionCompleted = true;
                });

                // ปิดทุก dialog ที่อาจค้างอยู่จากการชำระเงินด้วย QR Code
                // เป็นไปได้ว่า QrPaymentDialog หรือ processing dialog ยังคงแสดงอยู่

                // พยายามปิด QR dialogs ที่อาจยังค้างอยู่
                try {
                  if (kDebugMode) {
                    print("SaleScreen: ปิด dialogs ที่ค้างอยู่");
                  }

                  // ปิด dialog ทั้งหมดที่เป็น dialog จากการชำระเงินด้วย QR
                  Navigator.of(context).popUntil((route) {
                    final name = route.settings.name;
                    final isQRDialog = name == 'QrPaymentDialog' || name == 'QrProcessingDialog';
                    // ถ้าเป็น QR dialog ให้ปิด, แต่ถ้าไม่ใช่ ให้หยุดที่นั่น
                    return !isQRDialog;
                  });
                } catch (e) {
                  if (kDebugMode) {
                    print("SaleScreen: เกิดข้อผิดพลาดในการปิด dialogs: $e");
                  }
                }

                // แจ้งเตือนว่าบันทึกสำเร็จ
                // ScaffoldMessenger.of(context).showSnackBar(
                //   const SnackBar(
                //     content: Text('บันทึกการขายเรียบร้อยแล้ว'),
                //     backgroundColor: Colors.green,
                //   ),
                // );

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
                            totalAmount: widget.isFromPreOrder && state.preOrderApiTotalAmount > 0 ? state.preOrderApiTotalAmount : state.totalAmount,
                            onNextStep: () => _goToStep(2),
                            onBackStep: () => _goToStep(0),
                            isFromPreOrder: widget.isFromPreOrder, // ส่งค่า isFromPreOrder ไปยัง SaleCartStep
                          ),
                          if (state.selectedCustomer != null)
                            // Step 3: ชำระเงิน
                            SalePaymentStep(
                              totalAmount: widget.isFromPreOrder && state.preOrderApiTotalAmount > 0 ? state.preOrderApiTotalAmount : state.totalAmount,
                              payments: state.payments,
                              remainingAmount: state.remainingAmount,
                              onBackStep: () => _goToStep(1),
                              onNextStep: () => _goToStep(3),
                              customer: state.selectedCustomer!,
                              isFromPreOrder: widget.isFromPreOrder, // ส่งค่า isFromPreOrder ไปยัง SalePaymentStep
                            ),
                          // Step 4: สรุปรายการ + พิมพ์ใบเสร็จ
                          if (state.selectedCustomer != null)
                            SaleSummaryStep(
                              customer: state.selectedCustomer!,
                              items: state.items,
                              payments: state.payments,
                              totalAmount: widget.isFromPreOrder && state.preOrderApiTotalAmount > 0 ? state.preOrderApiTotalAmount : state.totalAmount,
                              onBackStep: () => _goToStep(2),
                              isConnected: _printerService.isConnected,
                              isConnecting: _printerService.isConnecting,
                              onReconnectPrinter: () async {
                                return await _printerService.connectPrinter();
                              },
                              empCode: _empCode,
                              preOrderDocNumber: preOrderDocNo, // ส่งเลขที่เอกสาร preOrder ถ้ามาจาก PreOrderDetailScreen
                              isFromPreOrder: widget.isFromPreOrder, // ส่งค่า isFromPreOrder ไปด้วย
                              balanceAmount: state.balanceAmount, // เพิ่มการส่งค่า balanceAmount
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
