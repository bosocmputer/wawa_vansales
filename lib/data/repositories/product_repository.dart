import 'package:logger/logger.dart';
import 'package:wawa_vansales/data/models/product_balance_model.dart';
import 'package:wawa_vansales/data/models/product_detail_model.dart';
import 'package:wawa_vansales/data/models/product_model.dart';
import 'package:wawa_vansales/data/services/api_service.dart';

class ProductRepository {
  final ApiService _apiService;
  final Logger _logger = Logger();

  ProductRepository({
    required ApiService apiService,
  }) : _apiService = apiService;

  // ดึงรายการสินค้าตามคำค้นหา
  Future<List<ProductModel>> getProducts({
    String search = '',
    String whCode = '',
    String shelfCode = '',
  }) async {
    try {
      _logger.i('Fetching products with search: $search');

      final response = await _apiService.get(
        '/getBarcodeList',
        queryParameters: {
          'search': search,
          'wh_code': whCode,
          'shelf_code': shelfCode,
        },
      );

      _logger.i('Get products response: ${response.statusCode}: ${response.data}');

      if (response.statusCode == 404) {
        _logger.e('API endpoint not found (404)');
        return _getMockProducts();
      }

      try {
        if (response.data == null) {
          throw Exception('ไม่มีข้อมูลตอบกลับจาก API');
        }

        // Log response data format
        _logger.i('Response data type: ${response.data.runtimeType}');

        // ใช้ข้อมูลจริงถ้ามีรูปแบบที่ถูกต้อง หรือใช้ mock ถ้าไม่ใช่
        Map<String, dynamic> validResponse;

        if (response.data is Map && response.data.containsKey('data') && response.data.containsKey('success')) {
          validResponse = response.data;
        } else {
          _logger.w('Invalid response format, using mock data');
          return _getMockProducts();
        }

        final productResponse = ProductResponse.fromJson(validResponse);

        if (!productResponse.success || productResponse.data.isEmpty) {
          if (search.isNotEmpty) {
            // ถ้ามีการค้นหา แต่ไม่พบข้อมูล ให้ return empty list
            return [];
          }
          throw Exception('ไม่พบข้อมูลสินค้า');
        }

        return productResponse.data;
      } catch (parseError) {
        _logger.e('Error parsing response: $parseError');
        return _getMockProducts();
      }
    } catch (e) {
      _logger.e('Get products error: $e');
      return _getMockProducts();
    }
  }

  Future<List<ProductModel>> getProductsReturn({
    String search = '',
    String custCode = '',
  }) async {
    try {
      _logger.i('Fetching products with search: $search');

      final response = await _apiService.get(
        '/getReturnItemsList',
        queryParameters: {
          'search': search,
          'cust_code': custCode,
        },
      );

      _logger.i('Get products response: ${response.statusCode}: ${response.data}');

      if (response.statusCode == 404) {
        _logger.e('API endpoint not found (404)');
        return _getMockProducts();
      }

      try {
        if (response.data == null) {
          throw Exception('ไม่มีข้อมูลตอบกลับจาก API');
        }

        // Log response data format
        _logger.i('Response data type: ${response.data.runtimeType}');

        // ใช้ข้อมูลจริงถ้ามีรูปแบบที่ถูกต้อง หรือใช้ mock ถ้าไม่ใช่
        Map<String, dynamic> validResponse;

        if (response.data is Map && response.data.containsKey('data') && response.data.containsKey('success')) {
          validResponse = response.data;
        } else {
          _logger.w('Invalid response format, using mock data');
          return _getMockProducts();
        }

        final productResponse = ProductResponse.fromJson(validResponse);

        if (!productResponse.success || productResponse.data.isEmpty) {
          if (search.isNotEmpty) {
            // ถ้ามีการค้นหา แต่ไม่พบข้อมูล ให้ return empty list
            return [];
          }
          throw Exception('ไม่พบข้อมูลสินค้า');
        }

        return productResponse.data;
      } catch (parseError) {
        _logger.e('Error parsing response: $parseError');
        return _getMockProducts();
      }
    } catch (e) {
      _logger.e('Get products error: $e');
      return _getMockProducts();
    }
  }

