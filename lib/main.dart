import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // เพิ่ม import นี้
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wawa_vansales/blocs/auth/auth_bloc.dart';
import 'package:wawa_vansales/blocs/cart/cart_bloc.dart';
import 'package:wawa_vansales/blocs/customer/customer_bloc.dart';
import 'package:wawa_vansales/blocs/pre_order_history/pre_order_history_bloc.dart';
import 'package:wawa_vansales/blocs/product/product_bloc.dart';
import 'package:wawa_vansales/blocs/product_detail/product_detail_bloc.dart';
import 'package:wawa_vansales/blocs/return_product/return_product_bloc.dart';
import 'package:wawa_vansales/blocs/sale_history/sale_history_bloc.dart';
import 'package:wawa_vansales/blocs/sales_summary/sales_summary_bloc.dart';
import 'package:wawa_vansales/blocs/warehouse/warehouse_bloc.dart';
import 'package:wawa_vansales/blocs/pre_order/pre_order_bloc.dart'; // เพิ่ม import นี้
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/repositories/auth_repository.dart';
import 'package:wawa_vansales/data/repositories/customer_repository.dart';
import 'package:wawa_vansales/data/repositories/pre_order_history_repository.dart';
import 'package:wawa_vansales/data/repositories/product_repository.dart';
import 'package:wawa_vansales/data/repositories/return_product_repository.dart';
import 'package:wawa_vansales/data/repositories/sale_history_repository.dart';
import 'package:wawa_vansales/data/repositories/sale_repository.dart';
import 'package:wawa_vansales/data/repositories/warehouse_repository.dart';
import 'package:wawa_vansales/data/repositories/pre_order_repository.dart'; // เพิ่ม import นี้
import 'package:wawa_vansales/data/services/api_service.dart';
import 'package:wawa_vansales/data/services/printer_status_provider.dart';
import 'package:wawa_vansales/data/services/receipt_printer_service.dart';
import 'package:wawa_vansales/ui/screens/splash_screen.dart';
import 'package:wawa_vansales/utils/global.dart';
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

  // สร้าง localStorage สำหรับการใช้งานข้อมูลท้องถิ่น
  final localStorage = LocalStorage(
    prefs: sharedPreferences,
    secureStorage: secureStorage,
  );

  // เตรียม printer service
  final printerService = ReceiptPrinterService();

  // ขอสิทธิ์การใช้งานบลูทูธและพยายามเชื่อมต่อเครื่องพิมพ์อัตโนมัติ
  await printerService.requestBluetoothPermissions();
  await printerService.autoConnect(); // ภายในนี้มีการเรียก checkConnection อยู่แล้ว

  await Global.initialize(localStorage);

  runApp(MyApp(
    localStorage: localStorage,
    printerService: printerService,
  ));
}

class MyApp extends StatelessWidget {
  final LocalStorage localStorage;
  final ReceiptPrinterService printerService;

  const MyApp({
    super.key,
    required this.localStorage,
    required this.printerService,
  });

  @override
  Widget build(BuildContext context) {
    // สร้าง dependencies
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

    final saleRepository = SaleRepository(
      apiService: apiService,
    );

    final saleHistoryRepository = SaleHistoryRepository(
      apiService: apiService,
      localStorage: localStorage,
    );

    final preOrderRepository = PreOrderRepository(
      apiService: apiService,
    );

    final preOrderHistoryRepository = PreOrderHistoryRepository(
      apiService: apiService,
    );

    final returnProductRepository = ReturnProductRepository(
      apiService: apiService,
    );

    return MultiBlocProvider(
      providers: [
        // เพิ่ม Provider สำหรับ LocalStorage
        Provider<LocalStorage>.value(value: localStorage),

        ChangeNotifierProvider(
          create: (context) => PrinterStatusProvider(printerService),
        ),
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(
            authRepository: authRepository,
            localStorage: localStorage, // เพิ่ม localStorage
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
        BlocProvider<ProductDetailBloc>(
          create: (context) => ProductDetailBloc(
            productRepository: productRepository,
          ),
        ),
        BlocProvider<CartBloc>(
          create: (context) => CartBloc(
            saleRepository: saleRepository,
            localStorage: localStorage,
          ),
        ),
        BlocProvider<SaleHistoryBloc>(
          create: (context) => SaleHistoryBloc(
            saleHistoryRepository: saleHistoryRepository,
          ),
        ),
        BlocProvider<SalesSummaryBloc>(
          create: (context) => SalesSummaryBloc(
            saleHistoryRepository: saleHistoryRepository,
          ),
        ),
        BlocProvider<PreOrderBloc>(
          create: (context) => PreOrderBloc(
            preOrderRepository: preOrderRepository,
            saleRepository: saleRepository,
            localStorage: localStorage,
          ),
        ),
        BlocProvider<PreOrderHistoryBloc>(
          create: (context) => PreOrderHistoryBloc(
            preOrderHistoryRepository: preOrderHistoryRepository,
          ),
        ),
        BlocProvider<ReturnProductBloc>(
          create: (context) => ReturnProductBloc(
            returnProductRepository: returnProductRepository,
            localStorage: localStorage,
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
