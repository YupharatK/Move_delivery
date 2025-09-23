import 'package:flutter/material.dart';

class AppTheme {
  // สีหลักตามดีไซน์ของคุณ
  static final Color primaryColor = Color(0xFF439061);
  static final Color backgroundColor = Colors.white;

  static ThemeData get theme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: 'Kanit', // แนะนำให้ใช้ฟอนต์ที่รองรับภาษาไทย
      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black, // สีของไอคอนและตัวหนังสือบน AppBar
        elevation: 0, // ไม่มีเงา
      ),

      // ElevatedButton Theme (สำหรับปุ่มหลัก)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Kanit',
          ),
        ),
      ),
    );
  }
}
