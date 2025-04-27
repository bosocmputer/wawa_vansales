// lib/ui/screens/sale/sale_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wawa_vansales/blocs/cart/cart_bloc.dart';
import 'package:wawa_vansales/blocs/cart/cart_event.dart';
import 'package:wawa_vansales/blocs/cart/cart_state.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/ui/screens/sale/sale_cart_step.dart';
import 'package:wawa_vansales/ui/screens/sale/sale_customer_step.dart';
import 'package:wawa_vansales/ui/screens/sale/sale_payment_step.dart';
import 'package:wawa_vansales/ui/screens/sale/sale_stepper_widget.dart';
import 'package:wawa_vansales/ui/screens/sale/sale_summary_step.dart';
import 'package:wawa_vansales/utils/global.dart';

class SaleScreen extends StatefulWidget {
  const SaleScreen({super.key});

  @override
  State<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  final PageController _pageController = PageController();
  String _warehouseCode = 'NA';

  @override
  void initState() {
    super.initState();
    // ดึงค่าจาก Global แทนการโหลดจาก LocalStorage โดยตรง
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _warehouseCode = Global.whCode;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    // ป้องกันไม่ให้ไปยัง step ที่ยังไม่พร้อม
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

    // อัปเดต step ใน bloc
    context.read<CartBloc>().add(UpdateStep(step));

    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // แสดง dialog ยืนยันออกจากหน้านี้ถ้ามีสินค้าในตะกร้า
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
            listener: (context, state) {
              if (state is CartError) {
                // แสดงข้อความ error
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              } else if (state is CartSubmitSuccess) {
                // แสดงข้อความสำเร็จ
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('บันทึกการขายเรียบร้อยแล้ว'),
                    backgroundColor: Colors.green,
                  ),
                );
                // กลับไปหน้าหลัก
                Navigator.of(context).pop();
              }
            },
            builder: (context, state) {
              if (state is CartLoaded) {
                return Column(
                  children: [
                    // Stepper แสดงขั้นตอน
                    SaleStepperWidget(
                      currentStep: state.currentStep,
                      isCustomerSelected: state.selectedCustomer != null,
                      hasItems: state.items.isNotEmpty,
                      isFullyPaid: state.isFullyPaid,
                    ),

                    // เนื้อหาแต่ละขั้นตอน
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

                          // Step 4: สรุปรายการ
                          if (state.selectedCustomer != null)
                            SaleSummaryStep(
                              customer: state.selectedCustomer!,
                              items: state.items,
                              payments: state.payments,
                              totalAmount: state.totalAmount,
                              onBackStep: () => _goToStep(2),
                              warehouseCode: _warehouseCode,
                            )
                          else
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.warning,
                                    size: 48,
                                    color: AppTheme.errorColor,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'ไม่พบข้อมูลลูกค้า',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'กรุณากลับไปเลือกลูกค้าก่อน',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                    ),
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
                // แสดง loading เมื่อกำลังบันทึก
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
                // จัดการ state อื่นๆ
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
        ),
      ),
    );
  }
}
