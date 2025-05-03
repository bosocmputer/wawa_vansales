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

  // Generate a document number for sales transactions
  static String generateDocumentNumber(String warehouseCode) {
    // Use warehouse code, current date, and random number to create a unique document number
    final now = DateTime.now();

    // ใช้รูปแบบปี 2 หลัก เดือน 2 หลัก วัน 2 หลัก
    final dateStr = '${(now.year % 100).toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    // สร้างเลขสุ่ม 3 หลัก
    final random = (100 + Random().nextInt(900)).toString();

    return 'MINV$warehouseCode$dateStr-$random';
  }

  /// ฟังก์ชันสำหรับการสร้างเลขที่เอกสาร pre-order MCNyyyymmddhhii-random4
  static String generatePreOrderDocumentNumber(String warehouseCode) {
    // ใช้ warehouse code, วันที่ปัจจุบัน, และเลขสุ่มเพื่อสร้างเลขที่เอกสารที่ไม่ซ้ำกัน
    final now = DateTime.now();

    // ใช้รูปแบบปี 4 หลัก เดือน 2 หลัก วัน 2 หลัก ชั่วโมง 2 หลัก นาที 2 หลัก
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    // สร้างเลขสุ่ม 4 หลัก
    final random = (1000 + Random().nextInt(9000)).toString();
    // สร้างเลขที่เอกสาร
    return 'MCN$warehouseCode$dateStr-$random';
  }

  // สร้างเลขที่เอกสารรับคืน
  static Future<String> generateReturnDocumentNumber(String warehouse) async {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final random = (1000 + Random().nextInt(9000)).toString();

    return 'MCN$warehouse$dateStr-$random';
  }
}
