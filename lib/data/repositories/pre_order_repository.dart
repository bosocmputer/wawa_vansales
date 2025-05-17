import 'package:wawa_vansales/data/models/pre_order_model.dart';
import 'package:wawa_vansales/data/services/api_service.dart';

class PreOrderRepository {
  final ApiService _apiService;

  PreOrderRepository({required ApiService apiService}) : _apiService = apiService;

  // ดึงรายการเอกสารพรีออเดอร์ตามลูกค้า
  Future<List<PreOrderModel>> getPreOrderList(String customerCode) async {
    try {
      final response = await _apiService.get(
        'getDocPreSaleList',
        queryParameters: {'cust_code': customerCode},
      );

      final preOrderResponse = PreOrderResponse.fromJson(response.data);
      return preOrderResponse.data;
    } catch (e) {
      // จัดการข้อผิดพลาด
      rethrow;
    }
  }

  // ดึงเอกสารพรีออเดอร์ตามเลขที่เอกสารและรหัสลูกค้า
  Future<PreOrderModel?> getDocPreSale(String customerCode, String docNo) async {
    try {
      final response = await _apiService.get(
        'getDocPreSale',
        queryParameters: {
          'cust_code': customerCode,
          'doc_no': docNo,
        },
      );

      final preOrderResponse = PreOrderResponse.fromJson(response.data);
      if (preOrderResponse.data.isNotEmpty) {
        return preOrderResponse.data.first;
      }
      return null;
    } catch (e) {
      // จัดการข้อผิดพลาด
      rethrow;
    }
  }

  // ดึงรายละเอียดเอกสารพรีออเดอร์
  Future<List<PreOrderDetailModel>> getPreOrderDetail(String docNo) async {
    try {
      final response = await _apiService.get(
        'getDocPreSaleDetail',
        queryParameters: {'doc_no': docNo},
      );

      final detailResponse = PreOrderDetailResponse.fromJson(response.data);
      return detailResponse.data;
    } catch (e) {
      // จัดการข้อผิดพลาด
      rethrow;
    }
  }
}
