// lib/ui/screens/return_product/return_product_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:wawa_vansales/blocs/return_product/return_product_bloc.dart';
import 'package:wawa_vansales/blocs/return_product/return_product_event.dart';
import 'package:wawa_vansales/blocs/return_product/return_product_state.dart';
import 'package:wawa_vansales/blocs/sales_summary/sales_summary_bloc.dart';
import 'package:wawa_vansales/blocs/sales_summary/sales_summary_event.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/services/printer_status_provider.dart';
import 'package:wawa_vansales/data/services/receipt_printer_service.dart';
import 'package:wawa_vansales/ui/screens/home_screen.dart';
import 'package:wawa_vansales/ui/screens/return_product/return_customer_step.dart';
import 'package:wawa_vansales/ui/screens/return_product/return_product_cart_step.dart';
import 'package:wawa_vansales/ui/screens/return_product/return_product_stepper_widget.dart';
import 'package:wawa_vansales/ui/screens/return_product/return_summary_step.dart';
import 'package:wawa_vansales/ui/screens/return_product/sale_document_step.dart';
import 'package:wawa_vansales/ui/screens/sale/print_receipt_dialog.dart';
import 'package:wawa_vansales/utils/global.dart';
import 'package:wawa_vansales/utils/local_storage.dart';

class ReturnProductScreen extends StatefulWidget {
  const ReturnProductScreen({super.key});

  @override
  State<ReturnProductScreen> createState() => _ReturnProductScreenState();
}

class _ReturnProductScreenState extends State<ReturnProductScreen> {
  final PageController _pageController = PageController();
  final ReceiptPrinterService _printerService = ReceiptPrinterService();

  String _warehouseCode = 'NA';
  String _empCode = 'NA';
  bool _isTransactionCompleted = false; // เพิ่มตัวแปรสำหรับติดตามสถานะการทำงาน

