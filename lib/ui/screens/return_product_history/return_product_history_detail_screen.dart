// lib/ui/screens/return_product_history/return_product_history_detail_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wawa_vansales/blocs/return_product_history/return_product_history_bloc.dart';
import 'package:wawa_vansales/blocs/return_product_history/return_product_history_event.dart';
import 'package:wawa_vansales/blocs/return_product_history/return_product_history_state.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/models/cart_item_model.dart';
import 'package:wawa_vansales/data/models/customer_model.dart';
import 'package:wawa_vansales/data/models/return_product/return_product_history_detail_model.dart';
import 'package:wawa_vansales/data/models/return_product/sale_document_model.dart';
import 'package:wawa_vansales/data/services/receipt_return_printer_service.dart';
import 'package:wawa_vansales/ui/screens/warehouse/emty_state_widget.dart';
import 'package:wawa_vansales/ui/widgets/dialogs/printing_dialog.dart';
import 'package:wawa_vansales/utils/global.dart';

class ReturnProductHistoryDetailScreen extends StatefulWidget {
  final String docNo;
  final String custCode;
  final String custName;
  final String docDate;
  final String docTime;
  final String invNo;
  final double totalAmount; // เพิ่ม totalAmount parameter
  final String remark; // เพิ่ม remark parameter

  const ReturnProductHistoryDetailScreen({
    super.key,
    required this.docNo,
    required this.custCode,
    required this.custName,
    required this.docDate,
    required this.docTime,
    required this.invNo,
    required this.totalAmount, // เพิ่มใน constructor
    this.remark = '', // เพิ่มใน constructor with default value
  });

  @override
  State<ReturnProductHistoryDetailScreen> createState() => _ReturnProductHistoryDetailScreenState();
}

class _ReturnProductHistoryDetailScreenState extends State<ReturnProductHistoryDetailScreen> {
  final _currencyFormat = NumberFormat('#,##0.00', 'th_TH');
  // เพิ่ม instance ของ printer service
  final ReceiptReturnPrinterService _printerService = ReceiptReturnPrinterService();

