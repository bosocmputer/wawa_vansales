class Validators {
  // ตรวจสอบว่า userCode ไม่เป็นค่าว่าง
  static String? validateUserCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณาระบุรหัสผู้ใช้';
    }
    return null;
  }

  // ตรวจสอบรหัสผ่านว่าไม่เป็นค่าว่าง
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณาระบุรหัสผ่าน';
    }
    return null;
  }

  // ตรวจสอบความยาวของรหัสผ่านขั้นต่ำ
  static String? validatePasswordLength(String? value, {int minLength = 4}) {
    if (value == null || value.isEmpty) {
      return 'กรุณาระบุรหัสผ่าน';
    } else if (value.length < minLength) {
      return 'รหัสผ่านต้องมีความยาวอย่างน้อย $minLength ตัวอักษร';
    }
    return null;
  }

  // ตรวจสอบว่าเป็นอีเมลที่ถูกต้องหรือไม่
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณาระบุอีเมล';
    }

    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value)) {
      return 'กรุณาระบุอีเมลที่ถูกต้อง';
    }

    return null;
  }

  // ตรวจสอบว่าเป็นเบอร์โทรศัพท์ที่ถูกต้องหรือไม่
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณาระบุเบอร์โทรศัพท์';
    }

    final phoneRegExp = RegExp(r'^[0-9]{9,10}$');
    if (!phoneRegExp.hasMatch(value)) {
      return 'กรุณาระบุเบอร์โทรศัพท์ที่ถูกต้อง (9-10 หลัก)';
    }

    return null;
  }
}
