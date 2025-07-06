import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:wawa_vansales/blocs/pre_order_summary/pre_order_summary_event.dart';
import 'package:wawa_vansales/blocs/pre_order_summary/pre_order_summary_state.dart';
import 'package:wawa_vansales/data/repositories/pre_order_history_repository.dart';

class PreOrderSummaryBloc extends Bloc<PreOrderSummaryEvent, PreOrderSummaryState> {
  final PreOrderHistoryRepository _preOrderHistoryRepository;
  final Logger _logger = Logger();

  PreOrderSummaryBloc({required PreOrderHistoryRepository preOrderHistoryRepository})
      : _preOrderHistoryRepository = preOrderHistoryRepository,
        super(PreOrderSummaryInitial()) {
    on<FetchTodaysPreOrderSummary>(_onFetchTodaysPreOrderSummary);
    on<RefreshTodaysPreOrderSummary>(_onRefreshTodaysPreOrderSummary);
  }

  // ดึงข้อมูลยอดพรีออเดอร์วันนี้
  Future<void> _onFetchTodaysPreOrderSummary(
    FetchTodaysPreOrderSummary event,
    Emitter<PreOrderSummaryState> emit,
  ) async {
    // ไม่แสดง loading state ถ้ามีข้อมูลอยู่แล้ว ป้องกันหน้าจอกระพริบ
    final currentState = state;
    if (currentState is! PreOrderSummaryLoaded) {
      emit(PreOrderSummaryLoading());
    }

    try {
      final summary = await _preOrderHistoryRepository.getTodaysPreOrderSummary();
      final totalAmount = summary['totalAmount'] as double;
      final billCount = summary['billCount'] as int;

      _logger.i('Fetched today\'s pre-order summary: Total ฿$totalAmount, Bills: $billCount');
      emit(PreOrderSummaryLoaded(
        totalAmount: totalAmount,
        billCount: billCount,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      _logger.e('Error fetching today\'s pre-order summary: $e');
      emit(PreOrderSummaryError(e.toString()));
    }
  }

  // รีเฟรชข้อมูลยอดพรีออเดอร์วันนี้ (แสดง loading ทุกครั้ง)
  Future<void> _onRefreshTodaysPreOrderSummary(
    RefreshTodaysPreOrderSummary event,
    Emitter<PreOrderSummaryState> emit,
  ) async {
    emit(PreOrderSummaryLoading());

    try {
      final summary = await _preOrderHistoryRepository.getTodaysPreOrderSummary();
      final totalAmount = summary['totalAmount'] as double;
      final billCount = summary['billCount'] as int;

      _logger.i('Refreshed today\'s pre-order summary: Total ฿$totalAmount, Bills: $billCount');
      emit(PreOrderSummaryLoaded(
        totalAmount: totalAmount,
        billCount: billCount,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      _logger.e('Error refreshing today\'s pre-order summary: $e');
      emit(PreOrderSummaryError(e.toString()));
    }
  }
}
