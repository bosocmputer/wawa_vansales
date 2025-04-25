import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wawa_vansales/blocs/auth/auth_bloc.dart';
import 'package:wawa_vansales/blocs/auth/auth_event.dart';
import 'package:wawa_vansales/blocs/auth/auth_state.dart';
import 'package:wawa_vansales/blocs/warehouse/warehouse_bloc.dart';
import 'package:wawa_vansales/blocs/warehouse/warehouse_event.dart';
import 'package:wawa_vansales/blocs/warehouse/warehouse_state.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/ui/screens/home_screen.dart';
import 'package:wawa_vansales/ui/screens/warehouse/warehouse_selection_screen.dart';
import 'package:wawa_vansales/utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCodeController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    // เติมข้อมูลตัวอย่าง (สำหรับการพัฒนา)
    _userCodeController.text = 'test';
    _passwordController.text = '8888';
  }

  @override
  void dispose() {
    _userCodeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      // ทำการ login ผ่าน AuthBloc
      context.read<AuthBloc>().add(
            LoginRequested(
              userCode: _userCodeController.text.trim(),
              password: _passwordController.text.trim(),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthAuthenticated) {
                // เมื่อ login แล้ว ให้ตรวจสอบว่าได้เลือกคลังและโลเคชั่นหรือยัง
                context.read<WarehouseBloc>().add(CheckWarehouseSelection());
              } else if (state is AuthFailure) {
                // แสดง dialog ข้อความผิดพลาด
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('เข้าสู่ระบบไม่สำเร็จ'),
                      content: Text(state.message),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('ปิด'),
                        ),
                      ],
                    );
                  },
                );
              }
            },
          ),
          BlocListener<WarehouseBloc, WarehouseState>(
            listener: (context, state) {
              if (state is WarehouseSelectionComplete) {
                // เลือกคลังและโลเคชั่นแล้ว ไปที่หน้าหลัก
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              } else if (state is WarehouseSelectionRequired) {
                // ยังไม่ได้เลือกคลังและโลเคชั่น ไปที่หน้าเลือก
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const WarehouseSelectionScreen()),
                );
              }
            },
          ),
        ],
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo หรือภาพแบรนด์แบบเรียบง่าย
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          'W',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'WAWA Van Sales',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'เข้าสู่ระบบเพื่อใช้งาน',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // แบบฟอร์มเข้าสู่ระบบแบบเรียบง่าย
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // ช่องกรอกรหัสผู้ใช้
                          TextFormField(
                            controller: _userCodeController,
                            decoration: const InputDecoration(
                              labelText: 'รหัสผู้ใช้',
                              hintText: 'กรอกรหัสผู้ใช้ของคุณ',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: Validators.validateUserCode,
                          ),
                          const SizedBox(height: 16),

                          // ช่องกรอกรหัสผ่าน
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              labelText: 'รหัสผ่าน',
                              hintText: 'กรอกรหัสผ่านของคุณ',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                ),
                                onPressed: _togglePasswordVisibility,
                              ),
                            ),
                            validator: Validators.validatePassword,
                          ),
                          const SizedBox(height: 32),

                          // ปุ่มเข้าสู่ระบบ
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              return SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: state is AuthLoading ? null : _submitForm,
                                  child: state is AuthLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('เข้าสู่ระบบ'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ข้อความด้านล่าง
                    const Text(
                      'WAWA Shop Service © 2025',
                      style: TextStyle(
                        color: AppTheme.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
