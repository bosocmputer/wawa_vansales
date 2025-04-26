import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wawa_vansales/blocs/auth/auth_bloc.dart';
import 'package:wawa_vansales/blocs/auth/auth_state.dart';
import 'package:wawa_vansales/blocs/warehouse/warehouse_bloc.dart';
import 'package:wawa_vansales/blocs/warehouse/warehouse_state.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/models/customer_model.dart';
import 'package:wawa_vansales/data/models/sale_model.dart';

class SaleHeader extends StatelessWidget {
  final SaleModel? transaction;
  final CustomerModel? selectedCustomer;
  final VoidCallback onSelectCustomer;

  const SaleHeader({
    super.key,
    required this.transaction,
    required this.selectedCustomer,
    required this.onSelectCustomer,
  });

  @override
  Widget build(BuildContext context) {
    // Get current user from auth bloc
    final authState = context.watch<AuthBloc>().state;
    final user = (authState is AuthAuthenticated) ? authState.user : null;

    // Get warehouse from warehouse bloc
    final warehouseState = context.watch<WarehouseBloc>().state;
    final warehouse = (warehouseState is WarehouseSelectionComplete) ? warehouseState.warehouse : null;
    final locations = (warehouseState is WarehouseSelectionComplete) ? warehouseState.location : null;

    return Card(
      margin: const EdgeInsets.all(6.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Row 1: Document ID and Date
            Row(
              children: [
                _buildInfoField(
                  'เลขที่',
                  transaction?.docno ?? '-',
                  icon: Icons.receipt,
                ),
                _buildInfoField(
                  'วันที่',
                  transaction != null ? _formatDate(transaction!.docdate) : '-',
                  icon: Icons.calendar_today,
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Row 2: Customer selection (enhanced visibility)
            _buildCustomerSelection(context),
            const SizedBox(height: 4),

            // Row 3: Employee and Warehouse info
            Row(
              children: [
                _buildInfoField(
                  'คลัง/พื้นที่เก็บ',
                  '${warehouse != null ? '${warehouse.code} - ${warehouse.name}' : 'เลือกคลัง'} / ${locations != null ? '${locations.code} - ${locations.name}' : 'เลือกพื้นที่เก็บ'}',
                  icon: Icons.warehouse,
                  isError: warehouse == null,
                ),
                _buildInfoField(
                  'พนักงาน',
                  user?.userName ?? '-',
                  icon: Icons.person,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField(
    String label,
    String value, {
    required IconData icon,
    bool isError = false,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 14,
              color: isError ? AppTheme.errorColor : AppTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: isError ? AppTheme.errorColor : AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isError ? AppTheme.errorColor : AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSelection(BuildContext context) {
    // Enhanced customer selection with prominent visual cues
    return Material(
      color: selectedCustomer != null ? Colors.green.withOpacity(0.05) : Colors.orange.withOpacity(0.05),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onSelectCustomer,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: selectedCustomer != null ? Colors.green.shade300 : Colors.orange.shade300,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.person_search,
                color: selectedCustomer != null ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'ลูกค้า',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (selectedCustomer == null)
                          const Text(
                            ' (จำเป็น)',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange,
                            ),
                          ),
                      ],
                    ),
                    Text(
                      selectedCustomer != null ? '${selectedCustomer!.code} - ${selectedCustomer!.name}' : 'แตะเพื่อเลือกลูกค้า',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: selectedCustomer != null ? AppTheme.textPrimary : Colors.orange,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dateTime = DateTime.parse(dateStr);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
