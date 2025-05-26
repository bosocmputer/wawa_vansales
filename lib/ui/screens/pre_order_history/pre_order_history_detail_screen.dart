// /lib/ui/screens/pre_order_history/pre_order_history_detail_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wawa_vansales/blocs/pre_order_history/pre_order_history_bloc.dart';
import 'package:wawa_vansales/blocs/pre_order_history/pre_order_history_event.dart';
import 'package:wawa_vansales/blocs/pre_order_history/pre_order_history_state.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/models/cart_item_model.dart';
import 'package:wawa_vansales/data/models/customer_model.dart';
import 'package:wawa_vansales/data/models/payment_model.dart';
import 'package:wawa_vansales/data/models/pre_order_history_detail_model.dart';
import 'package:wawa_vansales/data/models/pre_order_history_model.dart';
import 'package:wawa_vansales/data/services/printer_status_provider.dart';
import 'package:wawa_vansales/data/services/receipt_printer_service.dart';
import 'package:wawa_vansales/ui/screens/sale/print_receipt_dialog.dart';
import 'package:wawa_vansales/ui/screens/warehouse/emty_state_widget.dart';
import 'package:wawa_vansales/ui/widgets/dialogs/printing_dialog.dart';
import 'package:wawa_vansales/utils/global.dart';

class PreOrderHistoryDetailScreen extends StatefulWidget {
  final String docNo;
  final PreOrderHistoryModel orderHistory;

  const PreOrderHistoryDetailScreen({
    super.key,
    required this.docNo,
    required this.orderHistory,
  });

  @override
  State<PreOrderHistoryDetailScreen> createState() => _PreOrderHistoryDetailScreenState();
}