  @override
  void initState() {
    super.initState();

    // เมื่อเปิดหน้าจอ ให้โหลดข้อมูลรายละเอียดการรับคืนสินค้า
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReturnProductHistoryBloc>().add(FetchReturnProductHistoryDetail(widget.docNo));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดการรับคืนสินค้า'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // เมื่อกดปุ่มกลับใน AppBar ให้รีเซ็ตสถานะ
            context.read<ReturnProductHistoryBloc>().add(ClearReturnProductHistoryDetail());
            Navigator.of(context).pop();
          },
        ),
        actions: [
          // print button
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              // เรียกฟังก์ชันพิมพ์ใบรับคืนสินค้า
              _printReturnReceipt(widget.totalAmount);
            },
          ),
        ],
      ),
      body: BlocBuilder<ReturnProductHistoryBloc, ReturnProductHistoryState>(
        builder: (context, state) {
          if (state is ReturnProductHistoryLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is ReturnProductHistoryDetailLoaded) {
            final items = state.items;
            final docNo = state.docNo;

            if (items.isEmpty) {
              return Center(
                child: EmptyStateWidget(
                  icon: Icons.assignment_return,
                  message: 'ไม่พบรายละเอียดการรับคืนสินค้า',
                  subMessage: 'เลขที่: $docNo',
                  actionLabel: 'กลับ',
                  onAction: () {
                    Navigator.of(context).pop();
                  },
                ),
              );
            }

            final totalAmount = state.totalAmount;

            return Column(
              children: [
                // ส่วนหัวแสดงข้อมูลเอกสาร
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
          } else if (state is ReturnProductHistoryError) {
            return Center(
              child: EmptyStateWidget(
                icon: Icons.error_outline,
                message: 'เกิดข้อผิดพลาด',
                subMessage: state.message,
                actionLabel: 'ลองใหม่',
                onAction: () {
                  context.read<ReturnProductHistoryBloc>().add(FetchReturnProductHistoryDetail(widget.docNo));
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // เลขที่เอกสาร
          Row(
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'วันที่',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    '${widget.docDate} ${widget.docTime}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // เส้นคั่น
          Divider(color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 8),

          // ข้อมูลลูกค้า
          Row(
            children: [
              const Icon(
                Icons.person,
                color: Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.custName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'รหัสลูกค้า: ${widget.custCode}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ใบกำกับภาษีอ้างอิง
          Row(
            children: [
              const Icon(
                Icons.receipt_long,
                color: Colors.deepOrange,
                size: 20,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'อ้างอิงเอกสารขาย',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    widget.invNo,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // หมายเหตุ - เพิ่มการแสดงหมายเหตุ
          if (widget.remark.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.note_alt,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'หมายเหตุ',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        widget.remark,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.orange,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemCard(ReturnProductHistoryDetailModel item) {
    final qtyValue = double.tryParse(item.qty) ?? 0;
    final priceValue = double.tryParse(item.price) ?? 0;
    final totalItemValue = item.totalAmount;

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
                        '$qtyValue ${item.unitCode}',
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
                        '฿${_currencyFormat.format(totalItemValue)}',
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
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'มูลค่าการรับคืนทั้งสิ้น',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    '฿${_currencyFormat.format(totalAmount)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            // ปุ่มกลับ
            ElevatedButton.icon(
              onPressed: () {
                // เมื่อกดปุ่มกลับ ให้รีเซ็ตสถานะ
                context.read<ReturnProductHistoryBloc>().add(ClearReturnProductHistoryDetail());
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
      ),
    );
  }

  Future<void> _printReturnReceipt(double totalAmount) async {
    // ตรวจสอบสถานะการเชื่อมต่อเครื่องพิมพ์
    bool isConnected = await _printerService.checkConnection();

    if (!isConnected) {
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
      isConnected = await _printerService.connectPrinter();

      // ปิด dialog
      if (mounted) Navigator.of(context).pop();

      // ถ้าเชื่อมต่อไม่สำเร็จ แสดง dialog แจ้งเตือน
      if (!isConnected) {
        if (mounted) {
          final bool continueWithoutPrinter = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('ไม่พบเครื่องพิมพ์'),
                  content: const Text('ไม่สามารถเชื่อมต่อเครื่องพิมพ์ได้'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('ยกเลิก'),
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
    }

    // ถ้าเชื่อมต่อได้ ให้พิมพ์ใบรับคืนสินค้า
    if (isConnected) {
      final state = context.read<ReturnProductHistoryBloc>().state;
      if (state is ReturnProductHistoryDetailLoaded) {
        // แปลงข้อมูลใน state ให้เป็นรูปแบบที่ใช้กับ ReceiptReturnPrinterService ได้
        final items = state.items.map((item) {
          return CartItemModel(
            itemCode: item.itemCode,
            itemName: item.itemName,
            barcode: "", // ReturnProductHistoryDetailModel ไม่มี barcode ให้ใส่ค่าว่าง
            price: item.price,
            sumAmount: (item.totalAmount).toString(),
            unitCode: item.unitCode,
            whCode: item.whCode,
            shelfCode: item.shelfCode,
            ratio: item.ratio,
            standValue: item.standValue,
            divideValue: item.divideValue,
            qty: item.qty,
            refRow: "", // ไม่มีค่า refRow ในรายละเอียดประวัติการรับคืน
          );
        }).toList();

        // สร้าง CustomerModel
        final customer = CustomerModel(
          code: widget.custCode,
          name: widget.custName,
          address: '',
        );

        // สร้าง SaleDocumentModel สำหรับอ้างอิง
        final saleDocument = SaleDocumentModel(
          docNo: widget.invNo,
          docDate: '', // ไม่มีข้อมูลวันที่เอกสารขายอ้างอิง
          docTime: '',
          custCode: widget.custCode,
          custName: widget.custName,
          totalAmount: widget.totalAmount.toString(), // ใช้ค่า totalAmount จาก widget
          cashAmount: "0",
          transferAmount: "0",
          cardAmount: "0",
        );

        // แสดง loading dialog และเริ่มกระบวนการพิมพ์
        PrintingDialog.show(
          context: context,
          title: 'กำลังพิมพ์ใบรับคืนสินค้า',
          documentNumber: widget.docNo,
          additionalMessage: 'โปรดรอสักครู่...',
        );

        await Future.delayed(const Duration(seconds: 1));

        // เริ่มพิมพ์ใบรับคืนในแบ็คกราวนด์
        try {
          // อ่านข้อมูล warehouse และ employee code

          final warehouseCode = Global.whCode;
          final empCode = Global.empCode;

          // พิมพ์ใบรับคืนสินค้า (isCopy=true เพื่อให้มีคำว่าสำเนา)
          bool printSuccess = await _printerService.printReturnReceipt(
            customer: customer,
            saleDocument: saleDocument,
            items: items,
            payments: const [], // ไม่มีข้อมูลการชำระเงิน
            totalAmount: widget.totalAmount, // ใช้ค่า totalAmount จาก widget
            docNumber: widget.docNo,
            warehouseCode: warehouseCode,
            empCode: empCode,
            remark: widget.remark, // ส่งหมายเหตุไปพิมพ์ด้วย
            isCopy: true, // ระบุว่าเป็นการพิมพ์สำเนา
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

            // ถ้าเลือกพิมพ์ใหม่ ให้เรียกฟังก์ชันนี้อีกครั้ง
            if (printResult == 'reprint' && mounted) {
              _printReturnReceipt(totalAmount);
            }
          } else {
            // แสดงข้อความเมื่อพิมพ์ไม่สำเร็จ
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ไม่สามารถพิมพ์ใบรับคืนสินค้าได้'),
                  backgroundColor: Colors.red,
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
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // กรณีที่ไม่มีข้อมูลสำหรับพิมพ์
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่พบข้อมูลสำหรับพิมพ์ใบรับคืนสินค้า'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
