import 'package:intl/intl.dart';

class Formatters {
  // จัดรูปแบบราคาเป็นตัวเลขมีทศนิยม 2 ตำแหน่ง คั่นด้วยจุลภาค (,)
  static String formatPrice(String price) {
    try {
      final double priceValue = double.parse(price);
      final formatter = NumberFormat('#,##0.00', 'th_TH');
      return formatter.format(priceValue);
    } catch (e) {
      return price;
    }
  }

  // จัดรูปแบบจำนวน (ไม่มีทศนิยม)
  static String formatQuantity(String quantity) {
    try {
      final double quantityValue = double.parse(quantity);
      final formatter = NumberFormat('#,##0', 'th_TH');
      return formatter.format(quantityValue);
    } catch (e) {
      return quantity;
    }
  }
}
