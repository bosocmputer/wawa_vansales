// lib/ui/screens/sale/qr_payment_dialog.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wawa_vansales/blocs/cart/cart_bloc.dart';
import 'package:wawa_vansales/blocs/cart/cart_event.dart';
import 'package:wawa_vansales/blocs/cart/cart_state.dart';
import 'package:wawa_vansales/data/models/payment_model.dart';
import 'package:wawa_vansales/data/services/qr_payment_service.dart';

class QrPaymentDialog extends StatefulWidget {
  final double amount;
  final String? docNumber;
  final int timeoutSeconds;

  const QrPaymentDialog({
    super.key,
    required this.amount,
    this.docNumber,
    this.timeoutSeconds = 180, // ค่าเริ่มต้น 3 นาที
  });

  static Future<PaymentModel?> show(
    BuildContext context, {
    required double amount,
    String? docNumber,
    required int timeoutSeconds,
  }) async {
    return await showDialog<PaymentModel>(
      context: context,
      barrierDismissible: false,
      // เพิ่มการตั้งชื่อ route เพื่อให้สามารถอ้างอิงได้ใน Navigator.popUntil
      routeSettings: const RouteSettings(name: 'QrPaymentDialog'),
      builder: (context) => QrPaymentDialog(
        amount: amount,
        docNumber: docNumber,
        timeoutSeconds: timeoutSeconds,
      ),
    );
  }

  @override
  State<QrPaymentDialog> createState() => _QrPaymentDialogState();
}

class _QrPaymentDialogState extends State<QrPaymentDialog> {
  final QrPaymentService _qrPaymentService = QrPaymentService();

  bool _isLoading = true;
  bool _isCheckingStatus = false;
  bool _paymentSuccess = false;
  bool _isTimedOut = false;

  String? _qrCode;
  String? _txnUid;
  String? _txnNo;
  String? _errorMessage;

