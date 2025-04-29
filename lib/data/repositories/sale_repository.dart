// lib/data/repositories/sale_repository.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:wawa_vansales/data/models/sale_transaction_model.dart';
import 'package:wawa_vansales/data/services/api_service.dart';

class SaleRepository {
  final ApiService _apiService;
  final Logger _logger = Logger();

  SaleRepository({
    required ApiService apiService,
  }) : _apiService = apiService;

  // บันทึกการขาย
  Future<bool> saveSaleTransaction(SaleTransactionModel transaction) async {
    try {
      _logger.i('Saving sale transaction: ${transaction.docNo}');

      final response = await _apiService.post(
        '/saveTrans',
        data: transaction.toJson(),
      );

      _logger.i('Save transaction response: ${response.statusCode}: ${response.data}');

      debugPrint(transaction.toJson().toString());
      if (response.statusCode == 200) {
        // ตรวจสอบรูปแบบ response
        if (response.data is Map && response.data.containsKey('success')) {
          return response.data['success'] == true;
        }
        return true; // ถ้า response ไม่มี success field ให้ถือว่าสำเร็จ
      }

      return false;
    } catch (e) {
      _logger.e('Save transaction error: $e');
      throw Exception('ไม่สามารถบันทึกการขายได้: ${e.toString()}');
    }
  }

// สร้างเลขที่เอกสาร
  String generateDocumentNumber(String warehouseCode) {
    // สร้างเลขที่เอกสารตามรูปแบบ MINVwhcodeyymmdd-xxx
    final now = DateTime.now();
    // ใช้รูปแบบปี 2 หลัก เดือน 2 หลัก วัน 2 หลัก
    final dateStr = '${(now.year % 100).toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    // สร้างเลขสุ่ม 3 หลัก
    final random = (100 + Random().nextInt(900)).toString();

    return 'MINV$warehouseCode$dateStr-$random';
  }
}
