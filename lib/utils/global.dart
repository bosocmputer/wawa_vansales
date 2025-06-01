import 'dart:math';

import 'package:wawa_vansales/utils/local_storage.dart';

/// คลาส Global สำหรับเก็บค่าที่ใช้บ่อยทั่วทั้งแอพพลิเคชัน
class Global {
  // คอนสตรัคเตอร์แบบ private ป้องกันการสร้าง instance
  Global._();

  // ค่า static ที่เก็บไว้ใน memory
  static String? _empCode;
  static String? _whCode;
  static String? _shiftCode;

  // คีย์สำหรับ local storage
  static const String keyEmpCode = 'emp_code';
  static const String keyWhCode = 'wh_code';
  static const String keyShiftCode = 'shift_code';

  // Getters สำหรับค่าต่างๆ
  static String get empCode => _empCode ?? 'NA';
  static String get whCode => _whCode ?? 'NA';
  static String get shiftCode => _shiftCode ?? '';

  /// เริ่มต้นโหลดค่าจาก local storage
  static Future<void> initialize(LocalStorage localStorage) async {
    await Future.wait([
      _loadEmpCode(localStorage),
      _loadWhCode(localStorage),
      _loadShiftCode(localStorage),
    ]);
  }

  /// บันทึกรหัสพนักงาน
  static Future<void> setEmpCode(LocalStorage localStorage, String value) async {
    await localStorage.saveString(keyEmpCode, value);
    _empCode = value;
  }

  /// บันทึกรหัสคลัง
  static Future<void> setWhCode(LocalStorage localStorage, String value) async {
    await localStorage.saveString(keyWhCode, value);
    _whCode = value;
  }

  /// บันทึกรหัสกะ
  static Future<void> setShiftCode(LocalStorage localStorage, String value) async {
    await localStorage.saveString(keyShiftCode, value);
    _shiftCode = value;
  }

  /// โหลดรหัสพนักงานจาก local storage
  static Future<void> _loadEmpCode(LocalStorage localStorage) async {
    _empCode = await localStorage.getString(keyEmpCode);
  }

  /// โหลดรหัสคลังจาก local storage
  static Future<void> _loadWhCode(LocalStorage localStorage) async {
    _whCode = await localStorage.getString(keyWhCode);
  }

  /// โหลดรหัสกะจาก local storage
  static Future<void> _loadShiftCode(LocalStorage localStorage) async {
    _shiftCode = await localStorage.getString(keyShiftCode);
  }

  /// ล้างค่าทั้งหมด
  static Future<void> clearAll(LocalStorage localStorage) async {
    await Future.wait([
      localStorage.removeString(keyEmpCode),
      localStorage.removeString(keyWhCode),
      localStorage.removeString(keyShiftCode),
    ]);

    _empCode = null;
    _whCode = null;
    _shiftCode = null;
  }

  static String generateDocumentNumber(String warehouseCode) {
    // Use warehouse code, current date, time, and random number to create a unique document number
    final now = DateTime.now();

    // Use format: YY MM DD HH MM
    final dateStr = '${(now.year % 100).toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';

    // Generate random 3-digit number
    final random = (100 + Random().nextInt(900)).toString();

    String docNumber = 'MINV$warehouseCode$dateStr$timeStr$random';

    // Check and limit to maximum 25 characters
    if (docNumber.length > 25) {
      docNumber = docNumber.substring(0, 25);
    }

    return docNumber;
  }

  static String getPriceLevelText(String priceLevel) {
    switch (priceLevel) {
      case '0':
        return 'ราคากลาง';
      case '1':
        return 'ราคาที่ 1';
      case '2':
        return 'ราคาที่ 2';
      case '3':
        return 'ราคาที่ 3';
      case '4':
        return 'ราคาที่ 4';
      case '5':
        return 'ราคาที่ 5';
      case '6':
        return 'ราคาที่ 6';
      case '7':
        return 'ราคาที่ 7';
      case '8':
        return 'ราคาที่ 8';
      case '9':
        return 'ราคาที่ 9';
      default:
        return 'ไม่มีข้อมูล';
    }
  }
}
