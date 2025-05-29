import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

class Env {
  static final Logger _logger = Logger();

  static String? get apiBaseUrl {
    String? url = dotenv.env['API_BASE_URL'];
    _logger.i('Using API URL: $url');
    return url;
  }

  static String? get qrApiKey {
    String? key = dotenv.env['QR_API_KEY'];
    return key;
  }
}