class _PreOrderHistoryDetailScreenState extends State<PreOrderHistoryDetailScreen> {
  final _currencyFormat = NumberFormat('#,##0.00', 'th_TH');
  final ReceiptPrinterService _printerService = ReceiptPrinterService();
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PreOrderHistoryBloc>().add(FetchPreOrderHistoryDetail(widget.docNo));
    });
  }

  // ฟังก์ชันสำหรับพิมพ์ใบเสร็จ
  Future<void> _printReceipt(
    String docNo,
    CustomerModel customer,
    List<PreOrderHistoryDetailModel> items,
    double totalAmount,
  ) async {
    if (_isPrinting) return; // ป้องกันการกดพิมพ์ซ้ำ

    setState(() {
      _isPrinting = true;
    });

    final printerStatus = Provider.of<PrinterStatusProvider>(context, listen: false);

    // ดึงข้อมูลจำนวนเงินจากแต่ละประเภทการชำระเงิน
    final double cashAmount = double.tryParse(widget.orderHistory.cashAmount) ?? 0;
    final double transferAmount = double.tryParse(widget.orderHistory.tranferAmount) ?? 0;
    final double cardAmount = double.tryParse(widget.orderHistory.cardAmount) ?? 0;

    // คำนวณเงินทอน (กรณีจ่ายเงินสดมากกว่ายอดรวม)
    double? changeAmount;
    if (cashAmount > totalAmount) {
      changeAmount = cashAmount - totalAmount;
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
          setState(() {
            _isPrinting = false;
          });
          return;
        }
      }
    }

    // แสดง dialog เลือกประเภทใบเสร็จ
    final receiptChoice = await PrintReceiptDialog.show(
      context,
      documentNumber: docNo,
      customer: customer,
    );

    final bool shouldPrint = receiptChoice != null && receiptChoice['print'] == true;
    final String receiptType = receiptChoice != null ? receiptChoice['receiptType'] ?? 'taxReceipt' : 'taxReceipt';

    if (!shouldPrint) {
      setState(() {
        _isPrinting = false;
      });
      return;
    }

    PrintingDialog.show(
      context: context,
      title: 'กำลังพิมพ์ใบเสร็จ',
      documentNumber: docNo,
      additionalMessage: 'โปรดรอสักครู่...',
    );

    await Future.delayed(const Duration(seconds: 1));

    // แปลง PreOrderHistoryDetailModel เป็น CartItemModel เพื่อใช้กับ ReceiptPrinterService
    List<CartItemModel> cartItems = items.map((item) {
      final qtyValue = double.tryParse(item.qty) ?? 0;
      final priceValue = double.tryParse(item.price) ?? 0;
      final total = qtyValue * priceValue;

      return CartItemModel(
        itemCode: item.itemCode,
        itemName: item.itemName,
        barcode: '',
        price: item.price,
        sumAmount: total.toString(),
        unitCode: item.unitCode,
        whCode: item.whCode,
        shelfCode: item.shelfCode,
        ratio: item.ratio,
        standValue: item.standValue,
        divideValue: item.divideValue,
        qty: item.qty,
        refRow: "0",
      );
    }).toList();

    // รายการชำระเงิน - สร้างจากข้อมูลจริงของ PreOrder
    List<PaymentModel> payments = [];

    // เพิ่มข้อมูลการชำระเงินตามประเภท
    if (cashAmount > 0) {
      payments.add(PaymentModel(
        payType: 0, // เงินสด
        payAmount: cashAmount,
        transNumber: '',
      ));
    }

    if (transferAmount > 0) {
      payments.add(PaymentModel(
        payType: 1, // เงินโอน
        payAmount: transferAmount,
        transNumber: '',
      ));
    }

    if (cardAmount > 0) {
      // ใช้ค่า totalCreditCharge จาก API หรือคำนวณถ้าไม่มีค่า
      final double creditCardCharge = double.tryParse(widget.orderHistory.totalCreditCharge ?? '0') ?? (cardAmount * 0.015);

      payments.add(PaymentModel(
        payType: 2, // บัตรเครดิต
        payAmount: cardAmount,
        transNumber: '', // เพิ่มการสร้างเลขอ้างอิงจากเลขที่เอกสาร
        charge: creditCardCharge, // ใช้ค่าธรรมเนียมบัตรเครดิตจาก API
      ));
    }

    // ถ้าไม่มีข้อมูลการชำระเงินเลย ให้ตั้งเป็นเงินสดทั้งหมด
    if (payments.isEmpty && totalAmount > 0) {
      payments.add(PaymentModel(
        payType: 1, // เงินสด
        payAmount: totalAmount,
        transNumber: '',
      ));
    }

    // เริ่มพิมพ์ใบเสร็จ
    try {
      bool printSuccess = await _printerService.printReceipt(
        customer: customer,
        items: cartItems,
        payments: payments,
        totalAmount: totalAmount,
        docNumber: docNo,
        warehouseCode: items.isNotEmpty ? items.first.whCode : '',
        empCode: Global.empCode,
        receiptType: receiptType,
        isCopy: true, // ระบุว่าเป็นการพิมพ์สำเนา
        changeAmount: changeAmount, // เพิ่มการส่งค่าเงินทอน
        isFromPreOrder: true, // เพิ่มค่า isFromPreOrder เป็น true เพื่อระบุว่าเป็นการพิมพ์จาก Pre-Order
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
          if (mounted) {
            _printReceipt(docNo, customer, items, totalAmount);
            return;
          }
        }
      } else {
        // แจ้งเตือนว่าพิมพ์ไม่สำเร็จ
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ไม่สามารถพิมพ์ได้ กรุณาเชื่อมต่อเครื่องพิมพ์'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
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
    } finally {
      setState(() {
        _isPrinting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดพรีออเดอร์'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // เมื่อกดปุ่มกลับใน AppBar ให้รีเซ็ตสถานะ
            context.read<PreOrderHistoryBloc>().add(ResetPreOrderHistoryDetail());
            Navigator.of(context).pop();
          },
        ),
        actions: [
          // เพิ่มปุ่มพิมพ์ใบเสร็จ
          BlocBuilder<PreOrderHistoryBloc, PreOrderHistoryState>(
            builder: (context, state) {
              if (state is PreOrderHistoryDetailLoaded) {
                return IconButton(
                  icon: const Icon(Icons.print),
                  tooltip: 'พิมพ์ใบเสร็จ',
                  onPressed: _isPrinting
                      ? null
                      : () async {
                          // สร้าง CustomerModel จากข้อมูลที่มีใน orderHistory
                          try {
                            final customer = CustomerModel(
                              code: widget.orderHistory.custCode,
                              name: widget.orderHistory.custName,
                            );

                            // เรียกฟังก์ชันพิมพ์ใบเสร็จ
                            _printReceipt(
                              widget.docNo,
                              customer,
                              state.items,
                              state.totalAmount,
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('เกิดข้อผิดพลาด: ${e.toString()}'),
                                backgroundColor: AppTheme.errorColor,
                              ),
                            );
                          }
                        },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<PreOrderHistoryBloc, PreOrderHistoryState>(
        builder: (context, state) {
          if (state is PreOrderHistoryDetailLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is PreOrderHistoryDetailLoaded) {
            final items = state.items;
            final docNo = widget.docNo;

            if (items.isEmpty) {
              return Center(
                child: EmptyStateWidget(
                  icon: Icons.receipt_long,
                  message: 'ไม่พบรายละเอียดพรีออเดอร์',
                  subMessage: 'เลขที่: $docNo',
                  actionLabel: 'กลับ',
                  onAction: () {
                    // รีเซ็ตสถานะก่อนกลับ
                    context.read<PreOrderHistoryBloc>().add(ResetPreOrderHistoryDetail());
                    Navigator.of(context).pop();
                  },
                ),
              );
            }

            // คำนวณยอดรวมทั้งหมด
            final totalAmount = state.totalAmount;

            return Column(
              children: [
                // ส่วนหัวแสดงเลขที่เอกสาร
                _buildDocumentHeader(docNo),

                // รายการสินค้า
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildItemCard(item);
                    },
                  ),
                ),

                // สรุปยอดรวม
                _buildTotalSummary(totalAmount),
              ],
            );
          } else if (state is PreOrderHistoryError) {
            return Center(
              child: EmptyStateWidget(
                icon: Icons.error_outline,
                message: 'เกิดข้อผิดพลาด',
                subMessage: state.message,
                actionLabel: 'ลองใหม่',
                onAction: () {
                  context.read<PreOrderHistoryBloc>().add(FetchPreOrderHistoryDetail(widget.docNo));
                },
              ),
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }

  Widget _buildDocumentHeader(String docNo) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.primaryColor.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(
            Icons.receipt,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'เลขที่เอกสาร',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  docNo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(PreOrderHistoryDetailModel item) {
    final qtyValue = double.tryParse(item.qty) ?? 0;
    final priceValue = double.tryParse(item.price) ?? 0;
    final total = qtyValue * priceValue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Code and Warehouse
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.itemCode,
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'คลัง: ${item.whCode} / ${item.shelfCode}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Item Name
            Text(
              item.itemName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Divider
            Divider(color: Colors.grey.shade300),
            const SizedBox(height: 4),

            // Quantity, Price and Total
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'จำนวน',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        '${qtyValue.toStringAsFixed(qtyValue.truncateToDouble() == qtyValue ? 0 : 3)} ${item.unitCode}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'ราคา/หน่วย',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        '฿${_currencyFormat.format(priceValue)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'รวม',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        '฿${_currencyFormat.format(total)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSummary(double totalAmount) {
    // ใช้ยอดสุทธิจาก API ถ้ามี ไม่เช่นนั้นใช้ยอดรวมที่คำนวณจากรายการสินค้า
    final double displayAmount = double.tryParse(widget.orderHistory.totalNetAmount ?? '0') ?? totalAmount;

    // ตรวจสอบว่ามีค่าธรรมเนียมบัตรเครดิตหรือไม่
    final double creditCharge = double.tryParse(widget.orderHistory.totalCreditCharge ?? '0') ?? 0;
    final bool hasCharge = creditCharge > 0;

    // ตรวจสอบค่าบัตรเครดิตว่ามีการใช้จ่ายหรือไม่
    final double cardAmount = double.tryParse(widget.orderHistory.cardAmount) ?? 0;
    final bool hasCardPayment = cardAmount > 0;

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
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // แสดงรายละเอียดค่าธรรมเนียมบัตรเครดิตและยอดสุทธิ เฉพาะเมื่อมีการใช้บัตรเครดิต
            if (hasCardPayment && hasCharge) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ยอดรวมสินค้า',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    '฿${_currencyFormat.format(totalAmount)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.credit_card,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'ค่าธรรมเนียมบัตรเครดิต (1.5%)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '฿${_currencyFormat.format(creditCharge)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Divider(color: Colors.grey.shade300, height: 1),
              ),
            ],

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ยอดรวมทั้งสิ้น',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        '฿${_currencyFormat.format(displayAmount)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // ก่อนกลับไปหน้าก่อนหน้า ให้รีเซ็ตสถานะของ detail
                    context.read<PreOrderHistoryBloc>().add(ResetPreOrderHistoryDetail());
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('กลับ'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(120, 44),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
