// lib/ui/screens/sale/sale_stepper_widget.dart
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
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStep(
            context,
            index: 0,
            icon: Icons.person,
            label: 'เลือกลูกค้า',
            isCompleted: isCustomerSelected,
          ),
          _buildConnector(isCustomerSelected),
          _buildStep(
            context,
            index: 1,
            icon: Icons.shopping_cart,
            label: 'เลือกสินค้า',
            isCompleted: hasItems,
          ),
          _buildConnector(hasItems),
          _buildStep(
            context,
            index: 2,
            icon: Icons.payment,
            label: 'ชำระเงิน',
            isCompleted: isFullyPaid,
          ),
          _buildConnector(isFullyPaid),
          _buildStep(
            context,
            index: 3,
            icon: Icons.receipt_long,
            label: 'สรุปรายการ',
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppTheme.primaryColor : Colors.grey[300],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? AppTheme.primaryColor : Colors.grey[600],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(bool isCompleted) {
    return Container(
      width: 40,
      height: 2,
      color: Colors.grey[300],
    );
  }
}
