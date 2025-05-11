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

      // Convert transaction to JSON
      final Map<String, dynamic> jsonData = transaction.toJson();

      // Pretty print the JSON with type information
      _printJsonWithTypes(jsonData, 'Transaction data for Postman testing');

      final response = await _apiService.post(
        '/saveTrans',
        data: jsonData,
      );

      _logger.i('Save transaction response: ${response.statusCode}: ${response.data}');

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

  // Helper method to print JSON with type information
  void _printJsonWithTypes(dynamic data, String title) {
    debugPrint('\n===== $title =====');
    if (data is Map) {
      debugPrint('{');
      data.forEach((key, value) {
        final type = _getTypeString(value);
        debugPrint('  "$key": ${_formatValue(value)} // $type');

        // Special handling for items and payment_detail arrays to expand their contents
        if ((key == 'items' || key == 'payment_detail') && value is List && value.isNotEmpty) {
          _printNestedArrayDetails(value, key);
        }
      });
      debugPrint('}');
    } else if (data is List) {
      debugPrint('[');
      for (var item in data) {
        final type = _getTypeString(item);
        debugPrint('  ${_formatValue(item)} // $type');
      }
      debugPrint(']');
    } else {
      final type = _getTypeString(data);
      debugPrint('${_formatValue(data)} // $type');
    }
    debugPrint('===== End of $title =====\n');
  }

  // Print details of nested arrays (items and payment_detail)
  void _printNestedArrayDetails(List items, String arrayName) {
    debugPrint('  ===== $arrayName Details =====');
    for (int i = 0; i < items.length; i++) {
      var item = items[i];
      if (item != null) {
        debugPrint('    --- Item ${i + 1} ---');
        if (item is Map) {
          item.forEach((key, value) {
            final type = _getTypeString(value);
            debugPrint('    "$key": ${_formatValue(value)} // $type');
          });
        } else {
          // Convert to map if it's a model object
          try {
            Map<String, dynamic> itemMap = item.toJson();
            itemMap.forEach((key, value) {
              final type = _getTypeString(value);
              debugPrint('    "$key": ${_formatValue(value)} // $type');
            });
          } catch (e) {
            debugPrint('    $item // ${item.runtimeType}');
          }
        }
      }
    }
    debugPrint('  ===== End of $arrayName Details =====');
  }

  // Get a string representing the type
  String _getTypeString(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return 'String';
    if (value is int) return 'int';
    if (value is double) return 'double';
    if (value is bool) return 'boolean';
    if (value is List) return 'array';
    if (value is Map) return 'object';
    return value.runtimeType.toString();
  }

  // Format the value for printing
  String _formatValue(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return '"$value"';
    if (value is Map || value is List) return value.toString();
    return value.toString();
  }

  // อัพเดทสถานะการชำระเงินพรีออเดอร์
  Future<bool> updatePreOrderPayment(SaleTransactionModel transaction, String preOrderDocNo) async {
    try {
      _logger.i('Update transaction: ${transaction.docNo}');

      // Convert transaction to JSON
      final Map<String, dynamic> jsonData = transaction.toJson();

      // Pretty print the JSON with type information
      _printJsonWithTypes(jsonData, 'UpdatePreOrderPayment data for Postman testing');

      final response = await _apiService.post(
        '/updateTrans',
        data: jsonData,
      );

      _logger.i('Update transaction response: ${response.statusCode}: ${response.data}');

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
