// lib/data/repositories/return_product_repository.dart
import 'package:wawa_vansales/data/models/return_product/return_product_model.dart';
import 'package:wawa_vansales/data/models/return_product/sale_document_detail_model.dart';
import 'package:wawa_vansales/data/models/return_product/sale_document_model.dart';
import 'package:logger/logger.dart';
import 'package:wawa_vansales/data/services/api_service.dart';

class ReturnProductRepository {
  final ApiService _apiService;
  final Logger _logger = Logger();

  ReturnProductRepository({
    required ApiService apiService,
  }) : _apiService = apiService;

  // ดึงข้อมูลเอกสารขายตามรหัสลูกค้า
  Future<List<SaleDocumentModel>> getSaleDocuments({
    required String customerCode,
    String search = '',
    required String fromDate,
    required String toDate,
  }) async {
    try {
      final response = await _apiService.get(
        '/getDocSaleSuccess',
        queryParameters: {
          'search': search,
          'from_date': fromDate,
          'to_date': toDate,
          'cust_code': customerCode,
        },
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return (response.data['data'] as List).map((json) => SaleDocumentModel.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      _logger.e('Error getting sale documents: $e');
      throw Exception('ไม่สามารถดึงข้อมูลเอกสารขายได้: $e');
    }
  }

  // ดึงข้อมูลรายละเอียดเอกสารขาย
  Future<List<SaleDocumentDetailModel>> getSaleDocumentDetails({
    required String docNo,
  }) async {
    try {
      final response = await _apiService.get(
        '/getDocSaleSuccessDetail',
        queryParameters: {
          'doc_no': docNo,
        },
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return (response.data['data'] as List).map((json) => SaleDocumentDetailModel.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      _logger.e('Error getting sale document details: $e');
      throw Exception('ไม่สามารถดึงข้อมูลรายละเอียดเอกสารขายได้: $e');
    }
  }

  // บันทึกข้อมูลการรับคืนสินค้า
  Future<bool> saveReturnProduct(ReturnProductModel returnProductData) async {
    /// debug print
    _logger.d('ReturnProductModel: ${returnProductData.toJson()}');

    /// debug print items
    for (var item in returnProductData.items) {
      _logger.d('Item: ${item.toJson()}');
    }

    try {
      final response = await _apiService.post(
        '/saveReturn',
        data: returnProductData.toJson(),
      );

      if (response.data['success'] == true) {
        return true;
      }

      _logger.e('Error save return: ${response.data}');
      throw Exception(response.data['message'] ?? 'บันทึกข้อมูลการคืนสินค้าไม่สำเร็จ');
    } catch (e) {
      _logger.e('Error saving return: $e');
      throw Exception('ไม่สามารถบันทึกข้อมูลการคืนสินค้าได้: $e');
    }
  }
}
