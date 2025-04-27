import 'package:flutter/material.dart';
import 'package:wawa_vansales/config/app_theme.dart';

class SaleStepperWidget extends StatelessWidget {
  final int currentStep;
  final bool isCustomerSelected;
  final bool hasItems;
  final bool isFullyPaid;
  final bool hasCompletedSummary;

  const SaleStepperWidget({
    super.key,
    required this.currentStep,
    required this.isCustomerSelected,
    required this.hasItems,
    required this.isFullyPaid,
    this.hasCompletedSummary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8), // ลด padding
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStep(
            context,
            index: 0,
            icon: Icons.person,
            label: 'ลูกค้า',
            isCompleted: isCustomerSelected,
          ),
          _buildConnector(),
          _buildStep(
            context,
            index: 1,
            icon: Icons.shopping_cart,
            label: 'สินค้า',
            isCompleted: hasItems,
          ),
          _buildConnector(),
          _buildStep(
            context,
            index: 2,
            icon: Icons.payment,
            label: 'จ่ายเงิน',
            isCompleted: isFullyPaid,
          ),
          _buildConnector(),
          _buildStep(
            context,
            index: 3,
            icon: Icons.receipt_long,
            label: 'สรุป',
            isCompleted: hasCompletedSummary,
          ),
        ],
      ),
    );
  }

  Widget _buildStep(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    required bool isCompleted,
  }) {
    final bool isActive = currentStep == index;
    final bool isPassed = currentStep > index;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (isActive || isPassed) ? AppTheme.primaryColor : Colors.grey[300],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? AppTheme.primaryColor : Colors.grey[500],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildConnector() {
    return Container(
      width: 20, // ย่อเส้น connector
      height: 1,
      color: Colors.grey[400],
    );
  }
}
