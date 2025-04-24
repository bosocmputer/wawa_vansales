import 'package:wawa_vansales/data/models/user_model.dart';
import 'package:wawa_vansales/data/services/api_service.dart';
import 'package:wawa_vansales/utils/local_storage.dart';
import 'package:logger/logger.dart';

class AuthRepository {
  final ApiService _apiService;
  final LocalStorage _localStorage;
  final Logger _logger = Logger();

  AuthRepository({
    required ApiService apiService,
    required LocalStorage localStorage,
  })  : _apiService = apiService,
        _localStorage = localStorage;

  // Login method
  Future<UserModel> login(String userCode, String password) async {
    _logger.i('Logging in with user: $userCode, password: $password');

    try {
      final response = await _apiService.get(
        '/loginemp',
        queryParameters: {'user_code': userCode, 'password': password},
      );

      _logger.i('Login response: ${response.statusCode}: ${response.data}');

      // Check if response is successful
      if (response.statusCode == 200) {
        final responseData = response.data;
        _logger.i('Response data type: ${responseData.runtimeType}');
        _logger.i('Response data structure: $responseData');

        // Verify response format and success status
        if (responseData is Map<String, dynamic> && responseData.containsKey('success')) {
          final success = responseData['success'] as bool;

          if (success) {
            // API returned success true
            if (responseData.containsKey('data')) {
              final dataList = responseData['data'] as List;

              if (dataList.isNotEmpty) {
                // Normal successful login with user data
                final userData = dataList[0] as Map<String, dynamic>;
                final user = UserModel.fromJson(userData);

                _logger.i('Successfully parsed user: ${user.userName}');

                // Save user data
                await _saveUserData(user);

                return user;
              } else {
                // API returned success:true but empty data array
                // This means the username doesn't exist in the system
                _logger.w('API returned success with empty data array. Username does not exist: $userCode');

                throw Exception('ชื่อผู้ใช้ไม่มีในระบบ');
              }
            } else {
              throw Exception('ข้อมูลตอบกลับไม่มีฟิลด์ data');
            }
          } else {
            // API explicitly returned success:false
            throw Exception('การเข้าสู่ระบบล้มเหลว: ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง');
          }
        } else {
          throw Exception('รูปแบบข้อมูลตอบกลับไม่ถูกต้อง');
        }
      } else {
        throw Exception('เกิดข้อผิดพลาดจากเซิร์ฟเวอร์: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error during login process: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('เกิดข้อผิดพลาดในการเชื่อมต่อกับเซิร์ฟเวอร์');
    }
  }

  // Helper method to save user data
  Future<void> _saveUserData(UserModel user) async {
    _logger.i('Saving user data for: ${user.userCode}');
    await _localStorage.saveString('user_code', user.userCode);

    await _localStorage.saveString('user_name', user.userName);

    await _localStorage.saveBool('is_logged_in', true);
  }

  // ตรวจสอบว่ามีการ login อยู่หรือไม่
  Future<bool> isLoggedIn() async {
    return await _localStorage.isLoggedIn();
  }

  // ดึงข้อมูลผู้ใช้ที่ login อยู่
  Future<UserModel?> getCurrentUser() async {
    return await _localStorage.getUserData();
  }

  // ทำการ logout
  Future<void> logout() async {
    await _localStorage.clearUserData();
    await _localStorage.clearWarehouseAndLocation();
    await _localStorage.setLoggedIn(false);
  }
}
