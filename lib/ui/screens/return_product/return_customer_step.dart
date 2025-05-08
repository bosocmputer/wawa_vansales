// lib/ui/screens/return_product/return_customer_step.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wawa_vansales/blocs/return_product/return_product_bloc.dart';
import 'package:wawa_vansales/blocs/return_product/return_product_event.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/models/customer_model.dart';
import 'package:wawa_vansales/ui/screens/search_screen/customer_search_screen.dart';
import 'package:wawa_vansales/utils/global.dart';

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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.person, color: AppTheme.primaryColor, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'เลือกลูกค้า',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                'ระบุลูกค้าที่ต้องการรับคืนสินค้า',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // แสดงลูกค้าที่เลือกหรือปุ่มเลือกลูกค้า
        Expanded(
          child: selectedCustomer != null ? _buildCustomerDetails(context, selectedCustomer!) : _buildSelectCustomerButton(context),
        ),

        // ปุ่มถัดไป
        if (selectedCustomer != null)
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                icon: const Icon(Icons.arrow_forward, size: 20),
                label: const Text('ถัดไป'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
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

  // ส่วนแสดงข้อมูลลูกค้าแบบปรับปรุงใหม่ ให้สามารถเลื่อนได้
  Widget _buildCustomerDetails(BuildContext context, CustomerModel customer) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          // ส่วนข้อมูลหลักของลูกค้า
          _buildCustomerHeader(context, customer),

          const SizedBox(height: 12),

          // ส่วนรายละเอียดลูกค้า
          _buildCustomerInfoCard(customer),

          const SizedBox(height: 12),

          // ส่วนปุ่มดำเนินการ
          _buildActionButton(context),

          // เพิ่มพื้นที่ด้านล่างเพื่อให้เลื่อนได้เต็มที่
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ส่วนแสดงข้อมูลหลักของลูกค้า
  Widget _buildCustomerHeader(BuildContext context, CustomerModel customer) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryColorLight.withOpacity(0.3),
              radius: 28,
              child: Text(
                customer.name!.isNotEmpty ? customer.name![0].toUpperCase() : 'C',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
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
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'รหัส: ${customer.code}',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
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

  // ส่วนรายละเอียดลูกค้า
  Widget _buildCustomerInfoCard(CustomerModel customer) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ข้อมูลลูกค้า',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const Divider(height: 20),

            // แสดงรายละเอียดลูกค้าแบบกระชับ
            _buildDetailItem(
              icon: Icons.location_on,
              label: 'ที่อยู่',
              value: customer.address?.isNotEmpty ?? false ? customer.address! : 'ไม่มีข้อมูล',
            ),
            const SizedBox(height: 12),

            _buildDetailItem(
              icon: Icons.phone,
              label: 'เบอร์โทรศัพท์',
              value: customer.telephone?.isNotEmpty ?? false ? customer.telephone! : 'ไม่มีข้อมูล',
            ),
            const SizedBox(height: 12),

            _buildDetailItem(
              icon: Icons.confirmation_number,
              label: 'เลขประจำตัวผู้เสียภาษี',
              value: customer.taxId?.isNotEmpty ?? false ? customer.taxId! : 'ไม่มีข้อมูล',
            ),
            const SizedBox(height: 12),

            _buildDetailItem(
              icon: Icons.language,
              label: 'เว็บไซต์',
              value: customer.website?.isNotEmpty ?? false ? customer.website! : 'ไม่มีข้อมูล',
            ),
            const SizedBox(height: 12),

            _buildDetailItem(
              icon: Icons.price_change,
              label: 'ระดับราคา',
              value: Global.getPriceLevelText(customer.priceLevel ?? '0'),
            ),
            const SizedBox(height: 12),

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

  // ส่วนปุ่มดำเนินการ
  Widget _buildActionButton(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.refresh,
              color: Colors.blue,
              size: 24,
            ),
          ),
          title: const Text(
            'เลือกลูกค้าใหม่',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          subtitle: const Text(
            'เริ่มต้นกระบวนการใหม่โดยเลือกลูกค้าอื่น',
            style: TextStyle(
              fontSize: 12,
            ),
          ),
          onTap: () {
            context.read<ReturnProductBloc>().add(ClearReturnCart());
            _selectCustomer(context);
          },
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
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
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_add,
                size: 40,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),

            // ปุ่มเลือกลูกค้า
            ElevatedButton.icon(
              onPressed: () => _selectCustomer(context),
              icon: const Icon(Icons.search, size: 18),
              label: const Text('เลือกลูกค้า'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(180, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 10),
            Text(
              'กรุณาเลือกลูกค้าเพื่อเริ่มทำรายการรับคืนสินค้า',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
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