  Timer? _statusCheckTimer;
  Timer? _timeoutTimer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _createQrCode();
    _startTimeoutTimer();
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _startTimeoutTimer() {
    // เริ่มนับเวลาถอยหลัง
    _timeoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });

      // เมื่อเวลาหมด
      if (_elapsedSeconds >= widget.timeoutSeconds) {
        _timeoutTimer?.cancel();
        _statusCheckTimer?.cancel();
        setState(() {
          _isTimedOut = true;
          _errorMessage = 'หมดเวลาการชำระเงิน กรุณาลองใหม่อีกครั้ง';
        });
      }
    });
  }

  Future<void> _createQrCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _qrPaymentService.createQrCode(
        widget.amount,
        docNo: widget.docNumber,
      );

      if (response.status == 'ERROR' || response.qrCode.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = response.message ?? 'ไม่สามารถสร้าง QR Code ได้';
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _qrCode = response.qrCode;
        _txnUid = response.txnUid;
      });

      // เริ่มตรวจสอบสถานะการชำระเงินทุก 5 วินาที
      _startCheckingStatus();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'เกิดข้อผิดพลาด: $e';
      });
    }
  }

  void _startCheckingStatus() {
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkPaymentStatus();
    });
  }

  Future<void> _checkPaymentStatus() async {
    // ถ้าไม่มี txnUid หรือกำลังตรวจสอบสถานะอยู่ หรือชำระเงินแล้ว หรือหมดเวลา ให้ข้าม
    if (_txnUid == null || _isCheckingStatus || _paymentSuccess || _isTimedOut) return;

    setState(() {
      _isCheckingStatus = true;
    });

    try {
      final response = await _qrPaymentService.checkPaymentStatus(_txnUid!);

      if (response.isPaid) {
        // หยุดการตรวจสอบสถานะ
        _statusCheckTimer?.cancel();

        setState(() {
          _paymentSuccess = true;
          _isCheckingStatus = false;
          _txnNo = response.txnNo;
        });

        // สร้าง PaymentModel และปิดไดอะล็อก
        if (mounted) {
          _finishPayment();
        }
      } else {
        setState(() {
          _isCheckingStatus = false;
        });
      }
    } catch (e) {
      setState(() {
        _isCheckingStatus = false;
      });
    }
  }

  void _finishPayment() {
    // เมื่อชำระเงินเสร็จสิ้น ให้รอสักครู่แล้วดำเนินการต่อ
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        // สร้าง PaymentModel สำหรับ QR Code
        final payment = PaymentModel(
          payType: PaymentModel.paymentTypeToInt(PaymentType.qrCode),
          transNumber: _txnUid ?? '', // เก็บ txnUid ใน transNumber
          payAmount: widget.amount,
          noApproved: _txnNo ?? '', // เก็บ txnNo ใน noApproved (transaction number)
        );

        // แสดงข้อความรอสักครู่ก่อนบันทึกการขาย
        showDialog(
          context: context,
          barrierDismissible: false,
          // เพิ่มการตั้งชื่อ route เพื่อให้สามารถอ้างอิงได้ใน Navigator.popUntil
          routeSettings: const RouteSettings(name: 'QrProcessingDialog'),
          builder: (dialogContext) => const AlertDialog(
            title: Text('กำลังดำเนินการ'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('กำลังบันทึกการขาย กรุณารอสักครู่...'),
              ],
            ),
          ),
        );

        // เพิ่มวิธีการชำระเงินก่อน
        context.read<CartBloc>().add(AddPayment(payment));

        // บันทึกการขายทันที - ไม่จำเป็นต้องใช้ Future.delayed เพราะ addPayment
        // เป็น synchronous operation ใน bloc
        context.read<CartBloc>().add(const SubmitSale());

        // หมายเหตุ: BlocListener จะจัดการกับการปิด dialogs และแสดง PrintReceiptDialog
        // เมื่อได้รับ CartSubmitSuccess state
      }
    });
  }

  void _cancelPayment() {
    // ยกเลิกการตรวจสอบสถานะ
    _statusCheckTimer?.cancel();
    Navigator.of(context).pop(null); // ส่งค่า null กลับเมื่อยกเลิก
  }

  Widget _buildQrCodeImage() {
    if (_qrCode != null && _qrCode!.isNotEmpty) {
      // ใช้ QrImageView จาก qr_flutter แทนการใช้ base64
      return QrImageView(
        data: _qrCode!,
        version: QrVersions.auto,
        size: 250,
        backgroundColor: Colors.white,
      );
    } else {
      return const SizedBox(
        width: 250,
        height: 250,
        child: Center(
          child: Text('QR Code ไม่ถูกต้อง'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CartBloc, CartState>(
      listenWhen: (previous, current) => current is CartSubmitSuccess || current is CartError,
      listener: (context, state) {
        // ถ้าบันทึกการขายเสร็จสิ้น ให้ปิด dialog
        if (state is CartSubmitSuccess) {
          // ข้อผิดพลาดอาจเกิดจากการที่เราปิด dialog มากเกินไปหรือน้อยเกินไป
          // แทนที่จะเรียก pop() หลายครั้ง เราใช้ Navigator.of(context).popUntil
          // เพื่อปิดเฉพาะ dialogs ที่เราสร้าง แต่ไม่ปิด SaleScreen

          // หมายเหตุ: เราต้องการปิด QR dialog และ processing dialog แต่ไม่ต้องการปิด SaleScreen
          // ที่ถูกต้องแล้วคือ ไม่ต้องปิด dialog ที่นี่เลย ให้ SaleScreen จัดการเอง

          if (kDebugMode) {
            print("QrPaymentDialog: ได้รับ CartSubmitSuccess state - จะรอให้ SaleScreen จัดการ");
          }
          // ไม่ปิด dialog ใดๆ ที่นี่ เพราะ SaleScreen จะจัดการเอง
        } else if (state is CartError) {
          // ถ้าเกิดข้อผิดพลาด ให้ยกเลิก loading dialog
          Navigator.of(context).popUntil((route) => route == ModalRoute.of(context));

          // แสดงข้อความแจ้งเตือนข้อผิดพลาด
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.qr_code, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('ชำระด้วย QR Code'),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _paymentSuccess ? null : _cancelPayment,
            ),
          ],
        ),
        content: SizedBox(
          width: 300,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // จำนวนเงิน
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '฿${widget.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // สถานะหรือข้อผิดพลาด
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700, size: 40),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _createQrCode,
                          child: const Text('ลองใหม่'),
                        ),
                      ],
                    ),
                  )
                else if (_isLoading)
                  const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('กำลังสร้าง QR Code...'),
                    ],
                  )
                else if (_paymentSuccess)
                  Column(
                    children: [
                      // แสดง QR Code พร้อมเครื่องหมายถูกทับด้านบน
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // QR Code ด้านล่าง
                          _buildQrCodeImage(),

                          // พื้นหลังโปร่งใสเพื่อให้เห็น QR Code จางๆ
                          Container(
                            width: 250,
                            height: 250,
                            color: Colors.white.withOpacity(0.7),
                          ),

                          // เครื่องหมายถูกและข้อความ
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.green.shade500,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 50,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.green.shade700,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'ชำระเงินสำเร็จ',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // แสดงข้อความหากมีหมายเลขอ้างอิง
                      if (_txnNo != null && _txnNo!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'หมายเลขอ้างอิง: $_txnNo',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildQrCodeImage(),
                      const SizedBox(height: 16),

                      // แสดงเวลาที่เหลือ
                      Text(
                        'เวลาที่เหลือ: ${widget.timeoutSeconds - _elapsedSeconds} วินาที',
                        style: TextStyle(
                          color: (widget.timeoutSeconds - _elapsedSeconds) < 30 ? Colors.red : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (_isCheckingStatus)
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('กำลังตรวจสอบสถานะการชำระเงิน...'),
                          ],
                        )
                      else
                        const Text('สแกน QR Code เพื่อชำระเงิน'),
                      const SizedBox(height: 8),
                      const Text(
                        'QR Code ใช้ได้เฉพาะการชำระเงินเต็มจำนวนเท่านั้น',
                        style: TextStyle(color: Colors.amber, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        actions: [
          if (!_isLoading && !_paymentSuccess && _errorMessage == null)
            TextButton(
              onPressed: _cancelPayment,
              child: const Text('ยกเลิก'),
            ),
          if (_paymentSuccess)
            ElevatedButton(
              onPressed: () {
                if (!_statusCheckTimer!.isActive) {
                  _finishPayment();
                }
              },
              child: const Text('ตกลง'),
            ),
        ],
      ),
    );
  }
}
