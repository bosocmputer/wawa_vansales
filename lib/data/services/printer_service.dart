// lib/services/printer_service.dart
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:logger/logger.dart';
import 'package:wawa_vansales/data/models/receipt_model.dart';
import 'package:intl/intl.dart';

class PrinterService {
  final BlueThermalPrinter printer = BlueThermalPrinter.instance;
  final String printerAddress = "InnerPrinter";
  final Logger _logger = Logger();

  // Track connection status
  bool _isConnecting = false;

  // Singleton pattern
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  // Reset connection status
  void resetConnectionStatus() {
    _isConnecting = false;
  }

  // ตรวจสอบการเชื่อมต่อ
  Future<bool> isConnected() async {
    try {
      bool connected = await printer.isConnected ?? false;
      return connected;
    } catch (e) {
      _logger.e('Error checking printer connection: $e');
      return false;
    }
  }

  // เชื่อมต่อกับเครื่องพิมพ์
  Future<bool> connectToPrinter() async {
    if (_isConnecting) {
      _logger.w('Already trying to connect');
      return false;
    }

    try {
      _isConnecting = true;

      if (await isConnected()) {
        _logger.i('Printer already connected');
        return true;
      }

      await disconnectPrinter();

      await Future.delayed(const Duration(milliseconds: 1000));

      List<BluetoothDevice> devices = await printer.getBondedDevices();
      BluetoothDevice? deviceToConnect;

      for (var d in devices) {
        if (d.name == printerAddress) {
          deviceToConnect = d;
          break;
        }
      }

      if (deviceToConnect != null) {
        _logger.i('Connecting to device: ${deviceToConnect.name}');

        await printer.connect(deviceToConnect);

        await Future.delayed(const Duration(milliseconds: 2000));

        bool connected = await isConnected();
        if (connected) {
          _logger.i('Connected to printer: ${deviceToConnect.name}');
          return true;
        } else {
          _logger.e('Connection failed to establish');
          return false;
        }
      } else {
        _logger.e('Printer not found: $printerAddress');
        return false;
      }
    } catch (e) {
      _logger.e('Error connecting to printer: $e');
      return false;
    } finally {
      _isConnecting = false;
    }
  }

  // ตัดการเชื่อมต่อ
  Future<void> disconnectPrinter() async {
    try {
      bool connected = await printer.isConnected ?? false;

      if (connected) {
        await printer.printNewLine();
        await printer.printNewLine();
        await Future.delayed(const Duration(milliseconds: 200));
        await printer.disconnect();
        await Future.delayed(const Duration(milliseconds: 1000));
      }

      _logger.i('Disconnected from printer');
    } catch (e) {
      _logger.e('Error disconnecting printer: $e');
    }
  }

