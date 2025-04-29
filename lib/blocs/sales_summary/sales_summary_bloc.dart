import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:wawa_vansales/blocs/sales_summary/sales_summary_event.dart';
import 'package:wawa_vansales/blocs/sales_summary/sales_summary_state.dart';
import 'package:wawa_vansales/data/repositories/sale_history_repository.dart';

class SalesSummaryBloc extends Bloc<SalesSummaryEvent, SalesSummaryState> {
  final SaleHistoryRepository _saleHistoryRepository;
  final Logger _logger = Logger();

  SalesSummaryBloc({required SaleHistoryRepository saleHistoryRepository})
      : _saleHistoryRepository = saleHistoryRepository,
        super(SalesSummaryInitial()) {
    on<FetchTodaysSalesSummary>(_onFetchTodaysSalesSummary);
    on<RefreshTodaysSalesSummary>(_onRefreshTodaysSalesSummary);
  }

  // ดึงข้อมูลยอดขายวันนี้
  Future<void> _onFetchTodaysSalesSummary(
    FetchTodaysSalesSummary event,
    Emitter<SalesSummaryState> emit,
  ) async {
    // ไม่แสดง loading state ถ้ามีข้อมูลอยู่แล้ว ป้องกันหน้าจอกระพริบ
    final currentState = state;
    if (currentState is! SalesSummaryLoaded) {
      emit(SalesSummaryLoading());
    }

    try {
      final summary = await _saleHistoryRepository.getTodaySalesSummary();
      final totalAmount = summary['totalAmount'] as double;
      final billCount = summary['billCount'] as int;

      _logger.i('Fetched today\'s sales summary: Total ฿$totalAmount, Bills: $billCount');
      emit(SalesSummaryLoaded(
        totalAmount: totalAmount,
        billCount: billCount,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      _logger.e('Error fetching today\'s sales summary: $e');
      emit(SalesSummaryError(e.toString()));
    }
  }

  // รีเฟรชข้อมูลยอดขายวันนี้ (แสดง loading ทุกครั้ง)
  Future<void> _onRefreshTodaysSalesSummary(
    RefreshTodaysSalesSummary event,
    Emitter<SalesSummaryState> emit,
  ) async {
    emit(SalesSummaryLoading());

    try {
      final summary = await _saleHistoryRepository.getTodaySalesSummary();
      final totalAmount = summary['totalAmount'] as double;
      final billCount = summary['billCount'] as int;

      _logger.i('Refreshed today\'s sales summary: Total ฿$totalAmount, Bills: $billCount');
      emit(SalesSummaryLoaded(
        totalAmount: totalAmount,
        billCount: billCount,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      _logger.e('Error refreshing today\'s sales summary: $e');
      emit(SalesSummaryError(e.toString()));
    }
  }
}
