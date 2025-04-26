// sale_summary.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/models/sale_item_model.dart';

class SaleSummary extends StatelessWidget {
  final List<SaleItemModel> items;

  const SaleSummary({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,##0.00', 'th_TH');

    // คำนวณยอดรวมและจำนวนชิ้น
    double totalAmount = 0.0;
    int totalItems = 0;

    for (final item in items) {
      final quantity = item.quantity ?? 0;
      final price = item.price ?? 0.0;
      totalAmount += int.parse(quantity.toString()) * int.parse(price.toString());
      totalItems += int.parse(quantity.toString());
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          // แสดงข้อมูลสรุป
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // จำนวนรายการสินค้า
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'จำนวนสินค้า',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    '$totalItems ชิ้น (${items.length} รายการ)',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              // ยอดรวม
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'ยอดรวม',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    '฿${numberFormat.format(totalAmount)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
