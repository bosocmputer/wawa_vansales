// lib/data/repositories/ar_balance_repository.dart
import 'package:logger/logger.dart';
import 'package:wawa_vansales/data/models/ar_balance_model.dart';
import 'package:wawa_vansales/data/services/api_service.dart';

class ArBalanceRepository {
  final ApiService _apiService;
  final Logger _logger = Logger();

  ArBalanceRepository({required ApiService apiService}) : _apiService = apiService;

  // ดึงข้อมูลเอกสารลดหนี้ของลูกค้า
  Future<List<ArBalanceModel>> getArBalance(String custCode) async {
    try {
      _logger.i('Fetching AR balance for customer: $custCode');

      final response = await _apiService.get('/getDocArBalnce?cust_code=$custCode');
      _logger.i('AR Balance response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final ArBalanceResponse arResponse = ArBalanceResponse.fromJson(response.data);

        if (arResponse.success && arResponse.data.isNotEmpty) {
          return arResponse.data;
        } else {
          _logger.w('No AR Balance records found');
          return [];
        }
      } else {
        _logger.e('Error fetching AR balance: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      _logger.e('Exception when fetching AR balance: $e');
      return []; // Return empty list on error
    }
  }
}