  @override
  void initState() {
    super.initState();
    _isTransactionCompleted = false; // รีเซ็ตตัวแปรทุกครั้งเมื่อเปิดหน้าจอใหม่

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _warehouseCode = Global.whCode;
        _empCode = Global.empCode;
      });

      if (Global.empCode.isEmpty) {
        _loadUserData();
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
    final returnState = context.read<ReturnProductBloc>().state;
    if (returnState is ReturnProductLoaded) {
      if (step == 1 && returnState.selectedCustomer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเลือกลูกค้าก่อน')),
        );
        return;
      }

      if (step == 2 && returnState.selectedSaleDocument == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเลือกเอกสารขายก่อน')),
        );
        return;
      }

      if (step == 3 && returnState.returnItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเพิ่มสินค้าในรายการรับคืนก่อน')),
        );
        return;
      }

      print('Current step: ${returnState.currentStep}, Going to step: $step');
      print('Selected document: ${returnState.selectedSaleDocument?.docNo}');

      context.read<ReturnProductBloc>().add(UpdateReturnStep(step));

      // เราไม่จำเป็นต้องใช้ _pageController.animateTo อีกต่อไปเมื่อใช้ IndexedStack
      // แต่ถ้ายังต้องการใช้ ต้องเพิ่มการตรวจสอบ
      /* 
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          step,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
      */
    }
  }

  Future<void> _checkPrinterConnection() async {
    bool isConnected = await _printerService.checkConnection();
    if (!isConnected && mounted) {
      _printerService.autoConnect();
    }
  }

  Future<void> _printReturnReceipt(ReturnSubmitSuccess state, String receiptType) async {
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
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text('กำลังพิมพ์ใบรับคืนสินค้า'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('กำลังพิมพ์ใบรับคืนสินค้าเลขที่: ${state.documentNumber}'),
                const SizedBox(height: 8),
                const Text('โปรดรอสักครู่...', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );

    // เริ่มพิมพ์ใบรับคืนในแบ็คกราวนด์
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
            title: const Text('พิมพ์ใบรับคืนสินค้าเสร็จสิ้น'),
            content: const Text('พิมพ์ใบรับคืนสินค้าเรียบร้อยแล้ว'),
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
          // พิมพ์ซ้ำโดยกำหนด isCopy เป็น true
          await _printerService.printReceipt(
            customer: state.customer,
            items: state.items,
            payments: state.payments,
            totalAmount: state.totalAmount,
            docNumber: state.documentNumber,
            warehouseCode: _warehouseCode,
            empCode: _empCode,
            receiptType: receiptType,
            isCopy: true,
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final returnState = context.read<ReturnProductBloc>().state;
        if (returnState is ReturnProductLoaded && returnState.returnItems.isNotEmpty) {
          final bool shouldPop = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('ยืนยันการออก'),
                  content: const Text('คุณต้องการออกจากหน้านี้หรือไม่? รายการสินค้าในรายการรับคืนจะถูกล้าง'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('ยกเลิก'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        context.read<ReturnProductBloc>().add(ResetReturnProductState());

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
            // Use ResetReturnProductState instead of just clearing the cart
            context.read<ReturnProductBloc>().add(ResetReturnProductState());
            Navigator.of(context).pop();
          }
        } else {
          // Always use ResetReturnProductState to fully reset the state
          context.read<ReturnProductBloc>().add(ResetReturnProductState());
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('รับคืนสินค้า'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () async {
                final returnState = context.read<ReturnProductBloc>().state;
                if (returnState is ReturnProductLoaded && returnState.returnItems.isNotEmpty) {
                  final bool shouldPop = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('ยืนยันการออก'),
                          content: const Text('คุณต้องการออกจากหน้านี้หรือไม่? รายการสินค้าในรายการรับคืนจะถูกล้าง'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('ยกเลิก'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                context.read<ReturnProductBloc>().add(ResetReturnProductState());
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

                  if (!shouldPop) return;
                } else if (returnState is ReturnProductLoaded && returnState.selectedCustomer != null) {
                  // เพิ่มการถามยืนยันเมื่อได้เลือกลูกค้าแล้ว แต่ยังไม่มีสินค้าในตะกร้า
                  final bool shouldPop = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('ยืนยันการออก'),
                          content: const Text('คุณต้องการออกจากหน้านี้หรือไม่? ข้อมูลลูกค้าที่เลือกจะถูกล้าง'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('ยกเลิก'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                context.read<ReturnProductBloc>().add(ResetReturnProductState());
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

                  if (!shouldPop) return;
                }

                // Always use ResetReturnProductState instead of just going to step 0
                context.read<ReturnProductBloc>().add(ResetReturnProductState());
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
          body: BlocConsumer<ReturnProductBloc, ReturnProductState>(
            listenWhen: (previous, current) {
              // คืนค่า true เมื่อเราต้องการให้ listener ทำงาน
              // ถ้าเป็น ReturnSubmitSuccess และเคยทำงานแล้ว จะไม่ทำซ้ำอีก
              if (current is ReturnSubmitSuccess && _isTransactionCompleted) {
                return false;
              }

              // ไม่แสดง error สำหรับกรณีสินค้าไม่มีในบิลขายเดิม เพื่อป้องกัน SnackBar ซ้ำซ้อน
              if (current is ReturnProductError &&
                  (current.message.contains('ไม่มีในบิลขาย') || current.message.contains('รหัสสินค้า') && current.message.contains('ไม่มีในบิล'))) {
                return false;
              }

              return current is ReturnProductError || current is ReturnSubmitSuccess || current is ReturnSubmitting;
            },
            listener: (context, state) async {
              // ปิด dialog กรณีที่มี dialog กำลังแสดงอยู่ เมื่อได้รับ state เป็น ReturnProductError
              if (state is ReturnProductError) {
                // ตรวจสอบว่ามี dialog ที่กำลังแสดงอยู่หรือไม่
                // แล้วปิด dialog ก่อนแสดง SnackBar
                Navigator.of(context).popUntil((route) => route.isActive);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              } else if (state is ReturnSubmitSuccess && !_isTransactionCompleted) {
                // ตั้งค่า flag เพื่อป้องกันการทำงานซ้ำซ้อน
                setState(() {
                  _isTransactionCompleted = true;
                });

                // แจ้งเตือนว่าบันทึกสำเร็จ
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('บันทึกการรับคืนสินค้าเรียบร้อยแล้ว'),
                    backgroundColor: Colors.green,
                  ),
                );

                // รีเฟรชข้อมูลยอดขายวันนี้
                context.read<SalesSummaryBloc>().add(RefreshTodaysSalesSummary());

                // ถามว่าต้องการพิมพ์ใบรับคืนสินค้าหรือไม่
                final receiptChoice = await PrintReceiptDialog.show(
                  context,
                  documentNumber: state.documentNumber,
                  customer: state.customer,
                );
                final bool shouldPrint = receiptChoice != null && receiptChoice['print'] == true;
                final String receiptType = receiptChoice != null ? receiptChoice['receiptType'] ?? 'taxReceipt' : 'taxReceipt';

                if (shouldPrint) {
                  await _printReturnReceipt(state, receiptType);
                }

                // รีเซ็ตตะกร้าและกลับหน้าหลัก
                context.read<ReturnProductBloc>().add(ResetReturnProductState());
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              }
            },
            builder: (context, state) {
              if (state is ReturnProductLoaded || state is ReturnProductInitial) {
                // ใช้ state casting เพื่อให้เข้าถึงข้อมูลใน ReturnProductLoaded
                final loadedState = state is ReturnProductLoaded ? state : null;

                return Column(
                  children: [
                    // Stepper Widget
                    ReturnProductStepperWidget(
                      currentStep: loadedState?.currentStep ?? 0,
                      isCustomerSelected: loadedState?.selectedCustomer != null,
                      isDocumentSelected: loadedState?.selectedSaleDocument != null,
                      hasItems: loadedState?.returnItems.isNotEmpty ?? false,
                    ),

                    // เนื้อหาแต่ละ Step
                    Expanded(
                      child: IndexedStack(
                        index: loadedState?.currentStep ?? 0,
                        children: [
                          // Step 0: เลือกลูกค้า
                          ReturnCustomerStep(
                            selectedCustomer: loadedState?.selectedCustomer,
                            onNextStep: () => _goToStep(1),
                          ),

                          // Step 1: เลือกเอกสารขาย
                          SaleDocumentStep(
                            selectedSaleDocument: loadedState?.selectedSaleDocument,
                            customerCode: loadedState?.selectedCustomer?.code ?? '',
                            customerName: loadedState?.selectedCustomer?.name ?? '',
                            saleDocuments: loadedState?.saleDocuments ?? [],
                            onNextStep: () => _goToStep(2),
                            onBackStep: () => _goToStep(0),
                          ),

                          // Step 2: เลือกสินค้าที่จะรับคืน
                          ReturnProductCartStep(
                            returnItems: loadedState?.returnItems ?? [],
                            documentDetails: loadedState?.documentDetails ?? [],
                            totalAmount: loadedState?.totalAmount ?? 0,
                            onNextStep: () => _goToStep(3),
                            onBackStep: () => _goToStep(1),
                            customerCode: loadedState?.selectedCustomer?.code ?? '',
                          ),

                          // Step 3: สรุปรายการ + พิมพ์ใบรับคืน
                          if (loadedState?.selectedCustomer != null && loadedState?.selectedSaleDocument != null)
                            ReturnSummaryStep(
                              customer: loadedState!.selectedCustomer!,
                              saleDocument: loadedState.selectedSaleDocument!,
                              items: loadedState.returnItems,
                              payments: loadedState.payments,
                              totalAmount: loadedState.totalAmount,
                              onBackStep: () => _goToStep(2),
                              isConnected: _printerService.isConnected,
                              isConnecting: _printerService.isConnecting,
                              onReconnectPrinter: () async {
                                return await _printerService.connectPrinter();
                              },
                              empCode: _empCode,
                            )
                          else
                            const Center(
                              child: Text('ไม่พบข้อมูลลูกค้าหรือเอกสารขาย'),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              } else if (state is ReturnSubmitting) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('กำลังบันทึกการรับคืนสินค้า...'),
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
