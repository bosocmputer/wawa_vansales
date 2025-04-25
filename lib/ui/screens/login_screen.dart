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
import 'package:wawa_vansales/ui/widgets/custom_button.dart';
import 'package:wawa_vansales/ui/widgets/custom_text_field.dart';
import 'package:wawa_vansales/utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _userCodeController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // สร้าง animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();

    // เติมข้อมูลตัวอย่าง (สำหรับการพัฒนา)
    _userCodeController.text = 'test';
    _passwordController.text = '8888';
  }

  @override
  void dispose() {
    _userCodeController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
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
                // แสดงข้อความผิดพลาด
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppTheme.errorColor,
                  ),
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
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Logo หรือภาพแบรนด์
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'W',
                              style: TextStyle(
                                fontSize: 60,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'WAWA Van Sales',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'เข้าสู่ระบบเพื่อใช้งาน',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // แบบฟอร์มเข้าสู่ระบบ
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // ช่องกรอกรหัสผู้ใช้
                              CustomTextField(
                                controller: _userCodeController,
                                label: 'รหัสผู้ใช้',
                                hint: 'กรอกรหัสผู้ใช้ของคุณ',
                                keyboardType: TextInputType.text,
                                prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primaryColor),
                                validator: Validators.validateUserCode,
                              ),
                              const SizedBox(height: 20),

                              // ช่องกรอกรหัสผ่าน
                              CustomTextField(
                                controller: _passwordController,
                                label: 'รหัสผ่าน',
                                hint: 'กรอกรหัสผ่านของคุณ',
                                obscureText: !_isPasswordVisible,
                                prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryColor),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                    color: AppTheme.primaryColor,
                                  ),
                                  onPressed: _togglePasswordVisibility,
                                ),
                                validator: Validators.validatePassword,
                              ),
                              const SizedBox(height: 20),

                              // ตัวเลือกจำข้อมูลผู้ใช้
                              // Row(
                              //   children: [
                              //     Checkbox(
                              //       value: _rememberMe,
                              //       onChanged: _toggleRememberMe,
                              //       activeColor: AppTheme.primaryColor,
                              //     ),
                              //     const Text(
                              //       'จำข้อมูลผู้ใช้',
                              //       style: TextStyle(
                              //         color: AppTheme.textSecondary,
                              //       ),
                              //     ),
                              //   ],
                              // ),
                              const SizedBox(height: 30),

                              // ปุ่มเข้าสู่ระบบ
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  return CustomButton(
                                    text: 'เข้าสู่ระบบ',
                                    isLoading: state is AuthLoading,
                                    onPressed: _submitForm,
                                    icon: const Icon(Icons.login, color: Colors.white, size: 20),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        // ข้อความด้านล่าง
                        const Text(
                          'WAWA Shop Service © 2025',
                          style: TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
