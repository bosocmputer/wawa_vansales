import 'package:dio/dio.dart';
import 'package:wawa_vansales/config/env.dart';
import 'package:logger/logger.dart';

class ApiService {
  final Dio _dio = Dio();
  final Logger _logger = Logger();

  ApiService() {
    _dio.options.baseUrl = Env.apiBaseUrl!;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    // เซ็ต validateStatus ให้ยอมรับทุก status code เพื่อจัดการ error เอง
    _dio.options.validateStatus = (status) => true;

    // เพิ่ม interceptor สำหรับการ log และจัดการ error
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        _logger.i('REQUEST[${options.method}] => PATH: ${options.path} => DATA: ${options.data}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        _logger.i('RESPONSE[${response.statusCode}] => DATA: ${response.data}');
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        _logger.e('ERROR[${e.response?.statusCode}] => ${e.message}');
        return handler.next(e);
      },
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final fullUrl = '${_dio.options.baseUrl}$path';
      _logger.i('Full URL: $fullUrl with params: $queryParameters');

      return await _dio.get(
        path,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  void _handleError(DioException e) {
    String errorMessage = 'เกิดข้อผิดพลาดในการเชื่อมต่อ';

    if (e.response != null) {
      errorMessage = 'เกิดข้อผิดพลาด: ${e.response!.statusCode}';
      if (e.response!.data != null && e.response!.data['message'] != null) {
        errorMessage = e.response!.data['message'];
      }
    } else if (e.error != null) {
      // เพิ่ม log รายละเอียด error
      _logger.e('Error details: ${e.error}');
      errorMessage = 'การเชื่อมต่อล้มเหลว: ${e.error}';
    } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
      errorMessage = 'หมดเวลาการเชื่อมต่อ กรุณาลองอีกครั้ง';
    } else if (e.type == DioExceptionType.unknown) {
      errorMessage = 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต';
    }

    _logger.e('API Error: $errorMessage');
  }
}
