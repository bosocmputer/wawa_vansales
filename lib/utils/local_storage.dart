import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wawa_vansales/data/models/user_model.dart';
import 'package:wawa_vansales/data/models/warehouse_model.dart';
import 'package:wawa_vansales/data/models/location_model.dart';

class LocalStorage {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userDataKey = 'user_data';
  static const String _warehouseKey = 'warehouse_data';
  static const String _locationKey = 'location_data';
  static const String _isWarehouseSelectedKey = 'is_warehouse_selected';

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  LocalStorage({
    required SharedPreferences prefs,
    required FlutterSecureStorage secureStorage,
  })  : _prefs = prefs,
        _secureStorage = secureStorage;

  // บันทึกสถานะการลงชื่อเข้าใช้
  Future<void> setLoggedIn(bool value) async {
    await _prefs.setBool(_isLoggedInKey, value);
  }

  // ตรวจสอบสถานะการลงชื่อเข้าใช้
  Future<bool> isLoggedIn() async {
    return _prefs.getBool(_isLoggedInKey) ?? false;
  }

  // บันทึกข้อมูลผู้ใช้ลงใน secure storage
  Future<void> saveUserData(UserModel user) async {
    await _secureStorage.write(
      key: _userDataKey,
      value: jsonEncode(user.toJson()),
    );
  }

  // ดึงข้อมูลผู้ใช้จาก secure storage
  Future<UserModel?> getUserData() async {
    final userData = await _secureStorage.read(key: _userDataKey);
    if (userData != null) {
      return UserModel.fromJson(jsonDecode(userData));
    }
    return null;
  }

  // ล้างข้อมูลผู้ใช้ออกจาก secure storage
  Future<void> clearUserData() async {
    await _secureStorage.delete(key: _userDataKey);
  }

  // บันทึกข้อมูลคลังที่เลือก
  Future<void> saveWarehouse(WarehouseModel warehouse) async {
    await _secureStorage.write(
      key: _warehouseKey,
      value: jsonEncode(warehouse.toJson()),
    );
  }

  // ดึงข้อมูลคลังที่เลือก
  Future<WarehouseModel?> getWarehouse() async {
    final warehouseData = await _secureStorage.read(key: _warehouseKey);
    if (warehouseData != null) {
      return WarehouseModel.fromJson(jsonDecode(warehouseData));
    }
    return null;
  }

  // ดึงเฉพาะรหัสคลังที่เลือก
  Future<String> getWarehouseCode() async {
    final warehouse = await getWarehouse();
    return warehouse?.code ?? 'NA';
  }

  // บันทึกข้อมูลโลเคชั่นที่เลือก
  Future<void> saveLocation(LocationModel location) async {
    await _secureStorage.write(
      key: _locationKey,
      value: jsonEncode(location.toJson()),
    );
  }

  // ดึงข้อมูลโลเคชั่นที่เลือก
  Future<LocationModel?> getLocation() async {
    final locationData = await _secureStorage.read(key: _locationKey);
    if (locationData != null) {
      return LocationModel.fromJson(jsonDecode(locationData));
    }
    return null;
  }

  // บันทึกสถานะการเลือกคลังและโลเคชั่น
  Future<void> setWarehouseSelected(bool value) async {
    await _prefs.setBool(_isWarehouseSelectedKey, value);
  }

  // ตรวจสอบสถานะการเลือกคลังและโลเคชั่น
  Future<bool> isWarehouseSelected() async {
    return _prefs.getBool(_isWarehouseSelectedKey) ?? false;
  }

  // ล้างข้อมูลคลังและโลเคชั่น
  Future<void> clearWarehouseAndLocation() async {
    await _secureStorage.delete(key: _warehouseKey);
    await _secureStorage.delete(key: _locationKey);
    await _prefs.setBool(_isWarehouseSelectedKey, false);
  }

  // ล้างข้อมูลทั้งหมด
  Future<void> clearAll() async {
    await _prefs.clear();
    await _secureStorage.deleteAll();
  }

  /// saveString
  Future<void> saveString(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  /// saveBool
  Future<void> saveBool(String key, bool value) async {
    await _secureStorage.write(key: key, value: value.toString());
  }

  /// Retrieve a string value from secure storage
  Future<String?> getString(String key) async {
    return await _secureStorage.read(key: key);
  }

  /// Retrieve a boolean value from secure storage
  Future<bool?> getBool(String key) async {
    final value = await _secureStorage.read(key: key);
    if (value == null) return null;
    return value.toLowerCase() == 'true';
  }

  /// Remove a specific key from secure storage
  Future<void> removeString(String key) async {
    await _secureStorage.delete(key: key);
  }
}
