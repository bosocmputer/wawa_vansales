// lib/ui/screens/return_product/return_customer_step.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wawa_vansales/blocs/return_product/return_product_bloc.dart';
import 'package:wawa_vansales/blocs/return_product/return_product_event.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/models/customer_model.dart';
import 'package:wawa_vansales/ui/screens/search_screen/customer_search_screen.dart';

class ReturnCustomerStep extends StatelessWidget {
  final CustomerModel? selectedCustomer;
  final VoidCallback onNextStep;

  const ReturnCustomerStep({
    super.key,
    required this.selectedCustomer,
    required this.onNextStep,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // หัวข้อและคำอธิบาย - ทำให้กระชับขึ้น
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.person, color: AppTheme.primaryColor, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'เลือกลูกค้า',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'ระบุลูกค้าที่ต้องการรับคืนสินค้า',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        // แสดงลูกค้าที่เลือกหรือปุ่มเลือกลูกค้า
        Expanded(
          child: selectedCustomer != null ? _buildSelectedCustomerCard(context, selectedCustomer!) : _buildSelectCustomerButton(context),
        ),

        // ปุ่มถัดไป
        if (selectedCustomer != null)
          SafeArea(
            child: Container(
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
              child: ElevatedButton.icon(
                onPressed: onNextStep,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('ถัดไป'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSelectedCustomerCard(BuildContext context, CustomerModel customer) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColorLight.withOpacity(0.3),
                  radius: 28,
                  child: const Icon(
                    Icons.person,
                    color: AppTheme.primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (customer.code != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.badge,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'รหัส: ${customer.code}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      if (customer.address != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                customer.address!,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            TextButton.icon(
              onPressed: () {
                context.read<ReturnProductBloc>().add(ClearReturnCart());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('เลือกใหม่'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectCustomerButton(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ไอคอนใหญ่
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_add,
                size: 48,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),

            // ปุ่มเลือกลูกค้า
            ElevatedButton.icon(
              onPressed: () => _selectCustomer(context),
              icon: const Icon(Icons.search),
              label: const Text('เลือกลูกค้า'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 12),
            Text(
              'กรุณาเลือกลูกค้าเพื่อเริ่มทำรายการรับคืนสินค้า',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
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
      context.read<ReturnProductBloc>().add(SelectCustomerForReturn(result));
    }
  }
}
