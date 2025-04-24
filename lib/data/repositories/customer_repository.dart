import 'package:logger/logger.dart';
import 'package:wawa_vansales/data/models/customer_model.dart';
import 'package:wawa_vansales/data/services/api_service.dart';

class CustomerRepository {
  final ApiService _apiService;
  final Logger _logger = Logger();

  CustomerRepository({
    required ApiService apiService,
  }) : _apiService = apiService;

  // ดึงรายการลูกค้าทั้งหมด
  Future<List<CustomerModel>> getCustomers({String search = ''}) async {
    try {
      _logger.i('Fetching customers with search: $search');

      final response = await _apiService.get(
        '/getCustomerList',
        queryParameters: {
          'search': search,
        },
      );

      _logger.i('Get customers response: ${response.statusCode}: ${response.data}');

      if (response.statusCode == 404) {
        _logger.e('API endpoint not found (404)');
        return _getMockCustomers();
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
          return _getMockCustomers();
        }

        final customerResponse = CustomerResponse.fromJson(validResponse);

        if (!customerResponse.success || customerResponse.data.isEmpty) {
          if (search.isNotEmpty) {
            // ถ้ามีการค้นหา แต่ไม่พบข้อมูล ให้ return empty list
            return [];
          }
          throw Exception('ไม่พบข้อมูลลูกค้า');
        }

        return customerResponse.data;
      } catch (parseError) {
        _logger.e('Error parsing response: $parseError');
        return _getMockCustomers();
      }
    } catch (e) {
      _logger.e('Get customers error: $e');
      return _getMockCustomers();
    }
  }

  // สร้างลูกค้าใหม่
  Future<bool> createCustomer(CustomerModel customer) async {
    try {
      _logger.i('Creating new customer: ${customer.code}, ${customer.name}');

      final customerData = {
        'code': customer.code,
        'ar_status': customer.arstatus,
        'name_1': customer.name,
        'address': customer.address,
        'telephone': customer.telephone,
        'tax_id': customer.taxId,
      };

      final response = await _apiService.post(
        '/createNewCust',
        data: customerData,
      );

      _logger.i('Create customer response: ${response.statusCode}: ${response.data}');

      if (response.statusCode == 404) {
        _logger.e('API endpoint not found (404)');
        return false;
      }

      try {
        if (response.data == null) {
          throw Exception('ไม่มีข้อมูลตอบกลับจาก API');
        }

        // Log response data format
        _logger.i('Response data type: ${response.data.runtimeType}');

        // ใช้ข้อมูลจริงถ้ามีรูปแบบที่ถูกต้อง
        Map<String, dynamic> validResponse;

        if (response.data is Map && (response.data.containsKey('success') || response.data.containsKey('msg'))) {
          validResponse = response.data;
          // Check if API returns success: true or msg: "success"
          return validResponse['success'] == true || validResponse['msg'] == 'success';
        } else {
          _logger.w('Invalid response format');
          return false;
        }
      } catch (parseError) {
        _logger.e('Error parsing response: $parseError');
        return false;
      }
    } catch (e) {
      _logger.e('Create customer error: $e');
      return false;
    }
  }

  // ข้อมูลจำลองสำหรับลูกค้า
  List<CustomerModel> _getMockCustomers() {
    return [
      CustomerModel(
        code: 'AR00468',
        name: 'ได้รับเงินจากคระกรรมการหมู่บ้าน โนนผาสุก หมู่ 9',
        taxId: '',
      ),
      CustomerModel(
        code: 'AR00472',
        name: 'ร.ร.บ้านเชียงแหว',
        taxId: '',
        address: 'หมู่ 1 ต.เชียงแหว อ. กุมภวาปี จ. อุดรธานี',
      ),
      CustomerModel(
        code: 'AR00473',
        name: 'ร้านค้าตัวอย่าง',
        taxId: '1234567890123',
        address: 'เลขที่ 123 ถ.สุขุมวิท กรุงเทพฯ',
        telephone: '02-123-4567',
      ),
    ];
  }
}
