import 'package:flutter/material.dart';
import 'package:wawa_vansales/config/app_theme.dart';

class SelectionStepper extends StatelessWidget {
  final int currentStep;
  final bool warehouseSelected;
  final bool locationSelected;

  const SelectionStepper({
    super.key,
    required this.currentStep,
    required this.warehouseSelected,
    required this.locationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        children: [
          _buildStep(
            context,
            0,
            'คลังสินค้า',
            Icons.warehouse,
            warehouseSelected,
            currentStep == 0,
          ),
          _buildConnector(0),
          _buildStep(
            context,
            1,
            'พื้นที่เก็บ',
            Icons.location_on,
            locationSelected,
            currentStep == 1,
          ),
          _buildConnector(1),
          _buildStep(
            context,
            2,
            'ยืนยัน',
            Icons.check_circle,
            warehouseSelected && locationSelected,
            currentStep == 2,
          ),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context, int step, String label, IconData icon, bool isCompleted, bool isActive) {
    const Color activeColor = AppTheme.primaryColor;
    const Color completedColor = Colors.green;
    const Color inactiveColor = Colors.grey;

    Color iconColor;
    Color bgColor;
    Color textColor;

    if (isActive) {
      iconColor = Colors.white;
      bgColor = activeColor;
      textColor = activeColor;
    } else if (isCompleted) {
      iconColor = Colors.white;
      bgColor = completedColor;
      textColor = completedColor;
    } else {
      iconColor = inactiveColor;
      bgColor = Colors.grey.shade200;
      textColor = inactiveColor;
    }

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circle with number/icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              boxShadow: isActive || isCompleted
                  ? [
                      BoxShadow(
                        color: bgColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Step label
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConnector(int stepBefore) {
    final bool isActive = currentStep > stepBefore || (stepBefore == 0 && warehouseSelected) || (stepBefore == 1 && locationSelected);

    return Expanded(
      flex: 1,
      child: Container(
        height: 2,
        color: isActive ? AppTheme.primaryColor : Colors.grey.shade300,
      ),
    );
  }
}
