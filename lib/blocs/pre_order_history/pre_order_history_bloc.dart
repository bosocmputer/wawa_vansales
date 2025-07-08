// /lib/blocs/pre_order_history/pre_order_history_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:wawa_vansales/blocs/pre_order_history/pre_order_history_event.dart';
import 'package:wawa_vansales/blocs/pre_order_history/pre_order_history_state.dart';
import 'package:wawa_vansales/data/repositories/pre_order_history_repository.dart';

class PreOrderHistoryBloc extends Bloc<PreOrderHistoryEvent, PreOrderHistoryState> {
  final PreOrderHistoryRepository _preOrderHistoryRepository;
  final Logger _logger = Logger();

  // เพิ่มตัวแปรสำหรับเก็บค่า search และ date range
  DateTime? _fromDate;
  DateTime? _toDate;
  String _searchQuery = '';
  String _warehouseCode = '';
  String _shelfCode = '';

  PreOrderHistoryBloc({required PreOrderHistoryRepository preOrderHistoryRepository})
      : _preOrderHistoryRepository = preOrderHistoryRepository,
        super(PreOrderHistoryInitial()) {
    on<FetchPreOrderHistoryList>(_onFetchPreOrderHistoryList);
    on<FetchPreOrderHistoryDetail>(_onFetchPreOrderHistoryDetail);
    on<ResetPreOrderHistoryState>(_onResetState);
    on<ResetPreOrderHistoryDetail>(_onResetDetailState);
    on<SetPreOrderDateRange>(_onSetDateRange);
    on<SetPreOrderHistorySearchQuery>(_onSetSearchQuery);
  }

  // ดึงรายการประวัติการขาย (พรีออเดอร์)
  Future<void> _onFetchPreOrderHistoryList(
    FetchPreOrderHistoryList event,
    Emitter<PreOrderHistoryState> emit,
  ) async {
    try {
      // อัปเดตค่า date range และ search ที่รับเข้ามา
      _fromDate = event.fromDate ?? _fromDate;
      _toDate = event.toDate ?? _toDate;
      _searchQuery = event.search ?? _searchQuery;
      _warehouseCode = event.warehouseCode;
      _shelfCode = event.shelfCode;

      emit(PreOrderHistoryLoading());

      // เรียกใช้ repository ด้วยพารามิเตอร์ใหม่
      final preOrderHistoryList = await _preOrderHistoryRepository.getPreOrderHistoryList(
        fromDate: _fromDate,
        toDate: _toDate,
        search: _searchQuery.isNotEmpty ? _searchQuery : '',
        warehouseCode: _warehouseCode,
        shelfCode: _shelfCode,
      );

      emit(PreOrderHistoryListLoaded(preOrderHistoryList));
    } catch (e) {
      _logger.e('Error fetching pre-order history list: $e');
      emit(PreOrderHistoryError('ไม่สามารถโหลดรายการประวัติการขาย (พรีออเดอร์) ได้: ${e.toString()}'));
    }
  }

  // ดึงรายละเอียดประวัติการขาย (พรีออเดอร์)
  Future<void> _onFetchPreOrderHistoryDetail(
    FetchPreOrderHistoryDetail event,
    Emitter<PreOrderHistoryState> emit,
  ) async {
    try {
      emit(PreOrderHistoryDetailLoading());
      final items = await _preOrderHistoryRepository.getPreOrderHistoryDetail(event.docNo);

      // คำนวณยอดรวม โดยใช้ qty * price จาก model
      final totalAmount = items.fold<double>(
        0,
        (sum, item) => sum + (double.tryParse(item.qty) ?? 0) * (double.tryParse(item.price) ?? 0),
      );

      emit(PreOrderHistoryDetailLoaded(
        docNo: event.docNo,
        items: items,
        totalAmount: totalAmount,
      ));
    } catch (e) {
      _logger.e('Error fetching pre-order history detail: $e');
      emit(PreOrderHistoryError('ไม่สามารถโหลดรายละเอียดประวัติการขาย (พรีออเดอร์) ได้: ${e.toString()}'));
    }
  }

  // รีเซ็ตสถานะ
  void _onResetState(
    ResetPreOrderHistoryState event,
    Emitter<PreOrderHistoryState> emit,
  ) {
    emit(PreOrderHistoryInitial());
  }

  // รีเซ็ตสถานะรายละเอียดและโหลดข้อมูลรายการให้เป็นปัจจุบัน
  Future<void> _onResetDetailState(
    ResetPreOrderHistoryDetail event,
    Emitter<PreOrderHistoryState> emit,
  ) async {
    // รีเซ็ตสถานะรายละเอียดและโหลดข้อมูลรายการใหม่
    if (state is PreOrderHistoryDetailLoaded || state is PreOrderHistoryDetailLoading) {
      // หลังจากกดกลับจากหน้ารายละเอียด ให้โหลดข้อมูลรายการใหม่
      add(FetchPreOrderHistoryList(
        fromDate: _fromDate,
        toDate: _toDate,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        warehouseCode: _warehouseCode,
        shelfCode: _shelfCode,
      ));
    }
  }

  // จัดการเหตุการณ์ตั้งค่าช่วงวันที่
  Future<void> _onSetDateRange(
    SetPreOrderDateRange event,
    Emitter<PreOrderHistoryState> emit,
  ) async {
    _fromDate = event.fromDate;
    _toDate = event.toDate;

    // เรียกดึงข้อมูลใหม่ด้วยช่วงวันที่ที่อัปเดต
    add(FetchPreOrderHistoryList(
      fromDate: _fromDate,
      toDate: _toDate,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      warehouseCode: _warehouseCode,
      shelfCode: _shelfCode,
    ));
  }

  // จัดการเหตุการณ์ตั้งค่าคำค้นหา
  Future<void> _onSetSearchQuery(
    SetPreOrderHistorySearchQuery event,
    Emitter<PreOrderHistoryState> emit,
  ) async {
    _searchQuery = event.query;

    // เรียกดึงข้อมูลใหม่ด้วยคำค้นหาที่อัปเดต
    add(FetchPreOrderHistoryList(
      fromDate: _fromDate,
      toDate: _toDate,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      warehouseCode: _warehouseCode,
      shelfCode: _shelfCode,
    ));
  }
}
