// lib/utils/network_helper.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';

class NetworkHelper {
  final Logger _logger = Logger();
  final Connectivity _connectivity = Connectivity();

  // ตรวจสอบสถานะการเชื่อมต่อเครือข่าย
  Future<bool> isConnected() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      _logger.e('Error checking connectivity: $e');
      return false;
    }
  }

  // สร้าง retry mechanism สำหรับการเรียกใช้ API
  // T คือ type ของข้อมูลที่จะ return
  Future<T?> withRetry<T>({
    required Future<T> Function() apiCall,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        // ตรวจสอบการเชื่อมต่อก่อนเรียก API
        final isNetworkAvailable = await isConnected();
        if (!isNetworkAvailable) {
          _logger.w('No network connection. Retry ${retryCount + 1}/$maxRetries');
          retryCount++;

          if (retryCount >= maxRetries) {
            throw Exception('ไม่สามารถเชื่อมต่อเครือข่ายได้ กรุณาตรวจสอบการเชื่อมต่ออินเตอร์เน็ต');
          }

          await Future.delayed(retryDelay * retryCount);
          continue;
        }

        // เรียกใช้ API
        final result = await apiCall();
        return result;
      } catch (e) {
        _logger.e('API call failed: $e. Retry ${retryCount + 1}/$maxRetries');
        retryCount++;

        if (retryCount >= maxRetries) {
          throw Exception('เกิดข้อผิดพลาดในการเชื่อมต่อ: $e');
        }

        await Future.delayed(retryDelay * retryCount);
      }
    }

    return null;
  }

  // ตรวจสอบและลิสเทนการเปลี่ยนแปลงสถานะการเชื่อมต่อ
  Stream<ConnectivityResult> get connectivityStream => _connectivity.onConnectivityChanged;

  // ตรวจสอบว่าเป็น error จากปัญหาการเชื่อมต่อหรือไม่
  bool isNetworkError(dynamic error) {
    if (error is Exception) {
      final errorMessage = error.toString().toLowerCase();
      return errorMessage.contains('socketexception') ||
          errorMessage.contains('timeout') ||
          errorMessage.contains('connection refused') ||
          errorMessage.contains('network is unreachable');
    }
    return false;
  }
}
