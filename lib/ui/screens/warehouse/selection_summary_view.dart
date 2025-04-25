import 'package:flutter/material.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/models/location_model.dart';
import 'package:wawa_vansales/data/models/warehouse_model.dart';

class SelectionSummaryView extends StatelessWidget {
  final WarehouseModel warehouse;
  final LocationModel location;

  const SelectionSummaryView({
    super.key,
    required this.warehouse,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          const Text(
            'ตรวจสอบข้อมูลก่อนยืนยัน',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Warehouse selection summary card
          _buildSelectionCard(
            title: 'คลังสินค้า',
            code: warehouse.code,
            name: warehouse.name,
            icon: Icons.warehouse,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),

          // Location selection summary card
          _buildSelectionCard(
            title: 'พื้นที่เก็บ',
            code: location.code,
            name: location.name,
            icon: Icons.location_on,
            color: Colors.green,
          ),

          const SizedBox(height: 32),

          // Information text
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'หมายเหตุ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'การบันทึกข้อมูลคลังสินค้าและพื้นที่เก็บจะมีผลต่อการเรียกดูสินค้าและการทำรายการต่าง ๆ ในระบบ โปรดตรวจสอบความถูกต้องก่อนกดบันทึก',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required String code,
    required String name,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'รหัส: $code',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: color,
            size: 24,
          ),
        ],
      ),
    );
  }
}
