// lib/ui/screens/sale/sale_summary_step.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wawa_vansales/blocs/cart/cart_bloc.dart';
import 'package:wawa_vansales/blocs/cart/cart_event.dart';
import 'package:wawa_vansales/blocs/cart/cart_state.dart';
import 'package:wawa_vansales/data/models/cart_item_model.dart';
import 'package:wawa_vansales/data/models/customer_model.dart';
import 'package:wawa_vansales/data/models/payment_model.dart';
import 'package:wawa_vansales/ui/widgets/custom_button.dart';
import 'package:wawa_vansales/ui/screens/sale/receipt_preview_widget.dart';
import 'package:wawa_vansales/config/app_theme.dart';

class SaleSummaryStep extends StatelessWidget {
  final CustomerModel customer;
  final List<CartItemModel> items;
  final List<PaymentModel> payments;
  final double totalAmount;
  final VoidCallback onBackStep;
  final bool isConnected;
  final bool isConnecting;
  final Future<void> Function() onReconnectPrinter;
  final Future<Uint8List?> Function() createReceiptImage;

  const SaleSummaryStep({
    super.key,
    required this.customer,
    required this.items,
    required this.payments,
    required this.totalAmount,
    required this.onBackStep,
    required this.isConnected,
    required this.isConnecting,
    required this.onReconnectPrinter,
    required this.createReceiptImage,
  });

  Future<void> _showSaveConfirmDialog(BuildContext context) async {
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
      context.read<CartBloc>().add(const SubmitSale());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CartBloc, CartState>(
      listener: (context, state) {
        if (state is CartSubmitSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('บันทึกการขายเรียบร้อยแล้ว'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else if (state is CartError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: ${state.message}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      },
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPrinterStatus(context),
                  const SizedBox(height: 16),
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
                      customer: customer,
                      items: items,
                      payments: payments,
                      totalAmount: totalAmount,
                      docNumber: 'ตัวอย่างเลขที่เอกสาร',
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildBottomActions(context),
        ],
      ),
    );
  }

  Widget _buildPrinterStatus(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isConnected ? Icons.print : Icons.print_disabled,
              color: isConnected ? Colors.green : Colors.red,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isConnected ? 'เชื่อมต่อเครื่องพิมพ์แล้ว' : 'กำลังเชื่อมต่อเครื่องพิมพ์...',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isConnected ? Colors.green : Colors.orange,
                    ),
                  ),
                  if (isConnecting)
                    const Text(
                      'กำลังพยายามเชื่อมต่อใหม่...',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ),
            if (!isConnected)
              ElevatedButton(
                onPressed: isConnecting ? null : () => onReconnectPrinter(),
                child: isConnecting
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

  Widget _buildBottomActions(BuildContext context) {
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
              text: 'กลับ',
              onPressed: onBackStep,
              buttonType: ButtonType.outline,
              icon: const Icon(Icons.arrow_back),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: CustomButton(
              text: 'บันทึกรายการขาย',
              onPressed: () => _showSaveConfirmDialog(context),
              icon: const Icon(Icons.check_circle, color: Colors.white),
              buttonType: ButtonType.primary,
            ),
          ),
        ],
      ),
    );
  }
}
