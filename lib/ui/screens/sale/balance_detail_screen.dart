// lib/ui/screens/sale/balance_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wawa_vansales/blocs/ar_balance/ar_balance_bloc.dart';
import 'package:wawa_vansales/blocs/ar_balance/ar_balance_event.dart';
import 'package:wawa_vansales/blocs/ar_balance/ar_balance_state.dart';
import 'package:wawa_vansales/blocs/cart/cart_bloc.dart';
import 'package:wawa_vansales/blocs/cart/cart_event.dart';
import 'package:wawa_vansales/blocs/cart/cart_state.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/models/ar_balance_model.dart';
import 'package:wawa_vansales/data/models/balance_detail_model.dart';
import 'package:wawa_vansales/ui/screens/warehouse/emty_state_widget.dart';

class BalanceDetailScreen extends StatefulWidget {
  final String customerCode;
  final String customerName;
  final double remainingAmount;

  const BalanceDetailScreen({
    super.key,
    required this.customerCode,
    required this.customerName,
    required this.remainingAmount,
  });

  @override
  State<BalanceDetailScreen> createState() => _BalanceDetailScreenState();
}

class _BalanceDetailScreenState extends State<BalanceDetailScreen> {
  final _currencyFormat = NumberFormat('#,##0.00', 'th_TH');
  final Map<String, TextEditingController> _controllers = {};
  List<ArBalanceModel> _arBalanceList = [];
  bool _isLoading = true;
  String _errorMessage = '';
  double _totalSelectedAmount = 0.0;

  // Map เก็บยอดที่เลือกไว้เดิม โดยใช้ docNo เป็น key
  Map<String, double> _selectedAmounts = {};

  // เพิ่มตัวแปรเพื่อเก็บยอดคงเหลือที่ต้องชำระที่เปลี่ยนแปลงได้
  double _remainingAmountAfterSelection = 0.0;

