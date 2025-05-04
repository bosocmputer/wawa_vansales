import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:wawa_vansales/blocs/sale_history/sale_history_event.dart';
import 'package:wawa_vansales/blocs/sale_history/sale_history_state.dart';
import 'package:wawa_vansales/data/models/sale_history_model.dart';
import 'package:wawa_vansales/data/repositories/sale_history_repository.dart';

class SaleHistoryBloc extends Bloc<SaleHistoryEvent, SaleHistoryState> {
  final SaleHistoryRepository _saleHistoryRepository;
  final Logger _logger = Logger();

  // เก็บประวัติการขายและค่าการค้นหาล่าสุด
  List<SaleHistoryModel> _salesHistory = [];
  String _searchQuery = '';
  DateTime? _fromDate;
  DateTime? _toDate;

  SaleHistoryBloc({required SaleHistoryRepository saleHistoryRepository})
      : _saleHistoryRepository = saleHistoryRepository,
        super(SaleHistoryInitial()) {
    on<FetchSaleHistory>(_onFetchSaleHistory);
    on<FetchSaleHistoryDetail>(_onFetchSaleHistoryDetail);
    on<SetDateRange>(_onSetDateRange);
    on<SetHistorySearchQuery>(_onSetHistorySearchQuery);
    on<ResetSaleHistoryDetail>(_onResetSaleHistoryDetail);
    on<ResetSaleHistoryState>(_onResetSaleHistoryState); // เพิ่ม handler สำหรับ reset ทั้งหมด
  }

  // ดึงประวัติการขาย
  Future<void> _onFetchSaleHistory(
    FetchSaleHistory event,
    Emitter<SaleHistoryState> emit,
  ) async {
    _logger.i('Fetching sale history with search: ${event.search}, dates: ${event.fromDate} to ${event.toDate}');
    emit(SaleHistoryLoading());

    try {
      // อัปเดตค่าการค้นหาและวันที่
      _searchQuery = event.search;
      _fromDate = event.fromDate ?? _fromDate;
      _toDate = event.toDate ?? _toDate;

      final sales = await _saleHistoryRepository.getSaleHistory(
        search: event.search,
        fromDate: event.fromDate ?? _fromDate,
        toDate: event.toDate ?? _toDate,
        warehouseCode: event.warehouseCode,
      );

      _salesHistory = sales;

      _logger.i('Fetched ${sales.length} sale transactions');
      emit(SaleHistoryLoaded(
        sales: sales,
        searchQuery: _searchQuery,
        fromDate: _fromDate,
        toDate: _toDate,
      ));
    } catch (e) {
      _logger.e('Error fetching sale history: $e');
      emit(SaleHistoryError(e.toString()));
    }
  }

  // ดึงรายละเอียดการขาย
  Future<void> _onFetchSaleHistoryDetail(
    FetchSaleHistoryDetail event,
    Emitter<SaleHistoryState> emit,
  ) async {
    _logger.i('Fetching sale history detail for doc: ${event.docNo}');

    // เก็บ state ปัจจุบันไว้ก่อน
    final currentState = state;

    emit(SaleHistoryDetailLoading());

    try {
      final details = await _saleHistoryRepository.getSaleHistoryDetail(event.docNo);

      _logger.i('Fetched ${details.length} items for doc: ${event.docNo}');
      emit(SaleHistoryDetailLoaded(
        items: details,
        docNo: event.docNo,
      ));
    } catch (e) {
      _logger.e('Error fetching sale history detail: $e');
      emit(SaleHistoryDetailError(e.toString()));

      // กลับไปยังสถานะเดิม (SaleHistoryLoaded) หากเกิดข้อผิดพลาด
      if (currentState is SaleHistoryLoaded) {
        emit(currentState);
      }
    }
  }

  // กำหนดช่วงวันที่
  void _onSetDateRange(
    SetDateRange event,
    Emitter<SaleHistoryState> emit,
  ) {
    _logger.i('Setting date range: ${event.fromDate} to ${event.toDate}');

    _fromDate = event.fromDate;
    _toDate = event.toDate;

    // เรียกดึงข้อมูลตามวันที่ใหม่
    add(FetchSaleHistory(
      search: _searchQuery,
      fromDate: _fromDate,
      toDate: _toDate,
    ));
  }

  // กำหนดการค้นหา
  void _onSetHistorySearchQuery(
    SetHistorySearchQuery event,
    Emitter<SaleHistoryState> emit,
  ) {
    _logger.i('Setting search query: ${event.query}');

    _searchQuery = event.query;

    // เรียกดึงข้อมูลตามคำค้นหาใหม่
    add(FetchSaleHistory(
      search: _searchQuery,
      fromDate: _fromDate,
      toDate: _toDate,
    ));
  }

  // รีเซ็ตข้อมูลรายละเอียด
  void _onResetSaleHistoryDetail(
    ResetSaleHistoryDetail event,
    Emitter<SaleHistoryState> emit,
  ) {
    _logger.i('Resetting sale history detail');

    // กลับไปยังสถานะ SaleHistoryLoaded
    if (_salesHistory.isNotEmpty) {
      emit(SaleHistoryLoaded(
        sales: _salesHistory,
        searchQuery: _searchQuery,
        fromDate: _fromDate,
        toDate: _toDate,
      ));
    } else {
      emit(SaleHistoryInitial());
    }
  }

  // รีเซ็ตสถานะทั้งหมด
  void _onResetSaleHistoryState(
    ResetSaleHistoryState event,
    Emitter<SaleHistoryState> emit,
  ) {
    _logger.i('Resetting entire sale history state');
    _salesHistory = [];
    _searchQuery = '';
    _fromDate = null;
    _toDate = null;
    emit(SaleHistoryInitial());
  }
}
