// lib/data/repositories/sale_repository.dart
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
    // สร้างเลขที่เอกสารตามรูปแบบที่ต้องการ
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final random = (1000 + (9999 - 1000) * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000).floor().toString();
    return 'INV$warehouseCode$dateStr-$random';
  }
}
