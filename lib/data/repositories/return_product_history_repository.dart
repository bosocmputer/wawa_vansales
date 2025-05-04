// lib/data/repositories/return_product_history_repository.dart
import 'package:logger/logger.dart';
import 'package:wawa_vansales/data/models/return_product/return_product_history_detail_model.dart';
import 'package:wawa_vansales/data/models/return_product/return_product_history_model.dart';
import 'package:wawa_vansales/data/services/api_service.dart';

class ReturnProductHistoryRepository {
  final ApiService _apiService;
  final Logger _logger = Logger();

  ReturnProductHistoryRepository({
    required ApiService apiService,
  }) : _apiService = apiService;

  // ดึงข้อมูลรายการประวัติการรับคืนสินค้า
  Future<List<ReturnProductHistoryModel>> getReturnProductHistory({
    String search = '',
    required String fromDate,
    required String toDate,
  }) async {
    try {
      final response = await _apiService.get(
        '/getDocReturnHistory',
        queryParameters: {
          'search': search,
          'from_date': fromDate,
          'to_date': toDate,
        },
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return (response.data['data'] as List).map((json) => ReturnProductHistoryModel.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      _logger.e('Error getting return product history: $e');
      throw Exception('ไม่สามารถดึงข้อมูลประวัติการรับคืนสินค้าได้: $e');
    }
  }

  // ดึงข้อมูลรายละเอียดของรายการรับคืนสินค้า
  Future<List<ReturnProductHistoryDetailModel>> getReturnProductHistoryDetail({
    required String docNo,
  }) async {
    try {
      final response = await _apiService.get(
        '/getDocReturnHistoryDetail',
        queryParameters: {
          'doc_no': docNo,
        },
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return (response.data['data'] as List).map((json) => ReturnProductHistoryDetailModel.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      _logger.e('Error getting return product history detail: $e');
      throw Exception('ไม่สามารถดึงข้อมูลรายละเอียดการรับคืนสินค้าได้: $e');
    }
  }
}
