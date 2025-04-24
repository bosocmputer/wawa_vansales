import 'package:wawa_vansales/data/models/warehouse_model.dart';
import 'package:wawa_vansales/data/models/location_model.dart';
import 'package:wawa_vansales/data/services/api_service.dart';
import 'package:wawa_vansales/utils/local_storage.dart';
import 'package:logger/logger.dart';

class WarehouseRepository {
  final ApiService _apiService;
  final LocalStorage _localStorage;
  final Logger _logger = Logger();

  WarehouseRepository({
    required ApiService apiService,
    required LocalStorage localStorage,
  })  : _apiService = apiService,
        _localStorage = localStorage;

  // ดึงรายการคลังทั้งหมด
  Future<List<WarehouseModel>> getWarehouses() async {
    try {
      _logger.i('Fetching warehouses');

      final response = await _apiService.get('/getWarehouse');

      _logger.i('Get warehouses response: ${response.statusCode}: ${response.data}');

      if (response.statusCode == 404) {
        _logger.e('API endpoint not found (404)');

        // ใช้ข้อมูลจำลองในกรณีที่ไม่พบ endpoint
        return _getMockWarehouses();
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
          return _getMockWarehouses();
        }

        final warehouseResponse = WarehouseResponse.fromJson(validResponse);

        if (!warehouseResponse.success || warehouseResponse.data.isEmpty) {
          throw Exception('ไม่พบข้อมูลคลัง');
        }

        return warehouseResponse.data;
      } catch (parseError) {
        _logger.e('Error parsing response: $parseError');
        return _getMockWarehouses();
      }
    } catch (e) {
      _logger.e('Get warehouses error: $e');
      return _getMockWarehouses();
    }
  }

  // ดึงรายการโลเคชั่นตามรหัสคลัง
  Future<List<LocationModel>> getLocations(String warehouseCode) async {
    try {
      _logger.i('Fetching locations for warehouse: $warehouseCode');

      final response = await _apiService.get(
        '/getLocation',
        queryParameters: {
          'whcode': warehouseCode,
        },
      );

      _logger.i('Get locations response: ${response.statusCode}: ${response.data}');

      if (response.statusCode == 404) {
        _logger.e('API endpoint not found (404)');

        // ใช้ข้อมูลจำลองในกรณีที่ไม่พบ endpoint
        return _getMockLocations(warehouseCode);
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
          return _getMockLocations(warehouseCode);
        }

        final locationResponse = LocationResponse.fromJson(validResponse);

        if (!locationResponse.success || locationResponse.data.isEmpty) {
          throw Exception('ไม่พบข้อมูลโลเคชั่น');
        }

        return locationResponse.data;
      } catch (parseError) {
        _logger.e('Error parsing response: $parseError');
        return _getMockLocations(warehouseCode);
      }
    } catch (e) {
      _logger.e('Get locations error: $e');
      return _getMockLocations(warehouseCode);
    }
  }

  // บันทึกข้อมูลคลังและโลเคชั่นที่เลือก
  Future<void> saveWarehouseAndLocation(WarehouseModel warehouse, LocationModel location) async {
    await _localStorage.saveWarehouse(warehouse);
    await _localStorage.saveLocation(location);
    await _localStorage.setWarehouseSelected(true);
  }

  // ตรวจสอบว่ามีการเลือกคลังและโลเคชั่นหรือไม่
  Future<bool> isWarehouseSelected() async {
    return await _localStorage.isWarehouseSelected();
  }

  // ดึงข้อมูลคลังที่เลือก
  Future<WarehouseModel?> getSelectedWarehouse() async {
    return await _localStorage.getWarehouse();
  }

  // ดึงข้อมูลโลเคชั่นที่เลือก
  Future<LocationModel?> getSelectedLocation() async {
    return await _localStorage.getLocation();
  }

  // ล้างข้อมูลคลังและโลเคชั่นที่เลือก
  Future<void> clearWarehouseAndLocation() async {
    await _localStorage.clearWarehouseAndLocation();
  }

  // ข้อมูลจำลองสำหรับคลัง
  List<WarehouseModel> _getMockWarehouses() {
    return [
      WarehouseModel(code: 'KKA01', name: 'พี่แก่น'),
      WarehouseModel(code: 'KKA02', name: 'บริษัท ถูกจัง ซุปเปอร์สโตร์ จำกัด'),
      WarehouseModel(code: 'KKA03', name: 'ห้างหุ้นส่วนจำกัด สมพรพานิช'),
      WarehouseModel(code: 'MMA01', name: 'ร้านวาวา'),
      WarehouseModel(code: 'MMA02', name: 'ตั้งฮั่วไถ่'),
    ];
  }

  // ข้อมูลจำลองสำหรับโลเคชั่น
  List<LocationModel> _getMockLocations(String warehouseCode) {
    return [
      LocationModel(code: '$warehouseCode-A1', name: 'โซน A ชั้น 1'),
      LocationModel(code: '$warehouseCode-A2', name: 'โซน A ชั้น 2'),
      LocationModel(code: '$warehouseCode-B1', name: 'โซน B ชั้น 1'),
      LocationModel(code: '$warehouseCode-C1', name: 'โซน C ชั้น 1'),
    ];
  }
}
