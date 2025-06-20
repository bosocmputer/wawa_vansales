// lib/ui/screens/sale/qr_payment_dialog.dart
import 'dart:async';
import 'dart:convert'; // เพิ่มเพื่อใช้ JsonEncoder

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // เพิ่มเพื่อใช้ Clipboard
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wawa_vansales/blocs/cart/cart_bloc.dart';
import 'package:wawa_vansales/blocs/cart/cart_event.dart';
import 'package:wawa_vansales/blocs/cart/cart_state.dart';
import 'package:wawa_vansales/data/models/payment_model.dart';
import 'package:wawa_vansales/data/models/sale_transaction_model.dart';
import 'package:wawa_vansales/data/services/qr_payment_service.dart';
import 'package:wawa_vansales/ui/screens/home_screen.dart';

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

      // เริ่มตรวจสอบสถานะการชำระเงินทุก 10 วินาที
      _startCheckingStatus();
    } catch (e) {
      if (kDebugMode) {
        print('เกิดข้อผิดพลาดในการสร้าง QR Code: $e');
      }

      String errorMsg = 'เกิดข้อผิดพลาด';

      if (e is DioException) {
        final dioError = e;
        errorMsg = 'เกิดข้อผิดพลาดในการเชื่อมต่อ: ${dioError.message}\n';

        // เพิ่มรายละเอียด error จาก Dio
        if (dioError.response != null) {
          try {
            final errorData = dioError.response?.data;
            if (errorData != null) {
              errorMsg += 'รายละเอียด: ${jsonEncode(errorData)}';
            } else {
              errorMsg += 'รหัสข้อผิดพลาด: ${dioError.response?.statusCode}';
            }
          } catch (jsonError) {
            errorMsg += 'ข้อผิดพลาดจาก API: ${dioError.response?.statusCode} - ${dioError.response?.statusMessage}';
          }
        } else if (dioError.error != null) {
          errorMsg += 'รายละเอียด: ${dioError.error}';
        }
      } else {
        errorMsg = 'เกิดข้อผิดพลาด: $e';
      }

      setState(() {
        _isLoading = false;
        _errorMessage = errorMsg;
      });
    }
  }

  void _startCheckingStatus() {
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
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
        _timeoutTimer?.cancel(); // หยุดการนับเวลาถอยหลังด้วยเมื่อชำระเงินสำเร็จ

        if (response.txnNo == null || response.txnNo!.isEmpty) {
          // กรณีไม่มีเลขที่รายการ
          _showErrorDialog("ข้อมูลการชำระเงินไม่สมบูรณ์", "ไม่พบข้อมูลเลขที่รายการ (Transaction Number)\n\nTransaction ID: $_txnUid");

          setState(() {
            _isCheckingStatus = false;
          });
          return;
        }

        setState(() {
          _paymentSuccess = true;
          _isCheckingStatus = false;
          _txnNo = response.txnNo;
        });

        // บันทึกข้อมูลลงใน log เพื่อการตรวจสอบ
        if (kDebugMode) {
          print("การชำระเงินด้วย QR Code สำเร็จ: TxnUID=$_txnUid, TxnNo=$_txnNo, Amount=${widget.amount}");
        }

        // ให้เพิ่มวิธีการชำระเงิน แต่ยังไม่บันทึกรายการขาย รอให้ user กดปุ่มเอง
        if (mounted) {
          _finishPayment();
        }
      } else {
        // กรณียังไม่มีการชำระเงิน
        if (kDebugMode) {
          print("ยังไม่มีการชำระเงิน สถานะ: ${response.txnStatus}");
        }

        setState(() {
          _isCheckingStatus = false;
        });
      }
    } catch (e) {
      // กรณีเกิด error ในการเรียก API
      if (kDebugMode) {
        print("เกิดข้อผิดพลาดในการตรวจสอบสถานะการชำระเงิน: $e");
      }

      setState(() {
        _isCheckingStatus = false;
      });
    }
  }

  void _finishPayment() {
    // เมื่อชำระเงินเสร็จสิ้น ให้รอสักครู่แล้วดำเนินการต่อ
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        // ตรวจสอบข้อมูลที่จำเป็นก่อนทำการบันทึก
        if (_txnUid == null || _txnUid!.isEmpty) {
          _showErrorDialog("ไม่พบข้อมูลรหัสอ้างอิงธุรกรรม (Transaction UID)", "กรุณาลองทำรายการใหม่อีกครั้ง");
          return;
        }

        if (_txnNo == null || _txnNo!.isEmpty) {
          _showErrorDialog("ไม่พบเลขที่การทำรายการ (Transaction Number)", "กรุณาลองทำรายการใหม่อีกครั้ง");
          return;
        }

        // สร้าง PaymentModel สำหรับ QR Code โดยกำหนดค่าทุกฟิลด์ให้ครบถ้วน
        final payment = PaymentModel(
          payType: PaymentModel.paymentTypeToInt(PaymentType.qrCode),
          transNumber: _txnUid!, // เก็บ txnUid ใน transNumber
          payAmount: widget.amount,
          noApproved: _txnNo!, // เก็บ txnNo ใน noApproved (transaction number)
          charge: 0.0, // ค่าธรรมเนียม (ถ้ามี)
        );

        try {
          // เพิ่มวิธีการชำระเงินเท่านั้น แต่ไม่ submit sale อัตโนมัติ
          context.read<CartBloc>().add(AddPayment(payment));

          // แสดง SnackBar เพื่อบอกให้ผู้ใช้กดปุ่มบันทึกรายการขาย
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('การชำระเงินสำเร็จแล้ว กรุณากดปุ่ม "บันทึกรายการขาย"'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );

          // ไม่ต้องเรียก SubmitSale อัตโนมัติ เพื่อให้ผู้ใช้กดปุ่มเอง
        } catch (e) {
          _showErrorDialog("error", e.toString());
        }
      }
    });
  }

  // แสดง Dialog สำหรับข้อผิดพลาดที่ให้สามารถ copy ข้อความได้
  void _showErrorDialog(
    String title,
    String errorMessage,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // สร้าง JSON ที่จะแสดงในรูปแบบ Map
        final Map<String, dynamic> errorData = {
          'timestamp': DateTime.now().toIso8601String(),
          'transaction': {
            'txnUid': _txnUid ?? 'N/A',
            'txnNo': _txnNo ?? 'N/A',
            'amount': widget.amount,
            'docNumber': widget.docNumber ?? 'N/A',
          },
          'error': {
            'title': title,
            'message': errorMessage,
          },
          'deviceInfo': {
            'platform': kIsWeb ? 'web' : Theme.of(context).platform.toString(),
            'appVersion': '1.0.0', // ควรอัพเดทเป็นเวอร์ชันจริงของแอพ
          }
        };

        // แปลง Map เป็น JSON string และจัดรูปแบบให้อ่านง่าย
        final String prettyJson = _getPrettyJsonString(errorData);

        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(child: Text(title, overflow: TextOverflow.ellipsis)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite, // ทำให้กว้างสุด
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue),
                    SizedBox(width: 4),
                    Text(
                      'รายละเอียดข้อผิดพลาด:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[400]!),
                          ),
                          child: SelectableText(
                            prettyJson,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'กดที่ข้อความค้างไว้เพื่อคัดลอก หรือกดปุ่ม "คัดลอกข้อมูล"',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // ล้าง state ของ cart ก่อนที่จะนำทางกลับไปหน้าหลัก
                context.read<CartBloc>().add(ResetCartState());

                // ปิด dialog
                Navigator.of(context).pop();

                // ปิด QR Payment Dialog
                Navigator.of(context).pop();

                // กลับไปยังหน้า home เพื่อเริ่มการขายใหม่
                Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const HomeScreen()), (Route<dynamic> route) => false);
              },
              child: const Text('ตกลง'),
            ),
            ElevatedButton(
              onPressed: () {
                // คัดลอกข้อความลงคลิปบอร์ด (ต้องใช้ package: flutter/services.dart)
                try {
                  // import 'package:flutter/services.dart'; ต้องเพิ่มบรรทัดนี้ที่บนสุดของไฟล์
                  Clipboard.setData(ClipboardData(text: prettyJson));

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('คัดลอกข้อมูลแล้ว สามารถส่งให้ผู้พัฒนาได้'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ไม่สามารถคัดลอกข้อมูลได้: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }

                // ล้าง state ของ cart ก่อนที่จะนำทางกลับไปหน้าหลัก
                context.read<CartBloc>().add(ResetCartState());

                // ปิด dialog
                Navigator.of(context).pop();

                // ปิด QR Payment Dialog
                Navigator.of(context).pop();

                // กลับไปยังหน้า home เพื่อเริ่มการขายใหม่
                Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const HomeScreen()), (Route<dynamic> route) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text('คัดลอกข้อมูล'),
            ),
          ],
        );
      },
    );
  }

  // ฟังก์ชันสำหรับจัดรูปแบบ JSON String ให้อ่านง่าย
  String _getPrettyJsonString(Map<String, dynamic> json) {
    String result = '';
    try {
      const JsonEncoder encoder = JsonEncoder.withIndent('  ');
      result = encoder.convert(json);
    } catch (e) {
      result = json.toString();
    }
    return result;
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

  void _showErrorDialogWithTransaction(String title, String errorMessage, SaleTransactionModel transactionData) {
    showDialog(
      context: context,
      barrierDismissible: false, // ไม่ให้กดพื้นที่นอก dialog ปิด
      builder: (BuildContext context) {
        // แปลง Map เป็น JSON string และจัดรูปแบบให้อ่านง่าย
        final String prettyJson = _getPrettyJsonString(transactionData.toJson());

        // คำนวณความสูงของ dialog ตามขนาดหน้าจอ
        final double screenHeight = MediaQuery.of(context).size.height;
        final double dialogMaxHeight = screenHeight * 0.7; // ใช้ 70% ของความสูงหน้าจอ
        final double jsonContainerHeight = dialogMaxHeight * 0.6; // 60% ของความสูง dialog

        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(child: Text(title, overflow: TextOverflow.ellipsis)),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: dialogMaxHeight,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // แสดงข้อความ error
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // หัวข้อข้อมูลการทำรายการ
                const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue),
                    SizedBox(width: 4),
                    Text(
                      'ข้อมูลการทำรายการ:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 16),

                // สร้าง container สำหรับ JSON ที่สามารถเลื่อนได้
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    height: jsonContainerHeight,
                    child: SingleChildScrollView(
                      child: SelectableText(
                        prettyJson,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                  ),
                ),

                // ข้อความแนะนำการคัดลอก
                const Padding(
                  padding: EdgeInsets.only(top: 8.0, bottom: 4.0),
                  child: Text(
                    'กดที่ข้อความค้างไว้เพื่อคัดลอก หรือกดปุ่ม "คัดลอก"',
                    style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            // จัดให้ปุ่มอยู่ในแถวเดียวกัน
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // กระจายปุ่มไปทางซ้าย-ขวา
              children: [
                // ปุ่มคัดลอกอยู่ซ้าย
                TextButton.icon(
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('คัดลอก'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: prettyJson));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('คัดลอกข้อมูลแล้ว'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),

                // ปุ่มตกลงอยู่ขวา
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    // ล้าง state ของ cart ก่อนที่จะนำทางกลับไปหน้าหลัก
                    context.read<CartBloc>().add(ResetCartState());

                    // ปิด dialog
                    Navigator.of(context).pop();

                    // ปิด QR Payment Dialog
                    Navigator.of(context).pop();

                    // กลับไปยังหน้า home เพื่อเริ่มการขายใหม่
                    // ใช้ Navigator.of(context).pushAndRemoveUntil เพื่อล้าง stack ก่อนหน้า
                    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const HomeScreen()), (Route<dynamic> route) => false // ล้างทุก routes ก่อนหน้า
                        );
                  },
                  child: const Text('ตกลง'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CartBloc, CartState>(
      listenWhen: (previous, current) => current is CartSubmitSuccess || current is CartError || current is CartSubmitting,
      listener: (context, state) {
        // ถ้ากำลังบันทึกข้อมูล ไม่ต้องทำอะไร รอให้ state เปลี่ยนเป็น CartSubmitSuccess หรือ CartError
        if (state is CartSubmitting) {
          if (kDebugMode) {
            print("QrPaymentDialog: กำลังประมวลผลการบันทึกรายการ...");
          }
        }
        // ถ้าบันทึกการขายเสร็จสิ้น
        else if (state is CartSubmitSuccess) {
          // หมายเหตุ: เราต้องการปิด QR dialog และ processing dialog แต่ไม่ต้องการปิด SaleScreen
          // ที่ถูกต้องแล้วคือ ไม่ต้องปิด dialog ที่นี่เลย ให้ SaleScreen จัดการเอง

          if (kDebugMode) {
            print("QrPaymentDialog: บันทึกรายการสำเร็จ เลขที่เอกสาร: ${state.documentNumber}");
          }
        }
        // กรณีเกิดข้อผิดพลาด
        else if (state is CartError) {
          // หยุดการทำงานของทุก timer
          _statusCheckTimer?.cancel();
          _timeoutTimer?.cancel();

          setState(() {
            _isCheckingStatus = false;
            _isLoading = false;
          });

          _showErrorDialogWithTransaction("error", state.message, state.transaction!);
        }
      },
      child: AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.qr_code, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('ชำระด้วย QR Code'),
            const Spacer(),
            // ซ่อนปุ่มปิด (close) ไม่ให้ผู้ใช้กด
            Visibility(
              visible: false,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _paymentSuccess ? null : _cancelPayment,
              ),
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
                          child: Column(
                            children: [
                              Row(
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
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.amber.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.amber.shade800, size: 20),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'กรุณากดปุ่ม "บันทึกรายการขาย" ด้านล่างเพื่อดำเนินการต่อ',
                                        style: TextStyle(
                                          color: Colors.amber.shade800,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.left,
                                      ),
                                    ),
                                  ],
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    // ตรวจสอบว่ามีการเพิ่มวิธีการชำระเงินแล้ว
                    if (_txnUid != null && _txnUid!.isNotEmpty && _txnNo != null && _txnNo!.isNotEmpty) {
                      try {
                        // สร้าง JSON ของข้อมูลที่จะส่งไป
                        final Map<String, dynamic> submitData = {
                          'action': 'SubmitSale',
                          'payload': {
                            'qrPayment': {'txnUid': _txnUid, 'txnNo': _txnNo, 'amount': widget.amount, 'timestamp': DateTime.now().toIso8601String()},
                            'docNumber': widget.docNumber
                          }
                        };

                        // บันทึก log เพื่อการตรวจสอบ
                        if (kDebugMode) {
                          print("กำลังส่งข้อมูลไปที่ SubmitSale: ${jsonEncode(submitData)}");
                        }

                        // เรียกบันทึกรายการขาย
                        context.read<CartBloc>().add(const SubmitSale());

                        // แสดงข้อความกำลังบันทึกรายการ
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('กำลังบันทึกรายการขาย...'),
                            backgroundColor: Colors.blue,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } catch (e) {
                        _showErrorDialog("เกิดข้อผิดพลาดในการเรียกบันทึกรายการขาย", e.toString());
                      }
                    } else {
                      _showErrorDialog("ข้อมูลการชำระเงินไม่สมบูรณ์", "กรุณาติดต่อผู้ดูแลระบบ\n\nTxnUID: ${_txnUid ?? 'ไม่มีข้อมูล'}\nTxnNo: ${_txnNo ?? 'ไม่มีข้อมูล'}");
                    }
                  },
                  child: const Text('บันทึกรายการขาย'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
