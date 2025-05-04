// lib/blocs/return_product_history/return_product_history_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:wawa_vansales/blocs/return_product_history/return_product_history_event.dart';
import 'package:wawa_vansales/blocs/return_product_history/return_product_history_state.dart';
import 'package:wawa_vansales/data/repositories/return_product_history_repository.dart';

class ReturnProductHistoryBloc extends Bloc<ReturnProductHistoryEvent, ReturnProductHistoryState> {
  final ReturnProductHistoryRepository _repository;
  final Logger _logger = Logger();

  ReturnProductHistoryBloc({
    required ReturnProductHistoryRepository repository,
  })  : _repository = repository,
        super(ReturnProductHistoryInitial()) {
    // เชื่อมต่อ events กับ handlers
    on<FetchReturnProductHistory>(_onFetchReturnProductHistory);
    on<FetchReturnProductHistoryDetail>(_onFetchReturnProductHistoryDetail);
    on<ClearReturnProductHistoryDetail>(_onClearReturnProductHistoryDetail);
  }

  // Handler สำหรับดึงรายการประวัติการรับคืนสินค้า
  Future<void> _onFetchReturnProductHistory(
    FetchReturnProductHistory event,
    Emitter<ReturnProductHistoryState> emit,
  ) async {
    try {
      emit(ReturnProductHistoryLoading());

      final history = await _repository.getReturnProductHistory(
        search: event.search,
        fromDate: event.fromDate,
        toDate: event.toDate,
      );

      emit(ReturnProductHistoryLoaded(history));
    } catch (e) {
      _logger.e('Error fetching return product history: $e');
      emit(ReturnProductHistoryError(e.toString()));
    }
  }

  // Handler สำหรับดึงรายละเอียดรายการรับคืนสินค้า
  Future<void> _onFetchReturnProductHistoryDetail(
    FetchReturnProductHistoryDetail event,
    Emitter<ReturnProductHistoryState> emit,
  ) async {
    try {
      emit(ReturnProductHistoryLoading());

      final items = await _repository.getReturnProductHistoryDetail(
        docNo: event.docNo,
      );

      emit(ReturnProductHistoryDetailLoaded(
        docNo: event.docNo,
        items: items,
      ));
    } catch (e) {
      _logger.e('Error fetching return product history detail: $e');
      emit(ReturnProductHistoryError(e.toString()));
    }
  }

  // Handler สำหรับล้างสถานะรายละเอียด
  void _onClearReturnProductHistoryDetail(
    ClearReturnProductHistoryDetail event,
    Emitter<ReturnProductHistoryState> emit,
  ) {
    // ถ้าอยู่ในสถานะ ReturnProductHistoryLoaded ให้คงไว้ มิเช่นนั้นรีเซ็ตเป็น initial
    if (state is ReturnProductHistoryLoaded) {
      emit(state);
    } else {
      emit(ReturnProductHistoryInitial());
    }
  }
}