  @override
  void initState() {
    super.initState();

    // ตั้งค่ายอดคงเหลือเริ่มต้น
    _remainingAmountAfterSelection = widget.remainingAmount;

    // ดึงข้อมูลรายการลดหนี้ที่เลือกไว้เดิมจาก CartBloc
    final cartState = context.read<CartBloc>().state;
    if (cartState is CartLoaded && cartState.balanceDetail.isNotEmpty) {
      // เก็บ Map ของยอดที่เลือกไว้ โดยใช้ docNo เป็น key
      final Map<String, double> selectedAmounts = {};
      for (var detail in cartState.balanceDetail) {
        selectedAmounts[detail.docNo] = double.tryParse(detail.amount) ?? 0.0;
      }

      // บันทึก selectedAmounts ไว้ใช้ตอน _arBalanceList โหลดเสร็จ
      _selectedAmounts = selectedAmounts;
    }

    _loadArBalanceData();
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  // โหลดข้อมูลจาก ArBalanceBloc แทนการใช้ ApiService โดยตรง
  Future<void> _loadArBalanceData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // เรียกใช้ ArBalanceBloc ที่มีการ provide ไว้แล้วในแอพ
      context.read<ArBalanceBloc>().add(FetchArBalance(widget.customerCode));

      // รอสักครู่เพื่อให้ bloc ได้โหลดข้อมูล (optional)
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาดในการโหลดข้อมูล: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เลือกเอกสารลดหนี้'),
        actions: [
          if (_totalSelectedAmount > 0)
            TextButton(
              onPressed: _confirmSelection,
              child: const Text('ยืนยัน', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: BlocConsumer<ArBalanceBloc, ArBalanceState>(
        listener: (context, state) {
          if (state is ArBalanceLoaded) {
            setState(() {
              _arBalanceList = state.documents;

              // อัพเดท selectedAmount ใน _arBalanceList ตามข้อมูลที่เลือกไว้เดิม
              for (var doc in _arBalanceList) {
                if (_selectedAmounts.containsKey(doc.docNo)) {
                  doc.selectedAmount = _selectedAmounts[doc.docNo];
                }
              }

              _calculateTotalSelectedAmount();
              _isLoading = false;
            });
          } else if (state is ArBalanceError) {
            setState(() {
              _errorMessage = state.message;
              _isLoading = false;
            });
          }
        },
        builder: (context, state) {
          if (state is ArBalanceLoading || _isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ArBalanceError || _errorMessage.isNotEmpty) {
            return Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)));
          } else if (state is ArBalanceLoaded || _arBalanceList.isNotEmpty) {
            return _buildContent();
          }
          return const Center(child: Text('กรุณารอสักครู่...'));
        },
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildCustomerInfo(),
        _buildRemainingAmountInfo(),
        const Divider(),
        Expanded(
          child: _arBalanceList.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.assignment,
                  message: 'ไม่พบรายการลดหนี้สำหรับลูกค้านี้',
                )
              : _buildDocumentsList(),
        ),
        _buildTotalSection(),
      ],
    );
  }

  Widget _buildCustomerInfo() {
    // คำนวณยอดคงเหลือทั้งหมด
    double totalBalance = _arBalanceList.fold(0.0, (sum, doc) => sum + doc.balanceAmount);

    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      color: AppTheme.primaryColor.withOpacity(0.05),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ข้อมูลลูกค้าด้านซ้าย
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ลูกค้า: ${widget.customerName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('รหัส: ${widget.customerCode}', style: TextStyle(color: Colors.grey.shade700)),
              ],
            ),
          ),
          // ยอดคงเหลือทั้งหมดด้านขวา
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('ยอดคงเหลือทั้งหมด:', style: TextStyle(fontWeight: FontWeight.w500)),
              Text(
                '฿${_currencyFormat.format(totalBalance)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRemainingAmountInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('ยอดคงเหลือที่ต้องชำระ:', style: TextStyle(fontWeight: FontWeight.w500)),
          Text(
            '฿${_currencyFormat.format(_remainingAmountAfterSelection)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _arBalanceList.length,
      itemBuilder: (context, index) {
        final document = _arBalanceList[index];
        final docNo = document.docNo;

        if (!_controllers.containsKey(docNo)) {
          _controllers[docNo] = TextEditingController(text: document.selectedAmount?.toStringAsFixed(2) ?? '');
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // เลขที่เอกสาร
                    Text(
                      docNo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    // วันที่เอกสาร
                    Text(
                      document.docDate,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // ยอดคงเหลือ
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ยอดคงเหลือ:'),
                    Text(
                      '฿${_currencyFormat.format(document.balanceAmount)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // ช่องกรอกจำนวนเงินที่ต้องการลดหนี้
                Row(
                  children: [
                    const Text('จำนวนเงินที่ต้องการใช้:'),
                    const Spacer(),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: _controllers[docNo],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.end,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          prefixText: '฿',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          double? amount = double.tryParse(value);

                          // ถ้าค่าที่กรอกเกินยอดคงเหลือของเอกสาร ให้แก้เป็นค่าสูงสุดที่เป็นไปได้
                          if (amount != null && amount > document.balanceAmount) {
                            amount = document.balanceAmount;
                            _controllers[docNo]!.text = amount.toStringAsFixed(2);
                            // ตำแหน่ง cursor ไปท้ายข้อความ
                            _controllers[docNo]!.selection = TextSelection.fromPosition(
                              TextPosition(offset: _controllers[docNo]!.text.length),
                            );
                          }

                          // อัพเดทค่าที่เลือกในเอกสารและคำนวณยอดรวมใหม่
                          _updateSelectedAmount(document, amount ?? 0.0);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _updateSelectedAmount(ArBalanceModel document, double amount) {
    setState(() {
      document.selectedAmount = amount;
      _calculateTotalSelectedAmount();
    });
  }

  void _calculateTotalSelectedAmount() {
    double total = 0.0;
    for (var doc in _arBalanceList) {
      total += doc.selectedAmount ?? 0.0;
    }
    setState(() {
      _totalSelectedAmount = total;
      _remainingAmountAfterSelection = widget.remainingAmount - _totalSelectedAmount;
    });
  }

  Widget _buildTotalSection() {
    final isExceeded = _totalSelectedAmount > widget.remainingAmount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ยอดเงินที่เลือกชำระ:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                '฿${_currencyFormat.format(_totalSelectedAmount)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: isExceeded ? Colors.red : AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          if (isExceeded)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'ยอดที่เลือกเกินยอดที่ต้องชำระ',
                style: TextStyle(color: Colors.red),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _totalSelectedAmount <= 0 || isExceeded ? null : _confirmSelection,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'ยืนยันการชำระ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSelection() {
    final selectedDocs = _arBalanceList.where((doc) => doc.selectedAmount != null && doc.selectedAmount! > 0).toList();

    if (selectedDocs.isNotEmpty) {
      // คำนวณและตรวจสอบยอดรวม
      final totalAmount = selectedDocs.fold(0.0, (sum, doc) => sum + (doc.selectedAmount ?? 0));

      if (totalAmount <= widget.remainingAmount) {
        // แปลง ArBalanceModel เป็น BalanceDetailModel
        final List<BalanceDetailModel> balanceDetails = selectedDocs
            .map((doc) => BalanceDetailModel(
                  transFlag: "48", // รหัสเอกสารลดหนี้
                  docNo: doc.docNo,
                  docDate: doc.docDate,
                  amount: (doc.selectedAmount ?? 0.0).toString(),
                  balanceRef: doc.balance,
                ))
            .toList();

        // ส่งข้อมูลกลับไปยัง CartBloc
        context.read<CartBloc>().add(UpdateBalanceDetails(
              balanceDetails: balanceDetails,
              totalBalanceAmount: totalAmount,
            ));

        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ยอดรวมที่เลือกเกินกว่ายอดที่ต้องชำระ โปรดปรับยอดใหม่'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกอย่างน้อย 1 รายการ'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
