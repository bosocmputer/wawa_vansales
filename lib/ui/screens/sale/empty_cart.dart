// empty_cart.dart
import 'package:flutter/material.dart';
import 'package:wawa_vansales/config/app_theme.dart';

class EmptyCart extends StatelessWidget {
  const EmptyCart({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // สัญลักษณ์ตะกร้าว่าง
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 40,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),

          // ข้อความแจ้งว่าไม่มีสินค้า
          const Text(
            'ไม่มีสินค้าในรายการ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),

          // คำแนะนำการใช้งาน
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'สแกนบาร์โค้ดหรือป้อนรหัสสินค้าเพื่อเพิ่มสินค้าลงในรายการ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ไอคอนคำแนะนำ
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHintIcon(
                Icons.qr_code_scanner,
                'สแกนบาร์โค้ด',
              ),
              const SizedBox(width: 24),
              _buildHintIcon(
                Icons.person_search,
                'เลือกลูกค้าก่อน',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHintIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 24,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
