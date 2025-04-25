import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wawa_vansales/blocs/auth/auth_bloc.dart';
import 'package:wawa_vansales/blocs/bloc_observer.dart';
import 'package:wawa_vansales/blocs/customer/customer_bloc.dart';
import 'package:wawa_vansales/blocs/product/product_bloc.dart';
import 'package:wawa_vansales/blocs/warehouse/warehouse_bloc.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/repositories/auth_repository.dart';
import 'package:wawa_vansales/data/repositories/customer_repository.dart';
import 'package:wawa_vansales/data/repositories/product_repository.dart';
import 'package:wawa_vansales/data/repositories/warehouse_repository.dart';
import 'package:wawa_vansales/data/services/api_service.dart';
import 'package:wawa_vansales/ui/screens/splash_screen.dart';
import 'package:wawa_vansales/utils/local_storage.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

// Function to determine if we should allow app exit
bool _isExitAllowed() {
  // Only allow exits on Android, Windows, Linux, or macOS
  return !kIsWeb && (Platform.isAndroid || Platform.isWindows || Platform.isLinux || Platform.isMacOS);
}

// Function to exit the app
Future<void> _exitApp() async {
  await SystemNavigator.pop();
  // For non-Android platforms, this won't exit the app, but that's okay since the WillPopScope
  // will provide a confirmation dialog on those platforms anyway
}

void main() async {
  // ตรวจสอบให้แน่ใจว่า Flutter initialization เสร็จสมบูรณ์
  WidgetsFlutterBinding.ensureInitialized();

  // โหลดไฟล์ .env
  await dotenv.load();

  // ตั้งค่า BLoC observer
  Bloc.observer = AppBlocObserver();

  // เรียกใช้ shared preferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // สร้าง secure storage
  const secureStorage = FlutterSecureStorage();

  // กำหนดทิศทางหน้าจอที่ยอมให้แสดง
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(MyApp(
    sharedPreferences: sharedPreferences,
    secureStorage: secureStorage,
  ));
}

class MyApp extends StatelessWidget {
  final SharedPreferences sharedPreferences;
  final FlutterSecureStorage secureStorage;

  const MyApp({
    super.key,
    required this.sharedPreferences,
    required this.secureStorage,
  });

  @override
  Widget build(BuildContext context) {
    // สร้าง dependencies
    final localStorage = LocalStorage(
      prefs: sharedPreferences,
      secureStorage: secureStorage,
    );

    final apiService = ApiService();

    final authRepository = AuthRepository(
      apiService: apiService,
      localStorage: localStorage,
    );

    final warehouseRepository = WarehouseRepository(
      apiService: apiService,
      localStorage: localStorage,
    );

    final customerRepository = CustomerRepository(
      apiService: apiService,
    );

    final productRepository = ProductRepository(
      apiService: apiService,
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(
            authRepository: authRepository,
          ),
        ),
        BlocProvider<WarehouseBloc>(
          create: (context) => WarehouseBloc(
            warehouseRepository: warehouseRepository,
          ),
        ),
        BlocProvider<CustomerBloc>(
          create: (context) => CustomerBloc(
            customerRepository: customerRepository,
          ),
        ),
        BlocProvider<ProductBloc>(
          create: (context) => ProductBloc(
            productRepository: productRepository,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'WAWA Van Sales',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.getTheme(),
        home: AppExitHandler(child: const SplashScreen()),
      ),
    );
  }
}

// Widget to handle app exits
class AppExitHandler extends StatelessWidget {
  final Widget child;

  const AppExitHandler({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isExitAllowed()) {
          // Show confirmation dialog
          final shouldExit = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('ออกจากแอปพลิเคชัน'),
                  content: const Text('คุณต้องการออกจากแอปพลิเคชันใช่หรือไม่?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('ยกเลิก'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('ใช่', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ) ??
              false;

          if (shouldExit) {
            await _exitApp();
            return true;
          }
          return false;
        }
        // For web and iOS, let the system handle the back button
        return true;
      },
      child: child,
    );
  }
}
