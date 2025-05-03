import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wawa_vansales/blocs/cart/cart_bloc.dart';
import 'package:wawa_vansales/blocs/cart/cart_event.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/ui/screens/home_screen.dart';

class ConfirmExitDialog {
  /// แสดง dialog ยืนยันการออกจากหน้าสั่งซื้อ
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการออก'),
        content: const Text('คุณต้องการออกจากหน้านี้หรือไม่? รายการสินค้าในตะกร้าจะถูกล้าง'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<CartBloc>().add(ClearCart());

              // กลับไปหน้า home screen
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('ออก', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
