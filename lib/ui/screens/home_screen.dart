// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wawa_vansales/blocs/auth/auth_bloc.dart';
import 'package:wawa_vansales/blocs/auth/auth_event.dart';
import 'package:wawa_vansales/blocs/auth/auth_state.dart';
import 'package:wawa_vansales/blocs/warehouse/warehouse_bloc.dart';
import 'package:wawa_vansales/blocs/warehouse/warehouse_event.dart';
import 'package:wawa_vansales/blocs/warehouse/warehouse_state.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/models/location_model.dart';
import 'package:wawa_vansales/data/models/warehouse_model.dart';
import 'package:wawa_vansales/ui/screens/customer_form_screen.dart';
import 'package:wawa_vansales/ui/screens/customer_list_screen.dart';
import 'package:wawa_vansales/ui/screens/login_screen.dart';
import 'package:wawa_vansales/ui/screens/printtest.dart';
import 'package:wawa_vansales/ui/screens/sale/sale_screen.dart';
import 'package:wawa_vansales/ui/screens/warehouse/warehouse_selection_screen.dart';
import 'package:wawa_vansales/ui/widgets/custom_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  WarehouseModel? _selectedWarehouse;
  LocationModel? _selectedLocation;
  bool _isInitialized = false; // Add flag to track initialization

  @override
  void initState() {
    super.initState();
    // ตรวจสอบข้อมูลคลังและพื้นที่เก็บที่เลือกเมื่อเปิดหน้า
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isInitialized) {
        _isInitialized = true;
        final warehouseState = context.read<WarehouseBloc>().state;
        // Only check if not already loaded
        if (warehouseState is! WarehouseSelectionComplete) {
          context.read<WarehouseBloc>().add(CheckWarehouseSelection());
        } else {
          // If already loaded, just update the local state
          setState(() {
            _selectedWarehouse = (warehouseState).warehouse;
            _selectedLocation = warehouseState.location;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthUnauthenticated) {
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
            }
          },
        ),
        BlocListener<WarehouseBloc, WarehouseState>(
          listenWhen: (previous, current) {
            // Only trigger listener when the state actually changes
            if (previous is WarehouseSelectionComplete && current is WarehouseSelectionComplete) {
              return previous.warehouse != current.warehouse || previous.location != current.location;
            }
            return true;
          },
          listener: (context, state) {
            if (state is WarehouseSelectionComplete) {
              setState(() {
                _selectedWarehouse = state.warehouse;
                _selectedLocation = state.location;
              });
            } else if (state is WarehouseSelectionRequired) {
              // ไม่พบข้อมูลคลังและพื้นที่เก็บ ให้ไปยังหน้าเลือก
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const WarehouseSelectionScreen()),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('WAWA Van Sales'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                _showLogoutDialog(context);
              },
            ),
          ],
        ),
        body: _buildHomeContent(context),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreeting(context),
            const SizedBox(height: 24),
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting(BuildContext context) {
    final authBloc = context.read<AuthBloc>();
    final user = (authBloc.state is AuthAuthenticated) ? (authBloc.state as AuthAuthenticated).user : null;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar ผู้ใช้
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.primaryColor,
              child: Text((user?.userName ?? 'U').substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(width: 12),

            // ข้อมูลผู้ใช้และคลัง
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ชื่อผู้ใช้
                  Text('สวัสดี, ${user?.userName ?? 'User'}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

                  // ข้อมูลคลัง
                  if (_selectedWarehouse != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          const Icon(Icons.warehouse, color: AppTheme.primaryColor, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _selectedWarehouse!.name,
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ข้อมูลโลเคชัน
                  if (_selectedLocation != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: AppTheme.primaryColor, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _selectedLocation!.name,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryColorDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // ปุ่มเปลี่ยนคลัง
            IconButton(
              icon: const Icon(Icons.swap_horiz, size: 20),
              tooltip: 'เปลี่ยนคลังและพื้นที่เก็บ',
              visualDensity: VisualDensity.compact,
              color: AppTheme.primaryColor,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => WarehouseSelectionScreen(
                            initialWarehouse: _selectedWarehouse,
                            initialLocation: _selectedLocation,
                          )),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'เมนูด่วน',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            /// ทดสอบพิมพ์
            _buildQuickActionItem(
              Icons.print,
              'ทดสอบพิมพ์',
              Colors.orange,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PrinterPage()),
                );
              },
            ),
            _buildQuickActionItem(
              Icons.add_shopping_cart,
              'ขายสินค้า',
              Colors.orange,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SaleScreen()),
                );
              },
            ),
            // _buildQuickActionItem(Icons.assignment, 'ประวัติออร์เดอร์', Colors.blue),
            _buildQuickActionItem(
              Icons.person_add,
              'เพิ่มลูกค้า',
              Colors.purple,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CustomerFormScreen()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionItem(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: AppTheme.textSecondary,
      showUnselectedLabels: true,
      onTap: (index) {
        switch (index) {
          case 0: // หน้าหลัก
            break;
          case 1: // ขายสินค้า
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SaleScreen()),
            );

            break;
          case 2: // ลูกค้า
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CustomerListScreen()),
            );
            break;
          // case 3: // รายงาน
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     const SnackBar(
          //       content: Text('ฟังก์ชันนี้ยังไม่พร้อมใช้งาน'),
          //     ),
          //   );
          //   break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'หน้าหลัก'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'ขายสินค้า'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'ลูกค้า'),
        // BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'รายงาน'),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ออกจากระบบ'),
        content: const Text('คุณต้องการออกจากระบบใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
          CustomButton(
            text: 'ใช่',
            buttonType: ButtonType.primary,
            width: 120,
            isFullWidth: false,
            customColor: AppTheme.errorColor,
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(LogoutRequested());
            },
          ),
        ],
      ),
    );
  }
}
