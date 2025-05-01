// lib/data/repositories/sale_repository.dart

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

  // อัพเดทสถานะการชำระเงินพรีออเดอร์
  Future<bool> updatePreOrderPayment(SaleTransactionModel transaction, String preOrderDocNo) async {
    try {
      _logger.i('Update transaction: ${transaction.docNo}');

      final response = await _apiService.post(
        '/updateTrans',
        data: transaction.toJson(),
      );

      /// debugPrint('Update transaction: ${transaction.toJson()}');
      _logger.i('Update transaction: ${transaction.toJson()}');

      _logger.i('Update transaction response: ${response.statusCode}: ${response.data}');

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
      _logger.e('Update transaction error: $e');
      throw Exception('ไม่สามารถบันทึกการขายได้: ${e.toString()}');
    }
  }
}
