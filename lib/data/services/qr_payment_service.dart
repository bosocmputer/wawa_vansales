// lib/data/services/qr_payment_service.dart
import 'dart:convert';
import 'dart:math';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:wawa_vansales/config/env.dart';

class QrPaymentResponse {
  final String qrCode;
  final String txnUid;
  final String status;
  final String? message;

  QrPaymentResponse({
    required this.qrCode,
    required this.txnUid,
    required this.status,
    this.message,
  });

  factory QrPaymentResponse.fromJson(Map<String, dynamic> json) {
    return QrPaymentResponse(
      qrCode: json['qrCode'] ?? '',
      txnUid: json['txnUid'] ?? '',
      status: json['status'] ?? '',
      message: json['message'],
    );
  }
}

class QrPaymentStatusResponse {
  final String txnStatus;
  final String? txnNo;
  final String? message;

  QrPaymentStatusResponse({
    required this.txnStatus,
    this.txnNo,
    this.message,
  });

  factory QrPaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    return QrPaymentStatusResponse(
      txnStatus: json['txnStatus'] ?? '',
      txnNo: json['txnNo'],
      message: json['message'],
    );
  }

  bool get isPaid => txnStatus.toUpperCase() == 'PAID';
}

class QrPaymentService {
  final Logger _logger = Logger();
  final String _createQrUrl = 'https://kapiqr.smlsoft.com/qrapi/create-promptpay-qrcode';
  final String _checkStatusUrl = 'https://kapiqr.smlsoft.com/qrapi/payment-status';

  final String apiKey = Env.qrApiKey ?? '';

  // สร้าง reference id แบบสุ่ม
  String _generateRandomReference() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString(); // 6-digit random number
  }

  // สร้าง QR Code สำหรับชำระเงิน
  Future<QrPaymentResponse> createQrCode(double amount, {String? docNo}) async {
    try {
      final ref1 = docNo ?? _generateRandomReference();
      final ref2 = _generateRandomReference();
      final ref3 = _generateRandomReference();
      final ref4 = _generateRandomReference();

      final response = await http.post(
        Uri.parse(_createQrUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
        body: jsonEncode({
          'amount': amount,
          'ref1': ref1,
          'ref2': ref2,
          'ref3': ref3,
          'ref4': ref4,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _logger.i('QR Code created successfully: $responseData');

        // ตรวจสอบว่า response มี format เป็นอย่างไร เพราะอาจจะเป็น Base64 หรือ String QR ธรรมดา
        String qrCode = '';
        if (responseData['qrCode'] != null) {
          qrCode = responseData['qrCode'];
        } else if (responseData['promptPayQrCode'] != null) {
          // กรณีที่ API คืนค่าในชื่อ promptPayQrCode แทน qrCode
          qrCode = responseData['promptPayQrCode'];
        }

        return QrPaymentResponse(
          qrCode: qrCode,
          txnUid: responseData['txnUid'] ?? '',
          status: responseData['status'] ?? 'SUCCESS',
          message: responseData['message'],
        );
      } else {
        _logger.e('Failed to create QR Code: ${response.statusCode} - ${response.body}');
        return QrPaymentResponse(
          qrCode: '',
          txnUid: '',
          status: 'ERROR',
          message: 'Failed to create QR Code: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.e('Exception creating QR Code: $e');
      return QrPaymentResponse(
        qrCode: '',
        txnUid: '',
        status: 'ERROR',
        message: 'Exception: $e',
      );
    }
  }

  // ตรวจสอบสถานะการชำระเงิน
  Future<QrPaymentStatusResponse> checkPaymentStatus(String txnUid) async {
    try {
      final response = await http.post(
        Uri.parse(_checkStatusUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
        body: jsonEncode({
          'txnUid': txnUid,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _logger.i('Payment status checked: $responseData');

        // ตรวจสอบว่า response มี format เป็นอย่างไร
        String status = '';
        String? txnNo;

        if (responseData['txnStatus'] != null) {
          status = responseData['txnStatus'];
        } else if (responseData['status'] != null) {
          status = responseData['status'];
        }

        if (responseData['txnNo'] != null) {
          txnNo = responseData['txnNo'];
        } else if (responseData['transactionId'] != null) {
          txnNo = responseData['transactionId'];
        }

        return QrPaymentStatusResponse(
          txnStatus: status,
          txnNo: txnNo,
          message: responseData['message'],
        );
      } else {
        _logger.e('Failed to check payment status: ${response.statusCode} - ${response.body}');
        return QrPaymentStatusResponse(
          txnStatus: 'ERROR',
          message: 'Failed to check payment status: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.e('Exception checking payment status: $e');
      return QrPaymentStatusResponse(
        txnStatus: 'ERROR',
        message: 'Exception: $e',
      );
    }
  }
}
