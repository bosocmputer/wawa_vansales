import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wawa_vansales/data/services/receipt_printer_service.dart';

class PrinterStatusProvider with ChangeNotifier {
  final ReceiptPrinterService _printerService;
  bool _isConnected = false;
  bool _isConnecting = false;
  String _printerName = '';
  Timer? _statusCheckTimer;

  PrinterStatusProvider(this._printerService) {
    // เช็คสถานะเริ่มต้น
    _updateStatus();

    // ตั้งเวลาเช็คสถานะทุก 30 วินาที
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateStatus();
    });
  }

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String get printerName => _printerName;

  Future<void> _updateStatus() async {
    _isConnecting = _printerService.isConnecting;
    final connected = await _printerService.checkConnection();

    if (connected != _isConnected || _printerService.connectedDevice?.name != _printerName) {
      _isConnected = connected;
      _printerName = _printerService.connectedDevice?.name ?? '';
      notifyListeners();
    }
  }

  Future<bool> connectPrinter() async {
    _isConnecting = true;
    notifyListeners();

    final result = await _printerService.connectPrinter();
    await _updateStatus();

    return result;
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }
}
