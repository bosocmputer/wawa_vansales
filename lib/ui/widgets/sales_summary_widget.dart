import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wawa_vansales/blocs/sales_summary/sales_summary_bloc.dart';
import 'package:wawa_vansales/blocs/sales_summary/sales_summary_event.dart';
import 'package:wawa_vansales/blocs/sales_summary/sales_summary_state.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/ui/screens/sale_history/sale_history_list_screen.dart';
import 'package:wawa_vansales/ui/widgets/skeleton_loading.dart';

class SalesSummaryWidget extends StatefulWidget {
  const SalesSummaryWidget({super.key});

  @override
  State<SalesSummaryWidget> createState() => _SalesSummaryWidgetState();
}

class _SalesSummaryWidgetState extends State<SalesSummaryWidget> {
  final _currencyFormat = NumberFormat('#,##0.00', 'th_TH');
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

  @override
  void initState() {
    super.initState();

    // โหลดข้อมูลยอดขายตอนเปิดหน้าจอ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesSummaryBloc>().add(FetchTodaysSalesSummary());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: BlocBuilder<SalesSummaryBloc, SalesSummaryState>(
        builder: (context, state) {
          return InkWell(
            onTap: () {
              // เมื่อกดที่การ์ด ให้ไปที่หน้าประวัติการขาย
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SaleHistoryListScreen()),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ส่วนหัว
                  Row(
                    children: [
                      const Icon(
                        Icons.analytics,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'ยอดขายวันนี้',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const Spacer(),
                      // ปุ่มรีเฟรช
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        onPressed: () {
                          context.read<SalesSummaryBloc>().add(RefreshTodaysSalesSummary());
                        },
                        color: AppTheme.primaryColor,
                        tooltip: 'รีเฟรชข้อมูล',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // แสดงข้อมูลตาม state
                  if (state is SalesSummaryLoading && state is! SalesSummaryLoaded)
                    _buildLoadingState()
                  else if (state is SalesSummaryLoaded)
                    _buildLoadedState(state)
                  else if (state is SalesSummaryError)
                    _buildErrorState(state)
                  else
                    _buildInitialState(),

                  // เส้นคั่น
                  const Divider(height: 32),

                  // คำแนะนำกดเพื่อดูรายละเอียดเพิ่มเติม
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'กดเพื่อดูรายละเอียดเพิ่มเติม',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const ShimmerEffect(
      child: SalesSummarySkeleton(),
    );
  }

  Widget _buildLoadedState(SalesSummaryLoaded state) {
    final lastUpdated = _dateFormat.format(state.timestamp);

    return Column(
      children: [
        // แสดงยอดขายและจำนวนบิล
        Row(
          children: [
            // จำนวนเงิน
            Expanded(
              child: _buildSummaryItem(
                title: 'ยอดขายรวม',
                value: '฿${_currencyFormat.format(state.totalAmount)}',
                icon: Icons.attach_money,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            // จำนวนบิล
            Expanded(
              child: _buildSummaryItem(
                title: 'จำนวนบิล',
                value: state.billCount.toString(),
                icon: Icons.receipt,
                color: Colors.blue,
              ),
            ),
          ],
        ),

        // แสดงเวลาที่อัปเดตล่าสุด
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            'อัปเดตล่าสุด: $lastUpdated',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(SalesSummaryError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              'ไม่สามารถโหลดข้อมูลได้',
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            TextButton(
              onPressed: () {
                context.read<SalesSummaryBloc>().add(RefreshTodaysSalesSummary());
              },
              child: const Text('ลองใหม่'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return const ShimmerEffect(
      child: SalesSummarySkeleton(),
    );
  }

  Widget _buildSummaryItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