  Future<ProductDetailModel?> getProductByBarcode(String barcode, String customerCode) async {
    try {
      _logger.i('Fetching product detail with barcode: $barcode for customer: $customerCode');

      final response = await _apiService.get(
        '/getBarcodeDetail',
        queryParameters: {
          'barcode': barcode,
          'cust_code': customerCode,
        },
      );

      _logger.i('Get product detail response: ${response.statusCode}: ${response.data}');

      if (response.statusCode == 404) {
        _logger.e('API endpoint not found (404)');
        return null;
      }

      try {
        if (response.data == null) {
          throw Exception('ไม่มีข้อมูลตอบกลับจาก API');
        }

        // Log response data format
        _logger.i('Response data type: ${response.data.runtimeType}');

        Map<String, dynamic> validResponse;

        if (response.data is Map && response.data.containsKey('data') && response.data.containsKey('success')) {
          validResponse = response.data;
        } else {
          _logger.w('Invalid response format, using mock data');
          return null;
        }

        final productResponse = ProductDetailResponse.fromJson(validResponse);

        if (!productResponse.success || productResponse.data.isEmpty) {
          _logger.w('Product not found or API returned empty data');
          return null;
        }

        return productResponse.data.first;
      } catch (parseError) {
        _logger.e('Error parsing response: $parseError');
        return null;
      }
    } catch (e) {
      _logger.e('Get product detail error: $e');
      return null;
    }
  }

  // ดึงข้อมูลยอดสินค้าคงเหลือจากคลัง
  Future<List<ProductBalanceModel>> getBalanceWarehouse({
    String search = '',
    required String whCode,
    required String shelfCode,
  }) async {
    try {
      _logger.i('Fetching product balance with search: $search, whCode: $whCode, shelfCode: $shelfCode');

      final response = await _apiService.get(
        '/getBalanceWarehouse',
        queryParameters: {
          'search': search,
          'wh_code': whCode,
          'shelf_code': shelfCode,
        },
      );

      _logger.i('Get product balance response: ${response.statusCode}: ${response.data}');

      if (response.statusCode == 404) {
        _logger.e('API endpoint not found (404)');
        return [];
      }

      try {
        if (response.data == null) {
          throw Exception('ไม่มีข้อมูลตอบกลับจาก API');
        }

        _logger.i('Response data type: ${response.data.runtimeType}');

        Map<String, dynamic> validResponse;

        if (response.data is Map && response.data.containsKey('data') && response.data.containsKey('success')) {
          validResponse = response.data;
        } else {
          _logger.w('Invalid response format');
          return [];
        }

        final balanceResponse = ProductBalanceResponse.fromJson(validResponse);

        if (!balanceResponse.success || balanceResponse.data.isEmpty) {
          if (search.isNotEmpty) {
            // ถ้ามีการค้นหา แต่ไม่พบข้อมูล ให้ return empty list
            return [];
          }
          throw Exception('ไม่พบข้อมูลสินค้าคงเหลือ');
        }

        return balanceResponse.data;
      } catch (parseError) {
        _logger.e('Error parsing response: $parseError');
        return [];
      }
    } catch (e) {
      _logger.e('Get product balance error: $e');
      return [];
    }
  }

  // ข้อมูลสินค้าจำลอง
  List<ProductModel> _getMockProducts() {
    return [
      ProductModel(
        itemCode: '03-1433',
        itemName: 'ยาแก้ปวดเมื่อยตราแรมโบ้150ซีซี',
        barcode: '8852314999998',
        price: 0,
        unitCode: 'ชิ้น',
        standValue: '1.00',
        divideValue: '1.00',
        ratio: '1.00',
      ),
      ProductModel(
        itemCode: '05-2126',
        itemName: 'กระเทียมเจียว ตราบุญทิพย์80กรัม/10บ.',
        barcode: '3539629999107',
        price: 0,
        unitCode: 'ลัง200',
        standValue: '200.00',
        divideValue: '1.00',
        ratio: '200.00',
      ),
      ProductModel(
        itemCode: '06-4909',
        itemName: 'พอนด์ส เอจ มิราเคิล ไนท์แคร์ ครีม10กรัม',
        barcode: '8999999059934',
        price: 0,
        unitCode: 'ชิ้น',
        standValue: '1.00',
        divideValue: '1.00',
        ratio: '1.00',
      ),
    ];
  }
}
