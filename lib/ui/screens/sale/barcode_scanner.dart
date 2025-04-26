import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'dart:async';

class BarcodeScanner extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final String errorMessage;
  final Function(String) onSubmitted;
  // เพิ่มตัวเลือกการตั้งค่า delay
  final Duration scanCooldown;

  const BarcodeScanner({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.errorMessage,
    required this.onSubmitted,
    this.scanCooldown = const Duration(milliseconds: 1500), // กำหนดค่าเริ่มต้น 1.5 วินาที
  });

  @override
  State<BarcodeScanner> createState() => _BarcodeScannerState();
}

class _BarcodeScannerState extends State<BarcodeScanner> {
  bool _isScanEnabled = true;
  Timer? _cooldownTimer;
  Timer? _debounceTimer;
  bool _processingBarcode = false;

  @override
  void initState() {
    super.initState();

    // Request focus when widget is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.focusNode.canRequestFocus) {
        widget.focusNode.requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(BarcodeScanner oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if we were loading but now we're not
    if (oldWidget.isLoading && !widget.isLoading && _processingBarcode) {
      _processingBarcode = false;

      // Re-enable scanning and request focus after processing is complete
      _enableScanningAndRequestFocus();
    }
  }

  void _enableScanningAndRequestFocus() {
    // Cancel existing cooldown timer if any
    _cooldownTimer?.cancel();

    // Start a new cooldown timer
    _cooldownTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isScanEnabled = true;
          widget.controller.clear();
        });

        // Request focus with a slight delay to ensure UI has updated
        Timer(const Duration(milliseconds: 100), () {
          if (mounted && widget.focusNode.canRequestFocus) {
            widget.focusNode.requestFocus();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // ฟังก์ชันที่จะถูกเรียกเมื่อสแกนบาร์โค้ด
  void _processBarcode(String barcode) {
    if (!_isScanEnabled || barcode.isEmpty) return;

    // ป้องกันการสแกนซ้ำโดยปิดการสแกนชั่วคราว
    setState(() {
      _isScanEnabled = false;
      _processingBarcode = true;
    });

    // ส่งข้อมูลบาร์โค้ดไปประมวลผล
    widget.onSubmitted(barcode);

    // If not loading after submission, re-enable scanning
    // Otherwise, we'll re-enable in didUpdateWidget when loading completes
    if (!widget.isLoading) {
      _enableScanningAndRequestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Request focus when enabled and focus node doesn't have focus
    if (_isScanEnabled && !widget.focusNode.hasFocus && widget.focusNode.canRequestFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.focusNode.requestFocus();
      });
    }

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วนหัวของการสแกนพร้อมสถานะ
            Row(
              children: [
                Icon(Icons.qr_code_scanner, color: _isScanEnabled ? AppTheme.primaryColor : Colors.grey, size: 18),
                const SizedBox(width: 4),
                Text(
                  _isScanEnabled ? 'พร้อมสแกนบาร์โค้ด' : 'รอสักครู่...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _isScanEnabled ? AppTheme.primaryColor : Colors.grey,
                  ),
                ),
                const Spacer(),
                // แสดงสถานะการสแกน
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isScanEnabled ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // ช่องสแกนบาร์โค้ด - ไม่แสดงแป้นพิมพ์
            RawKeyboardListener(
              focusNode: FocusNode(),
              onKey: (RawKeyEvent event) {
                // จับการกดปุ่มจากฮาร์ดแวร์สแกนเนอร์ (ถ้ามี)
                if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
                  if (_isScanEnabled && widget.controller.text.isNotEmpty) {
                    _processBarcode(widget.controller.text);
                  }
                }
              },
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                // ปิดการแสดงแป้นพิมพ์
                showCursor: true,
                readOnly: false,
                keyboardType: TextInputType.none,
                enabled: _isScanEnabled, // ปิดการใช้งานช่องขณะอยู่ในช่วง cooldown

                // ปรับสีพื้นหลังตามสถานะการสแกน
                decoration: InputDecoration(
                  hintText: _isScanEnabled ? 'สแกนบาร์โค้ด...' : 'กำลังประมวลผล...',
                  filled: true,
                  fillColor: _isScanEnabled ? Colors.white : Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                  prefixIcon: Icon(
                    Icons.barcode_reader,
                    color: _isScanEnabled ? AppTheme.primaryColor : Colors.grey,
                    size: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(
                      color: _isScanEnabled ? Colors.grey.shade300 : Colors.grey.shade200,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(
                      color: _isScanEnabled ? Colors.grey.shade300 : Colors.grey.shade200,
                    ),
                  ),
                  suffixIcon: widget.controller.text.isNotEmpty && _isScanEnabled
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            widget.controller.clear();
                            widget.focusNode.requestFocus();
                          },
                        )
                      : null,
                ),
                // จับเหตุการณ์ Enter จากสแกนเนอร์
                onSubmitted: _isScanEnabled ? _processBarcode : null,
                // สำหรับเครื่องสแกนที่ไม่ส่ง Enter โดยอัตโนมัติ
                onChanged: (value) {
                  if (!_isScanEnabled) return;

                  // ยกเลิก timer เก่า (ถ้ามี)
                  _debounceTimer?.cancel();

                  // เริ่ม timer ใหม่
                  _debounceTimer = Timer(const Duration(milliseconds: 300), () {
                    if (value.isNotEmpty && _isScanEnabled) {
                      _processBarcode(value);
                    }
                  });
                },
              ),
            ),

            // ข้อความแนะนำการใช้งานและแสดงสถานะ
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _isScanEnabled ? 'วางเครื่องสแกนเพื่ออ่านบาร์โค้ด หรือป้อนรหัสแล้วกด Enter' : 'รอ ${widget.scanCooldown.inMilliseconds ~/ 1000} วินาทีก่อนสแกนอีกครั้ง',
                      style: TextStyle(
                        fontSize: 10,
                        color: _isScanEnabled ? AppTheme.textSecondary : Colors.orange,
                        fontStyle: _isScanEnabled ? FontStyle.normal : FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // แสดงข้อความผิดพลาด (ถ้ามี)
            if (widget.errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.errorMessage,
                        style: const TextStyle(
                          color: AppTheme.errorColor,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // แสดง loading indicator (ถ้ากำลังโหลด)
            if (widget.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),

            // แสดงข้อมูลเกี่ยวกับ Cooldown ถ้าไม่พร้อมสแกน
            if (!_isScanEnabled)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.orange.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'กำลังประมวลผล โปรดรอสักครู่...',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
