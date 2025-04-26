// lib/services/printer_service.dart
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'dart:typed_data';

class PrinterService {
  final BlueThermalPrinter printer = BlueThermalPrinter.instance;
  final String printerAddress = "InnerPrinter";
  final Logger _logger = Logger();

  // Singleton pattern
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  // ตรวจสอบการเชื่อมต่อ
  Future<bool> isConnected() async {
    try {
      return await printer.isConnected ?? false;
    } catch (e) {
      _logger.e('Error checking printer connection: $e');
      return false;
    }
  }

  // เชื่อมต่อกับเครื่องพิมพ์
  Future<bool> connectToPrinter() async {
    try {
      if (await isConnected()) return true;

      List<BluetoothDevice> devices = await printer.getBondedDevices();
      BluetoothDevice? deviceToConnect;

      for (var d in devices) {
        if (d.name == printerAddress) {
          deviceToConnect = d;
          break;
        }
      }

      if (deviceToConnect != null) {
        await printer.connect(deviceToConnect);
        _logger.i('Connected to printer: ${deviceToConnect.name}');
        return true;
      } else {
        _logger.e('Printer not found: $printerAddress');
        return false;
      }
    } catch (e) {
      _logger.e('Error connecting to printer: $e');
      return false;
    }
  }

  // ตัดการเชื่อมต่อ
  Future<void> disconnectPrinter() async {
    try {
      await printer.disconnect();
      _logger.i('Disconnected from printer');
    } catch (e) {
      _logger.e('Error disconnecting printer: $e');
    }
  }

  // พิมพ์รูปภาพ
  Future<bool> printImageBytes(Uint8List bytes) async {
    try {
      if (await connectToPrinter()) {
        await printer.printImageBytes(bytes);
        await printer.printNewLine();
        await printer.printNewLine();
        await printer.printNewLine();
        await printer.printNewLine(); // เว้นระยะสำหรับตัด
        return true;
      }
      return false;
    } catch (e) {
      _logger.e('Error printing image: $e');
      return false;
    }
  }
}
