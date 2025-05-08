import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wawa_vansales/blocs/customer/customer_bloc.dart';
import 'package:wawa_vansales/blocs/customer/customer_state.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/models/customer_model.dart';
import 'package:wawa_vansales/utils/global.dart';

class CustomerDetailScreen extends StatelessWidget {
  const CustomerDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, state) {
        if (state is! CustomerSelected) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('รายละเอียดลูกค้า'),
            ),
            body: const Center(
              child: Text('ไม่พบข้อมูลลูกค้า'),
            ),
          );
        }

        final customer = state.customer;

        return Scaffold(
          appBar: AppBar(
            title: const Text('รายละเอียดลูกค้า'),
            actions: const [],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCustomerHeader(customer),
                const SizedBox(height: 8),
                _buildCustomerDetails(customer),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomerHeader(CustomerModel customer) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Avatar ของลูกค้า
            CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.primaryColor,
              child: Text(
                customer.name!.isNotEmpty ? customer.name![0].toUpperCase() : 'C',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // ข้อมูลลูกค้า
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // รหัสลูกค้า
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      customer.code!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // ชื่อลูกค้า
                  Text(
                    customer.name!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerDetails(CustomerModel customer) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ข้อมูลรายละเอียด',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // ที่อยู่
            _buildDetailItem(
              icon: Icons.location_on,
              label: 'ที่อยู่',
              value: customer.address?.isNotEmpty ?? false ? customer.address! : 'ไม่มีข้อมูล',
            ),
            const Divider(height: 24),
            // เบอร์โทรศัพท์
            _buildDetailItem(
              icon: Icons.phone,
              label: 'เบอร์โทรศัพท์',
              value: customer.telephone?.isNotEmpty ?? false ? customer.telephone! : 'ไม่มีข้อมูล',
            ),
            const Divider(height: 24),
            // เลขประจำตัวผู้เสียภาษี
            _buildDetailItem(
              icon: Icons.confirmation_number,
              label: 'เลขประจำตัวผู้เสียภาษี',
              value: customer.taxId!.isNotEmpty ? customer.taxId! : 'ไม่มีข้อมูล',
            ),
            const Divider(height: 24),
            // เว็บไซต์
            _buildDetailItem(
              icon: Icons.language,
              label: 'GPRS',
              value: customer.website?.isNotEmpty ?? false ? customer.website! : 'ไม่มีข้อมูล',
            ),
            const Divider(height: 24),
            // ระดับราคา
            _buildDetailItem(
              icon: Icons.price_change,
              label: 'ระดับราคา',
              value: Global.getPriceLevelText(customer.priceLevel ?? '0'),
            ),
            const Divider(height: 24),
            // สถานะ AR
            _buildDetailItem(
              icon: Icons.account_balance,
              label: 'ประเภทลูกค้า',
              value: customer.arstatus == '0' ? 'บุคคลธรรมดา' : 'นิติบุคคล (บริษัท)',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
