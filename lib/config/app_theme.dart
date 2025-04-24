// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  // ธีมระบบ
  static ThemeData getTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: primaryColor, primary: primaryColor, secondary: accentColor, error: errorColor, background: backgroundColor),
      scaffoldBackgroundColor: backgroundColor,
      cardTheme: const CardTheme(color: cardColor, elevation: 2, surfaceTintColor: Colors.white),
      textTheme: GoogleFonts.promptTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.prompt(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary),
        displayMedium: GoogleFonts.prompt(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary),
        titleLarge: GoogleFonts.prompt(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: GoogleFonts.prompt(fontSize: 16, color: textPrimary),
        bodyMedium: GoogleFonts.prompt(fontSize: 14, color: textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColorLight.withOpacity(0.3))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColorLight.withOpacity(0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryColor, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: errorColor)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))),
      appBarTheme: const AppBarTheme(backgroundColor: primaryColor, foregroundColor: Colors.white, centerTitle: true, elevation: 0),
    );
  }
}
