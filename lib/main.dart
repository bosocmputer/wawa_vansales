import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // เพิ่ม import นี้
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wawa_vansales/blocs/auth/auth_bloc.dart';
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

// Global flag สำหรับโหมดประสิทธิภาพต่ำ
bool isLowPerformanceMode = true; // เปิดใช้งานโหมดประสิทธิภาพต่ำเป็นค่าเริ่มต้น

void main() async {
  // ตรวจสอบให้แน่ใจว่า Flutter initialization เสร็จสมบูรณ์
  WidgetsFlutterBinding.ensureInitialized();

  // โหลดไฟล์ .env
  await dotenv.load();

  // ปรับแต่งการทำงานสำหรับอุปกรณ์สเปคต่ำ
  timeDilation = 0.8; // ทำให้ animation เร็วขึ้น 20%

  // ลดความซับซ้อนของการ render
  if (!kIsWeb && Platform.isAndroid) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  // กำหนดทิศทางหน้าจอที่ยอมให้แสดง
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // เรียกใช้ shared preferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // สร้าง secure storage
  const secureStorage = FlutterSecureStorage();

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
        theme: AppTheme.getLightTheme(isLowPerformanceMode),
        home: const SplashScreen(),
      ),
    );
  }
}
