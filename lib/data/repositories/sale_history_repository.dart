import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:wawa_vansales/data/models/sale_history_model.dart';
import 'package:wawa_vansales/data/models/sale_history_detail_model.dart';
import 'package:wawa_vansales/data/services/api_service.dart';
import 'package:wawa_vansales/utils/local_storage.dart';

class SaleHistoryRepository {
  final ApiService _apiService;
  final LocalStorage _localStorage;
  final Logger _logger = Logger();

  SaleHistoryRepository({
    required ApiService apiService,
    required LocalStorage localStorage,
  })  : _apiService = apiService,
        _localStorage = localStorage;

  // Get sale history for the specified date range
  Future<List<SaleHistoryModel>> getSaleHistory({
    String search = '',
    DateTime? fromDate,
    DateTime? toDate,
    String? warehouseCode,
  }) async {
    try {
      // Set default dates to today if not provided
      final now = DateTime.now();
      final dateFormatter = DateFormat('yyyy-MM-dd');

      final from = fromDate ?? now;
      final to = toDate ?? now;

      // Format dates for API
      final fromDateStr = dateFormatter.format(from);
      final toDateStr = dateFormatter.format(to);

      // Get warehouse code from storage if not provided
      final whCode = warehouseCode ?? await _getWarehouseCode();

      _logger.i('Fetching sale history with search: $search, dates: $fromDateStr to $toDateStr, warehouse: $whCode');

      final response = await _apiService.get(
        '/getDocSaleHistory',
        queryParameters: {
          'search': search,
          'from_date': fromDateStr,
          'to_date': toDateStr,
          'wh_code': whCode,
        },
      );

      _logger.i('Get sale history response: ${response.statusCode}: ${response.data}');

      if (response.statusCode == 200) {
        try {
          if (response.data == null) {
            throw Exception('ไม่มีข้อมูลตอบกลับจาก API');
          }

          // Log response data format
          _logger.i('Response data type: ${response.data.runtimeType}');

          if (response.data is Map && response.data.containsKey('data') && response.data.containsKey('success')) {
            final saleHistoryResponse = SaleHistoryResponse.fromJson(response.data);

            if (!saleHistoryResponse.success) {
              throw Exception('API returned success: false');
            }

            return saleHistoryResponse.data;
          } else {
            _logger.w('Invalid response format, using empty list');
            return [];
          }
        } catch (parseError) {
          _logger.e('Error parsing response: $parseError');
          return [];
        }
      } else {
        _logger.e('API request failed with status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      _logger.e('Get sale history error: $e');
      return [];
    }
  }

  // Get sale history detail by document number
  Future<List<SaleHistoryDetailModel>> getSaleHistoryDetail(String docNo) async {
    try {
      _logger.i('Fetching sale history detail for doc: $docNo');

      final response = await _apiService.get(
        '/getDocSaleHistoryDetail',
        queryParameters: {
          'doc_no': docNo,
        },
      );

      _logger.i('Get sale history detail response: ${response.statusCode}: ${response.data}');

      if (response.statusCode == 200) {
        try {
          if (response.data == null) {
            throw Exception('ไม่มีข้อมูลตอบกลับจาก API');
          }

          // Log response data format
          _logger.i('Response data type: ${response.data.runtimeType}');

          if (response.data is Map && response.data.containsKey('data') && response.data.containsKey('success')) {
            final detailResponse = SaleHistoryDetailResponse.fromJson(response.data);

            if (!detailResponse.success) {
              throw Exception('API returned success: false');
            }

            return detailResponse.data;
          } else {
            _logger.w('Invalid response format, using empty list');
            return [];
          }
        } catch (parseError) {
          _logger.e('Error parsing response: $parseError');
          return [];
        }
      } else {
        _logger.e('API request failed with status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      _logger.e('Get sale history detail error: $e');
      return [];
    }
  }

  // Get warehouse code from localStorage
  Future<String> _getWarehouseCode() async {
    try {
      final warehouse = await _localStorage.getWarehouse();
      return warehouse?.code ?? 'NA';
    } catch (e) {
      _logger.e('Error getting warehouse code: $e');
      return 'NA';
    }
  }

  Future<Map<String, dynamic>> getTodaySalesSummary() async {
    try {
      final today = DateTime.now();
      final dateFormatter = DateFormat('yyyy-MM-dd');
      final todayStr = dateFormatter.format(today);

      // Get warehouse code from storage
      final whCode = await _getWarehouseCode();

      _logger.i('Fetching today\'s sales summary for date: $todayStr, warehouse: $whCode');

      final response = await _apiService.get(
        '/getDocSaleHistory',
        queryParameters: {
          'search': '',
          'from_date': todayStr,
          'to_date': todayStr,
          'wh_code': whCode,
        },
      );

      if (response.statusCode == 200 && response.data is Map && response.data.containsKey('data') && response.data.containsKey('success')) {
        final saleHistoryResponse = SaleHistoryResponse.fromJson(response.data);

        if (!saleHistoryResponse.success) {
          return {'totalAmount': 0.0, 'billCount': 0};
        }

        final bills = saleHistoryResponse.data;
        final billCount = bills.length;

        // Calculate total amount by summing all bills
        double totalAmount = 0.0;
        for (var bill in bills) {
          totalAmount += bill.totalAmountValue;
        }

        return {
          'totalAmount': totalAmount,
          'billCount': billCount,
        };
      } else {
        return {'totalAmount': 0.0, 'billCount': 0};
      }
    } catch (e) {
      _logger.e('Get today\'s sales summary error: $e');
      return {'totalAmount': 0.0, 'billCount': 0};
    }
  }
}
