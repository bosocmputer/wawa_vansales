// /lib/data/repositories/pre_order_history_repository.dart
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:wawa_vansales/data/models/pre_order_history_model.dart';
import 'package:wawa_vansales/data/models/pre_order_history_detail_model.dart';
import 'package:wawa_vansales/data/services/api_service.dart';
import 'package:wawa_vansales/utils/local_storage.dart';

class PreOrderHistoryRepository {
  final ApiService _apiService;
  final LocalStorage? _localStorage;
  final Logger _logger = Logger();

  PreOrderHistoryRepository({
    required ApiService apiService,
    LocalStorage? localStorage,
  })  : _apiService = apiService,
        _localStorage = localStorage;

  // ดึงรายการประวัติการขาย (พรีออเดอร์)
  Future<List<PreOrderHistoryModel>> getPreOrderHistoryList({
    String search = '',
    DateTime? fromDate,
    DateTime? toDate,
    required String warehouseCode,
  }) async {
    try {
      // ตั้งค่าวันเริ่มต้นและวันสิ้นสุดเป็นวันนี้ถ้าไม่ได้ระบุ
      final now = DateTime.now();
      final dateFormatter = DateFormat('yyyy-MM-dd');

      final from = fromDate ?? now;
      final to = toDate ?? now;

      // แปลงวันที่สำหรับ API
      final fromDateStr = dateFormatter.format(from);
      final toDateStr = dateFormatter.format(to);

      _logger.i('Fetching pre-order history with search: $search, dates: $fromDateStr to $toDateStr');

      final response = await _apiService.get(
        'getDocPreorderHistory',
        queryParameters: {
          'search': search,
          'from_date': fromDateStr,
          'to_date': toDateStr,
          'wh_code': warehouseCode,
        },
      );

      _logger.i('Get pre-order history response: ${response.statusCode}: ${response.data}');

      if (response.statusCode == 200) {
        try {
          if (response.data == null) {
            throw Exception('ไม่มีข้อมูลตอบกลับจาก API');
          }

          // บันทึก log รูปแบบข้อมูลที่ได้รับ
          _logger.i('Response data type: ${response.data.runtimeType}');

          if (response.data is Map && response.data.containsKey('data') && response.data.containsKey('success')) {
            final historyResponse = PreOrderHistoryResponse.fromJson(response.data);

            if (!historyResponse.success) {
              throw Exception('API returned success: false');
            }

            return historyResponse.data;
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
      _logger.e('Get pre-order history error: $e');
      return [];
    }
  }

  // Get warehouse code from localStorage
  Future<String> _getWarehouseCode() async {
    try {
      if (_localStorage != null) {
        final warehouse = await _localStorage!.getWarehouse();
        return warehouse?.code ?? 'NA';
      }
      return 'NA';
    } catch (e) {
      _logger.e('Error getting warehouse code: $e');
      return 'NA';
    }
  }

  // Get today's pre-order summary
  Future<Map<String, dynamic>> getTodaysPreOrderSummary() async {
    try {
      final today = DateTime.now();
      final dateFormatter = DateFormat('yyyy-MM-dd');
      final todayStr = dateFormatter.format(today);

      // Get warehouse code from storage
      final whCode = await _getWarehouseCode();

      _logger.i('Fetching today\'s pre-order summary for date: $todayStr, warehouse: $whCode');

      final response = await _apiService.get(
        'getDocPreorderHistory',
        queryParameters: {
          'search': '',
          'from_date': todayStr,
          'to_date': todayStr,
          'wh_code': whCode,
        },
      );

      if (response.statusCode == 200 && response.data is Map && response.data.containsKey('data') && response.data.containsKey('success')) {
        final preOrderHistoryResponse = PreOrderHistoryResponse.fromJson(response.data);

        if (!preOrderHistoryResponse.success) {
          return {'totalAmount': 0.0, 'billCount': 0};
        }

        final bills = preOrderHistoryResponse.data;
        final billCount = bills.length;

        // Calculate total amount by summing all bills
        double totalAmount = 0.0;
        for (var bill in bills) {
          totalAmount += bill.totalAmount;
        }

        return {
          'totalAmount': totalAmount,
          'billCount': billCount,
        };
      } else {
        return {'totalAmount': 0.0, 'billCount': 0};
      }
    } catch (e) {
      _logger.e('Get today\'s pre-order summary error: $e');
      return {'totalAmount': 0.0, 'billCount': 0};
    }
  }

  // ดึงรายละเอียดประวัติการขาย (พรีออเดอร์) ตาม docNo
  Future<List<PreOrderHistoryDetailModel>> getPreOrderHistoryDetail(String docNo) async {
    try {
      _logger.i('Fetching pre-order history detail for doc: $docNo');

      final response = await _apiService.get(
        'getDocPreorderHistoryDetail',
        queryParameters: {'doc_no': docNo},
      );

      _logger.i('Get pre-order history detail response: ${response.statusCode}: ${response.data}');

      if (response.statusCode == 200) {
        try {
          if (response.data == null) {
            throw Exception('ไม่มีข้อมูลตอบกลับจาก API');
          }

          // บันทึก log รูปแบบข้อมูลที่ได้รับ
          _logger.i('Response data type: ${response.data.runtimeType}');

          if (response.data is Map && response.data.containsKey('data') && response.data.containsKey('success')) {
            final detailResponse = PreOrderHistoryDetailResponse.fromJson(response.data);

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
      _logger.e('Get pre-order history detail error: $e');
      return [];
    }
  }
}

// คลาสสำหรับการตอบกลับของ API รายการประวัติการขาย (พรีออเดอร์)
class PreOrderHistoryResponse {
  final bool success;
  final List<PreOrderHistoryModel> data;

  PreOrderHistoryResponse({
    required this.success,
    required this.data,
  });

  factory PreOrderHistoryResponse.fromJson(Map<String, dynamic> json) {
    final success = json['success'] as bool? ?? false;

    List<PreOrderHistoryModel> data = [];
    if (json['data'] != null && json['data'] is List) {
      data = (json['data'] as List).map((item) => PreOrderHistoryModel.fromJson(item as Map<String, dynamic>)).toList();
    }

    return PreOrderHistoryResponse(
      success: success,
      data: data,
    );
  }
}

// คลาสสำหรับการตอบกลับของ API รายละเอียดประวัติการขาย (พรีออเดอร์)
class PreOrderHistoryDetailResponse {
  final bool success;
  final List<PreOrderHistoryDetailModel> data;

  PreOrderHistoryDetailResponse({
    required this.success,
    required this.data,
  });

  factory PreOrderHistoryDetailResponse.fromJson(Map<String, dynamic> json) {
    final success = json['success'] as bool? ?? false;

    List<PreOrderHistoryDetailModel> data = [];
    if (json['data'] != null && json['data'] is List) {
      data = (json['data'] as List).map((item) => PreOrderHistoryDetailModel.fromJson(item as Map<String, dynamic>)).toList();
    }

    return PreOrderHistoryDetailResponse(
      success: success,
      data: data,
    );
  }
}
