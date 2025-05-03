// lib/ui/screens/return_product/return_product_stepper_widget.dart
import 'package:flutter/material.dart';
import 'package:wawa_vansales/config/app_theme.dart';

class ReturnProductStepperWidget extends StatelessWidget {
  final int currentStep;
  final bool isCustomerSelected;
  final bool isDocumentSelected;
  final bool hasItems;

  const ReturnProductStepperWidget({
    super.key,
    required this.currentStep,
    required this.isCustomerSelected,
    required this.isDocumentSelected,
    required this.hasItems,
  });

  @override
  Widget build(BuildContext context) {
    // คำนวณว่าขั้นตอนสรุปเสร็จสมบูรณ์หรือยัง (ถ้าอยู่ที่ขั้นตอนสุดท้ายและเงื่อนไขก่อนหน้าครบ)
    final bool hasCompletedSummary = currentStep == 3 && hasItems;

    return Column(
      children: [
        // Step indicators
        Container(
          height: 80, // เพิ่มความสูงเพื่อให้แน่ใจว่าไม่มี overflow
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          width: MediaQuery.of(context).size.width, // ใช้ความกว้างเต็มจอ
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // กระจายขั้นตอนให้เต็มความกว้าง
              children: [
                // ขั้นตอนที่ 1: เลือกลูกค้า
                _buildStep(
                  index: 0,
                  icon: Icons.person,
                  label: 'ลูกค้า',
                  isCompleted: isCustomerSelected,
                ),
                _buildConnector(0),
                _buildStep(
                  index: 1,
                  icon: Icons.receipt_long,
                  label: 'เอกสารขาย',
                  isCompleted: isDocumentSelected,
                ),
                _buildConnector(1),
                _buildStep(
                  index: 2,
                  icon: Icons.shopping_cart,
                  label: 'สินค้ารับคืน',
                  isCompleted: hasItems,
                ),
                _buildConnector(2),
                _buildStep(
                  index: 3,
                  icon: Icons.check_circle,
                  label: 'สรุป',
                  isCompleted: hasCompletedSummary,
                ),
              ],
            ),
          ),
        ),
        // Progress bar
        Container(
          height: 2,
          color: Colors.grey.shade200,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double maxWidth = constraints.maxWidth;
              final double progressWidth = maxWidth * _calculateProgress();

              return Row(
                children: [
                  Container(
                    width: progressWidth,
                    color: AppTheme.primaryColor,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStep({
    required int index,
    required IconData icon,
    required String label,
    required bool isCompleted,
  }) {
    final bool isCurrentStep = currentStep == index;
    final bool isPastStep = currentStep > index;

    // กำหนดสี
    Color circleColor;
    Color iconColor;
    Color textColor;

    if (isCurrentStep) {
      // ขั้นตอนปัจจุบัน
      circleColor = AppTheme.primaryColor;
      iconColor = Colors.white;
      textColor = AppTheme.primaryColor;
    } else if (isPastStep && isCompleted) {
      // ขั้นตอนที่ผ่านมาและเสร็จสมบูรณ์แล้ว
      circleColor = Colors.green;
      iconColor = Colors.white;
      textColor = Colors.green;
    } else if (isPastStep) {
      // ขั้นตอนที่ผ่านมาแต่ยังไม่เสร็จสมบูรณ์
      circleColor = Colors.orange;
      iconColor = Colors.white;
      textColor = Colors.orange;
    } else {
      // ขั้นตอนที่ยังไม่ถึง
      circleColor = Colors.grey.shade300;
      iconColor = Colors.grey;
      textColor = Colors.grey;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circle with icon
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textColor,
            fontWeight: isCurrentStep ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(int stepIndex) {
    final bool isPastConnector = currentStep > stepIndex;

    return Container(
      width: 30,
      height: 2,
      color: isPastConnector ? Colors.green : Colors.grey.shade300,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  double _calculateProgress() {
    // ตอนนี้มี 4 ขั้นตอน (0, 1, 2, 3)
    switch (currentStep) {
      case 0:
        return 0.125; // เริ่มต้น - แสดง 1/8 ของแถบ
      case 1:
        if (isCustomerSelected) {
          return 0.375; // เลือกลูกค้าแล้ว - แสดง 3/8 ของแถบ
        }
        return 0.125;
      case 2:
        if (isDocumentSelected) {
          return 0.625; // เลือกเอกสารขายแล้ว - แสดง 5/8 ของแถบ
        }
        return 0.375;
      case 3:
        if (hasItems) {
          return 1.0; // เสร็จสมบูรณ์ - แสดงแถบเต็ม
        }
        return 0.625;
      default:
        return 0;
    }
  }
}
