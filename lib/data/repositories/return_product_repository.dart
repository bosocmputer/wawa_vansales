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
        '/getDetailForReturn',
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
      // สร้าง JSON ตามรูปแบบที่ API ต้องการ
      final Map<String, dynamic> requestData = {
        'cust_code': returnProductData.custCode,
        'emp_code': returnProductData.empCode,
        'doc_date': returnProductData.docDate,
        'doc_time': returnProductData.docTime,
        'doc_no': returnProductData.docNo,
        'ref_doc_date': returnProductData.refDocDate,
        'ref_doc_no': returnProductData.refDocNo,
        'ref_amount': returnProductData.refAmount,
        'items': returnProductData.items
            .map((item) => {
                  'item_code': item.itemCode,
                  'item_name': item.itemName,
                  'barcode': item.barcode,
                  'price': item.price,
                  'sum_amount': item.sumAmount,
                  'unit_code': item.unitCode,
                  'wh_code': item.whCode,
                  'shelf_code': item.shelfCode,
                  'ratio': item.ratio,
                  'stand_value': item.standValue,
                  'divide_value': item.divideValue,
                  'ref_row': item.refRow,
                  'qty': item.qty,
                })
            .toList(),
        'payment_detail': returnProductData.paymentDetail.map((payment) => payment.toJson()).toList(),
        'tranfer_amount': returnProductData.transferAmount,
        'credit_amount': returnProductData.creditAmount,
        'cash_amount': returnProductData.cashAmount,
        'card_amount': returnProductData.cardAmount,
        'total_amount': returnProductData.totalAmount,
        'total_value': returnProductData.totalValue,
        'remark': returnProductData.remark.isEmpty ? '' : returnProductData.remark,
      };

      // แสดง debug ข้อมูลที่จะส่งไป API
      _logger.d('Request data: $requestData');

      final response = await _apiService.post(
        '/saveReturn',
        data: requestData,
      );

      // ตรวจสอบ response
      if (response.statusCode == 200) {
        if (response.data is Map && response.data['success'] == true) {
          return true;
        } else if (response.data is Map && response.data.containsKey('ERROR')) {
          // กรณี API ส่ง error กลับมา
          final errorMessage = response.data['ERROR'] ?? 'เกิดข้อผิดพลาดจาก server';
          _logger.e('API Error: $errorMessage');
          throw Exception('บันทึกไม่สำเร็จ: $errorMessage');
        } else {
          // กรณีที่ไม่มี success flag หรือ response format ไม่ตรงตาม spec
          _logger.w('Unexpected response format: ${response.data}');
          return true; // อาจจะสำเร็จแต่ response format ไม่ตรงตาม spec
        }
      } else {
        _logger.e('HTTP Error: ${response.statusCode} - ${response.data}');
        throw Exception('เกิดข้อผิดพลาดจาก server (${response.statusCode})');
      }
    } catch (e) {
      _logger.e('Error saving return: $e');

      // แยกประเภทของ error เพื่อให้ข้อความที่เหมาะสม
      if (e.toString().contains('JSONObject["remark"] not found')) {
        throw Exception('รูปแบบข้อมูลไม่ถูกต้อง: ไม่พบข้อมูล remark');
      } else if (e.toString().contains('type \'String\' is not a subtype of type \'int\'')) {
        throw Exception('เกิดข้อผิดพลาดในการแปลงข้อมูล: รูปแบบข้อมูลไม่ถูกต้อง');
      } else if (e is Exception) {
        rethrow; // ส่งต่อ Exception ที่สร้างขึ้นแล้ว
      } else {
        throw Exception('ไม่สามารถบันทึกข้อมูลการคืนสินค้าได้: $e');
      }
    }
  }
}
