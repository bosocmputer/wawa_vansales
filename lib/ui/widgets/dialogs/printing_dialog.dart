// lib/ui/widgets/dialogs/printing_dialog.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:wawa_vansales/config/app_theme.dart';

/// Widget สำหรับแสดง dialog ขณะพิมพ์เอกสารในแอปพลิเคชัน
/// - โดยมีการปรับแต่ง UI ให้สวยงามขึ้น
/// - สามารถกำหนดข้อความต่างๆ ได้ เช่น หัวข้อ, เนื้อหา, เลขที่เอกสาร
/// - มีการแสดงภาพพิมพ์เพื่อเพิ่มความน่าสนใจ
class PrintingDialog extends StatefulWidget {
  /// หัวข้อของ dialog (เช่น "กำลังพิมพ์ใบเสร็จ", "กำลังพิมพ์ใบรับคืนสินค้า")
  final String title;

  /// เลขที่เอกสารที่กำลังพิมพ์
  final String documentNumber;

  /// ข้อความเพิ่มเติม (ถ้ามี)
  final String? additionalMessage;

  /// ตั้งค่าว่าสามารถปิด dialog โดยการกดพื้นที่นอก dialog ได้หรือไม่
  final bool barrierDismissible;

  const PrintingDialog({
    super.key,
    required this.title,
    required this.documentNumber,
    this.additionalMessage,
    this.barrierDismissible = false,
  });

  /// แสดง PrintingDialog
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String documentNumber,
    String? additionalMessage,
    bool barrierDismissible = false,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => PrintingDialog(
        title: title,
        documentNumber: documentNumber,
        additionalMessage: additionalMessage,
        barrierDismissible: barrierDismissible,
      ),
    );
  }

  @override
  State<PrintingDialog> createState() => _PrintingDialogState();
}

class _PrintingDialogState extends State<PrintingDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // สร้าง animation controller สำหรับทำ loop animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // สร้าง animation จาก 0.8 ถึง 1.0 สำหรับทำให้ไอคอนพิมพ์มีการเคลื่อนไหว
    _animation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // ป้องกันการกดปุ่ม back
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ส่วนหัวข้อ
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Animation ไอคอนปริ้นเตอร์
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _animation.value,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.print_rounded,
                      size: 48,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // ตัวหมุนแสดงสถานะ loading
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
            const SizedBox(height: 20),

            // เลขที่เอกสาร
            Text(
              'เลขที่: ${widget.documentNumber}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),

            // ข้อความเพิ่มเติม
            Text(
              widget.additionalMessage ?? 'โปรดรอสักครู่...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
