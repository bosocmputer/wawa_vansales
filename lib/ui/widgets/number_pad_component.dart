// lib/ui/widgets/number_pad_component.dart
import 'package:flutter/material.dart';

class NumberPadComponent extends StatelessWidget {
  final Function(String) onNumberPressed;
  final VoidCallback onClearPressed;

  const NumberPadComponent({
    super.key,
    required this.onNumberPressed,
    required this.onClearPressed,
  });

  @override
  Widget build(BuildContext context) {
    // คำนวณขนาดปุ่มตามหน้าจอ
    final screenWidth = MediaQuery.of(context).size.width;
    // ปรับขนาดปุ่มให้เล็กลงเพื่อให้มีช่องว่างมากขึ้น
    final buttonSize = (screenWidth - 64) / 4; // ลดขนาดลงและคำนวณใหม่
    final buttonHeight = buttonSize * 0.8; // ปรับความสูง

    // เพิ่มค่า spacing สำหรับกำหนดระยะห่างระหว่างปุ่ม
    const double horizontalSpacing = 8.0; // ระยะห่างแนวนอน
    const double verticalSpacing = 8.0; // ระยะห่างแนวตั้ง

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8), // เพิ่ม padding
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // แถวที่ 1-2 (แถวบนและกลาง) - ปรับให้แถวกลางอยู่ติดกับแถวบน
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // คอลัมน์ซ้าย (1, 4, 7)
              Column(
                children: [
                  _buildNumberButton('1', buttonSize, buttonHeight),
                  SizedBox(height: verticalSpacing),
                  _buildNumberButton('4', buttonSize, buttonHeight),
                  SizedBox(height: verticalSpacing),
                  _buildNumberButton('7', buttonSize, buttonHeight),
                ],
              ),
              SizedBox(width: horizontalSpacing),

              // คอลัมน์กลางซ้าย (2, 5, 8)
              Column(
                children: [
                  _buildNumberButton('2', buttonSize, buttonHeight),
                  SizedBox(height: verticalSpacing),
                  _buildNumberButton('5', buttonSize, buttonHeight),
                  SizedBox(height: verticalSpacing),
                  _buildNumberButton('8', buttonSize, buttonHeight),
                ],
              ),
              SizedBox(width: horizontalSpacing),

              // คอลัมน์กลางขวา (3, 6, 9)
              Column(
                children: [
                  _buildNumberButton('3', buttonSize, buttonHeight),
                  SizedBox(height: verticalSpacing),
                  _buildNumberButton('6', buttonSize, buttonHeight),
                  SizedBox(height: verticalSpacing),
                  _buildNumberButton('9', buttonSize, buttonHeight),
                ],
              ),
              SizedBox(width: horizontalSpacing),

              // คอลัมน์ขวาสุด (C, 0)
              Column(
                children: [
                  // ปุ่ม C ขนาดใหญ่ (สูงเท่ากับ 2 ปุ่ม + ระยะห่าง)
                  _buildLargeActionButton('C', buttonSize, (buttonHeight * 2) + verticalSpacing, Colors.red.shade100, Colors.red.shade800, onClearPressed),
                  SizedBox(height: verticalSpacing),
                  _buildNumberButton('0', buttonSize, buttonHeight),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ปุ่มตัวเลข
  Widget _buildNumberButton(String number, double width, double height) {
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: Colors.white,
        elevation: 2, // เพิ่ม elevation
        borderRadius: BorderRadius.circular(10), // เพิ่มความโค้งมนให้มากขึ้น
        child: InkWell(
          onTap: () => onNumberPressed(number),
          borderRadius: BorderRadius.circular(10),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ปุ่มพิเศษ C ขนาดใหญ่ (รวม 2 แถว)
  Widget _buildLargeActionButton(String label, double width, double height, Color bgColor, Color textColor, VoidCallback onPressed) {
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: bgColor,
        elevation: 2, // เพิ่ม elevation
        borderRadius: BorderRadius.circular(10), // เพิ่มความโค้งมนให้มากขึ้น
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 26, // เพิ่มขนาดตัวอักษรให้ใหญ่ขึ้น
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
