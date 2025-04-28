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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: Colors.white,
          child: Row(
            children: [
              _buildStep(
                index: 0,
                icon: Icons.person,
                label: 'ลูกค้า',
                isCompleted: isCustomerSelected,
              ),
              _buildConnector(0),
              _buildStep(
                index: 1,
                icon: Icons.shopping_cart,
                label: 'สินค้า',
                isCompleted: hasItems,
              ),
              _buildConnector(1),
              _buildStep(
                index: 2,
                icon: Icons.payment,
                label: 'ชำระเงิน',
                isCompleted: isFullyPaid,
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
        // Progress bar
        Container(
          height: 2,
          color: Colors.grey.shade200,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: constraints.maxWidth * (currentStep / 3),
                  color: AppTheme.primaryColor,
                ),
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
    final bool isActive = currentStep == index;
    final bool isPassed = currentStep > index;

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? AppTheme.primaryColor
                  : isPassed
                      ? Colors.green.shade400
                      : Colors.transparent,
              border: Border.all(
                color: (isActive || isPassed) ? Colors.transparent : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Icon(
              isPassed ? Icons.check : icon,
              color: (isActive || isPassed) ? Colors.white : Colors.grey.shade600,
              size: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive
                  ? AppTheme.primaryColor
                  : isPassed
                      ? Colors.green.shade600
                      : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnector(int index) {
    final bool isCompleted = currentStep > index;

    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: isCompleted ? Colors.green.shade400 : Colors.grey.shade200,
      ),
    );
  }
}
