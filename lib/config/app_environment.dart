import 'package:logger/logger.dart';

enum Environment {
  development,
  production,
}

class AppEnvironment {
  static Environment _environment = Environment.development;
  static Logger? _logger;

  // Initialize environment settings
  static void init({Environment environment = Environment.development}) {
    _environment = environment;

    // Configure logger based on environment
    _logger = Logger(
      filter: _getLogFilter(),
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        // ignore: deprecated_member_use
        printTime: true,
      ),
    );
  }

  // Access the current environment
  static Environment get environment => _environment;

  // Check if we're in development mode
  static bool get isDevelopment => _environment == Environment.development;

  // Check if we're in production mode
  static bool get isProduction => _environment == Environment.production;

  // Get the configured logger
  static Logger get logger => _logger ?? Logger();

  static bool get isDebugMode {
    bool isDebug = false;
    // This is set to true only during debugging
    assert(() {
      isDebug = true;
      return true;
    }());
    return isDebug;
  }

  // Get the appropriate log filter based on environment
  static LogFilter _getLogFilter() {
    if (isProduction) {
      return ProductionFilter();
    } else {
      return DevelopmentFilter();
    }
  }
}

// Custom filter that only shows warning and above in production
class ProductionFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    return event.level.index >= Level.warning.index;
  }
}

// Custom filter that shows all logs in development
class DevelopmentFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    return true;
  }
}
