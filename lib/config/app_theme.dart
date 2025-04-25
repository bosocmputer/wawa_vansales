// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class AppTheme {
  // สีหลักของแอป - โทนสีม่วง
  static const Color primaryColor = Color(0xFF6A1B9A);
  static const Color primaryColorLight = Color(0xFF9C4DCC);
  static const Color primaryColorDark = Color(0xFF38006B);

  // สีสำหรับองค์ประกอบต่างๆ
  static const Color accentColor = Color(0xFFFFC107);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color cardColor = Colors.white;
  static const Color errorColor = Color(0xFFD32F2F);

  // สีข้อความ
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFBDBDBD);

  // ธีมระบบแบบเรียบง่ายสำหรับอุปกรณ์สเปคต่ำ
  static ThemeData getLightTheme(bool isLowPerformanceMode) {
    final baseTheme = ThemeData.light();

    return ThemeData(
      useMaterial3: !isLowPerformanceMode, // ปิดใช้ Material3 เมื่อเป็นโหมดประสิทธิภาพต่ำ
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: MaterialColor(primaryColor.value, _getSwatch(primaryColor)),
        accentColor: accentColor,
        errorColor: errorColor,
        backgroundColor: backgroundColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardTheme: CardTheme(
        color: cardColor,
        elevation: isLowPerformanceMode ? 0 : 2, // ไม่มีเงาเมื่อเป็นโหมดประสิทธิภาพต่ำ
        shadowColor: isLowPerformanceMode ? Colors.transparent : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200, width: 1), // เพิ่มเส้นขอบแทนเงา
        ),
      ),
      textTheme: baseTheme.textTheme.copyWith(
        displayLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary),
        displayMedium: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary),
        titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: const TextStyle(fontSize: 16, color: textPrimary),
        bodyMedium: const TextStyle(fontSize: 14, color: textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), // ลดความโค้งเล็กน้อย
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15), // ลดขนาดลงเล็กน้อย
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: isLowPerformanceMode ? 0 : 2, // ไม่มีเงาเมื่อเป็นโหมดประสิทธิภาพต่ำ
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
    );
  }

  // Helper สำหรับสร้าง MaterialColor
  static Map<int, Color> _getSwatch(Color color) {
    return {
      50: color.withOpacity(0.1),
      100: color.withOpacity(0.2),
      200: color.withOpacity(0.3),
      300: color.withOpacity(0.4),
      400: color.withOpacity(0.5),
      500: color.withOpacity(0.6),
      600: color.withOpacity(0.7),
      700: color.withOpacity(0.8),
      800: color.withOpacity(0.9),
      900: color,
    };
  }
}
