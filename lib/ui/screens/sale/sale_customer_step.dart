// lib/ui/screens/sale/sale_customer_step.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wawa_vansales/blocs/cart/cart_bloc.dart';
import 'package:wawa_vansales/blocs/cart/cart_event.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/models/customer_model.dart';
import 'package:wawa_vansales/ui/screens/search_screen/customer_search_screen.dart';
import 'package:wawa_vansales/ui/widgets/custom_button.dart';

class SaleCustomerStep extends StatelessWidget {
  final CustomerModel? selectedCustomer;
  final VoidCallback onNextStep;

  const SaleCustomerStep({
    super.key,
    required this.selectedCustomer,
    required this.onNextStep,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // หัวข้อ
                const Text(
                  'เลือกลูกค้า',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'กรุณาเลือกลูกค้าก่อนทำรายการขาย',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // แสดงลูกค้าที่เลือกแล้ว
                if (selectedCustomer != null) _buildSelectedCustomerCard(context) else _buildSelectCustomerButton(context),
              ],
            ),
          ),
        ),

        // ปุ่มถัดไป
        if (selectedCustomer != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: CustomButton(
              text: 'ถัดไป',
              onPressed: onNextStep,
              icon: const Icon(Icons.arrow_forward, color: Colors.white),
              buttonType: ButtonType.primary,
            ),
          ),
      ],
    );
  }

  Widget _buildSelectedCustomerCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedCustomer!.name!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'รหัส: ${selectedCustomer!.code}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  color: AppTheme.primaryColor,
                  onPressed: () => _selectCustomer(context),
                ),
              ],
            ),
            if (selectedCustomer!.address!.isNotEmpty) ...[
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedCustomer!.address!,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (selectedCustomer!.telephone!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.phone,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    selectedCustomer!.telephone!,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelectCustomerButton(BuildContext context) {
    return InkWell(
      onTap: () => _selectCustomer(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppTheme.primaryColor,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.person_add,
                size: 48,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 16),
              const Text(
                'เลือกลูกค้า',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'แตะเพื่อค้นหาและเลือกลูกค้า',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectCustomer(BuildContext context) async {
    final result = await Navigator.of(context).push<CustomerModel?>(
      MaterialPageRoute(
        builder: (_) => const CustomerSearchScreen(),
      ),
    );

    if (result != null && context.mounted) {
      context.read<CartBloc>().add(SelectCustomerForCart(result));
    }
  }
}
