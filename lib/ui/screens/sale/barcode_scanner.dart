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
  final Function()? onCancel;
  final Duration scanCooldown;

  const BarcodeScanner({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.errorMessage,
    required this.onSubmitted,
    this.onCancel,
    this.scanCooldown = const Duration(milliseconds: 1500),
  });

  @override
  State<BarcodeScanner> createState() => _BarcodeScannerState();
}

class _BarcodeScannerState extends State<BarcodeScanner> {
  bool _isScanEnabled = true;
  Timer? _cooldownTimer;
  Timer? _debounceTimer;
  bool _processingBarcode = false;
  String _lastScannedBarcode = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.focusNode.canRequestFocus) {
        widget.focusNode.requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(BarcodeScanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading && !widget.isLoading && _processingBarcode) {
      _processingBarcode = false;
      _enableScanningAndRequestFocus();
    }
  }

  void _enableScanningAndRequestFocus() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isScanEnabled = true;
          widget.controller.clear();
          _lastScannedBarcode = '';
        });
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

  void _processBarcode(String barcode) {
    if (!_isScanEnabled || barcode.isEmpty) return;

    // ป้องกันการสแกนบาร์โค้ดเดิมซ้ำ
    if (barcode == _lastScannedBarcode && widget.isLoading) {
      return;
    }

    setState(() {
      _isScanEnabled = false;
      _processingBarcode = true;
      _lastScannedBarcode = barcode;
    });

    widget.onSubmitted(barcode);

    if (!widget.isLoading) {
      _enableScanningAndRequestFocus();
    }
  }

  void _cancelSearch() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    }

    setState(() {
      _isScanEnabled = true;
      _processingBarcode = false;
      _lastScannedBarcode = '';
      widget.controller.clear();
    });

    widget.focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    if (_isScanEnabled && !widget.focusNode.hasFocus && widget.focusNode.canRequestFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.focusNode.requestFocus();
      });
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ช่องสแกนบาร์โค้ด - ไม่แสดงแป้นพิมพ์
          RawKeyboardListener(
            focusNode: FocusNode(),
            onKey: (RawKeyEvent event) {
              if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
                if (_isScanEnabled && widget.controller.text.isNotEmpty) {
                  _processBarcode(widget.controller.text);
                }
              } else if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
                if (widget.isLoading) {
                  _cancelSearch();
                }
              }
            },
            child: Row(
              children: [
                // ไอคอนสถานะ
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isScanEnabled ? Colors.green : Colors.grey,
                  ),
                ),

                // ช่องกรอกบาร์โค้ด
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    showCursor: true,
                    readOnly: widget.isLoading, // ป้องกันการแก้ไขขณะกำลังค้นหา
                    keyboardType: TextInputType.none,
                    enabled: true, // เปิดใช้งานเสมอเพื่อให้ยกเลิกได้
                    decoration: InputDecoration(
                      hintText: _isScanEnabled ? 'สแกนบาร์โค้ด...' : 'กำลังค้นหา ${widget.controller.text}...',
                      filled: true,
                      fillColor: _isScanEnabled ? Colors.white : Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      isDense: true,
                      prefixIcon: Icon(
                        Icons.qr_code_scanner,
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
                      // แสดงปุ่มยกเลิกเมื่อกำลังค้นหา
                      suffixIcon: widget.isLoading
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 16, color: Colors.red),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: _cancelSearch,
                              tooltip: 'ยกเลิกการค้นหา',
                            )
                          : widget.controller.text.isNotEmpty && _isScanEnabled
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    widget.controller.clear();
                                    widget.focusNode.requestFocus();
                                  },
                                )
                              : null,
                    ),
                    onSubmitted: _isScanEnabled ? _processBarcode : null,
                    onChanged: (value) {
                      if (!_isScanEnabled || widget.isLoading) return;
                      _debounceTimer?.cancel();
                      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
                        if (value.isNotEmpty && _isScanEnabled) {
                          _processBarcode(value);
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // แสดง LinearProgressIndicator เมื่อกำลังโหลด
          if (widget.isLoading)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey.shade200,
                color: AppTheme.primaryColor,
                minHeight: 2,
              ),
            ),

          // แสดงข้อความผิดพลาด (ถ้ามี)
          if (widget.errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 12),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.errorMessage,
                      style: const TextStyle(
                        color: AppTheme.errorColor,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