  // พิมพ์ใบเสร็จแบบข้อความธรรมดาที่ format ด้วย ESC/POS
  Future<bool> printReceipt(ReceiptModel receipt) async {
    try {
      bool connected = await connectToPrinter();

      if (!connected) {
        _logger.e('Could not connect to printer');
        return false;
      }

      await Future.delayed(const Duration(milliseconds: 1000));

      // Initialize printer
      await printer.write('\x1B\x40'); // ESC @ - Reset printer
      await Future.delayed(const Duration(milliseconds: 200));

      // ชื่อร้าน - ตัวใหญ่
      await printer.write('\x1B\x45\x01'); // ESC E 1 - Bold ON
      await printer.write('\x1B\x61\x01'); // ESC a 1 - Center align
      await printer.write('WAWA Shop Service\n');
      await printer.write('\x1B\x45\x00'); // ESC E 0 - Bold OFF
      await Future.delayed(const Duration(milliseconds: 100));

      // ที่อยู่
      await printer.write('123 Sukhumvit Rd.\n');
      await printer.write('Tel: 02-123-4567\n');
      await printer.write('\n');

      // เส้นคั่น
      await printer.write('--------------------------------\n');

      // หัวเอกสาร
      await printer.write('\x1B\x45\x01'); // Bold ON
      await printer.write('Receipt\n');
      await printer.write('\x1B\x45\x00'); // Bold OFF
      await printer.write('\n');

      // รายละเอียด - ชิดซ้าย
      await printer.write('\x1B\x61\x00'); // ESC a 0 - Left align
      await printer.write('No: ${receipt.docNo}\n');
      await printer.write('Date: ${_formatDate(receipt.date!)}\n');
      await printer.write('Customer: ${receipt.customerName}\n');
      await printer.write('Code: ${receipt.customerCode}\n');
      await printer.write('\n');

      // เส้นคั่น
      await printer.write('--------------------------------\n');

      // หัวตารางสินค้า
      await printer.write('Item              Qty    Amount\n');
      await printer.write('--------------------------------\n');

      // รายการสินค้า
      for (var item in receipt.items!) {
        // ชื่อสินค้า
        String itemName = _truncateString(item.itemName ?? '', 16);
        String qty = item.quantity?.padLeft(3) ?? '0';

        final total = double.parse(item.price ?? '0') * double.parse(item.quantity ?? '0');
        String totalStr = total.toStringAsFixed(2).padLeft(8);

        await printer.write('$itemName${' ' * (18 - itemName.length)}$qty$totalStr\n');

        // ราคาต่อหน่วย
        String unitPrice = ' @${item.price}';
        await printer.write(unitPrice + '\n');

        await Future.delayed(const Duration(milliseconds: 50));
      }

      // เส้นคั่น
      await printer.write('--------------------------------\n');

      // ยอดรวม
      await printer.write('\x1B\x45\x01'); // Bold ON
      await printer.write('Total: ${receipt.totalAmount}\n');
      await printer.write('\x1B\x45\x00'); // Bold OFF
      await printer.write('\n');

      // ข้อความขอบคุณ
      await printer.write('\x1B\x61\x01'); // Center align
      await printer.write('Thank you\n');

      // ป้อนกระดาษ
      await printer.write('\n\n\n\n');

      // ตัดกระดาษ (ถ้ารองรับ)
      await printer.write('\x1D\x56\x00'); // GS V 0 - Partial cut

      await Future.delayed(const Duration(milliseconds: 1000));

      _logger.i('Receipt print completed');
      return true;
    } catch (e) {
      _logger.e('Error printing receipt: $e');
      return false;
    } finally {
      await Future.delayed(const Duration(milliseconds: 1000));
      await disconnectPrinter();
    }
  }

  // พิมพ์แบบข้อความธรรมดา (เก็บไว้เป็น backup)
  Future<bool> printSimpleReceipt(ReceiptModel receipt) async {
    try {
      bool connected = await connectToPrinter();

      if (!connected) {
        _logger.e('Could not connect to printer');
        return false;
      }

      await Future.delayed(const Duration(milliseconds: 1000));

      // Simple text printing
      await printer.write('WAWA Shop Service\n');
      await printer.write('123 Sukhumvit Rd.\n');
      await printer.write('Tel: 02-123-4567\n');
      await printer.write('------------------------\n');
      await printer.write('Receipt\n');
      await printer.write('No: ${receipt.docNo}\n');
      await printer.write('Date: ${_formatDate(receipt.date!)}\n');
      await printer.write('Customer: ${receipt.customerName}\n');
      await printer.write('------------------------\n');

      for (var item in receipt.items!) {
        await printer.write('${item.itemName}\n');
        final total = double.parse(item.price ?? '0') * double.parse(item.quantity ?? '0');
        await printer.write('${item.quantity} x ${item.price} = ${total}\n');
      }

      await printer.write('------------------------\n');
      await printer.write('Total: ${receipt.totalAmount}\n');
      await printer.write('Thank you\n');
      await printer.write('\n\n\n\n');

      _logger.i('Simple receipt print completed');
      return true;
    } catch (e) {
      _logger.e('Error printing simple receipt: $e');
      return false;
    } finally {
      await Future.delayed(const Duration(milliseconds: 1000));
      await disconnectPrinter();
    }
  }

  // Helper functions
  String _formatDate(String dateStr) {
    try {
      final dateTime = DateTime.parse(dateStr);
      final formatter = DateFormat('dd/MM/yyyy HH:mm', 'th_TH');
      return formatter.format(dateTime);
    } catch (e) {
      return dateStr;
    }
  }

  String _truncateString(String str, int maxLength) {
    if (str.length <= maxLength) return str;
    return str.substring(0, maxLength);
  }
}
