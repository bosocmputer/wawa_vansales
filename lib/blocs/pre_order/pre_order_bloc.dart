import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:wawa_vansales/blocs/pre_order/pre_order_event.dart';
import 'package:wawa_vansales/blocs/pre_order/pre_order_state.dart';
import 'package:wawa_vansales/data/repositories/pre_order_repository.dart';
import 'package:wawa_vansales/data/repositories/sale_repository.dart';
import 'package:wawa_vansales/utils/local_storage.dart';

class PreOrderBloc extends Bloc<PreOrderEvent, PreOrderState> {
  final PreOrderRepository _preOrderRepository;
  final Logger _logger = Logger();

  PreOrderBloc({
    required PreOrderRepository preOrderRepository,
    required SaleRepository saleRepository,
    required LocalStorage localStorage,
  })  : _preOrderRepository = preOrderRepository,
        super(PreOrderInitial()) {
    on<FetchPreOrders>(_onFetchPreOrders);
    on<FetchPreOrderDetail>(_onFetchPreOrderDetail);
    on<ResetPreOrderState>(_onResetState);
    on<FetchPreOrderByDocNo>(_onFetchPreOrderByDocNo);
  }

  // ดึงรายการพรีออเดอร์ตามลูกค้า
  Future<void> _onFetchPreOrders(FetchPreOrders event, Emitter<PreOrderState> emit) async {
    try {
      emit(PreOrderLoading());
      final preOrders = await _preOrderRepository.getPreOrderList(event.customerCode);
      emit(PreOrdersLoaded(preOrders));
    } catch (e) {
      _logger.e('Error fetching pre-orders: $e');
      emit(PreOrderError('ไม่สามารถโหลดรายการพรีออเดอร์ได้: ${e.toString()}'));
    }
  }

  // ดึงรายละเอียดพรีออเดอร์
  Future<void> _onFetchPreOrderDetail(FetchPreOrderDetail event, Emitter<PreOrderState> emit) async {
    try {
      emit(PreOrderDetailLoading());
      final items = await _preOrderRepository.getPreOrderDetail(event.docNo);

      // คำนวณยอดรวม
      final totalAmount = items.fold<double>(
        0,
        (sum, item) => sum + item.totalAmount,
      );

      emit(PreOrderDetailLoaded(
        docNo: event.docNo,
        items: items,
        totalAmount: totalAmount,
      ));
    } catch (e) {
      _logger.e('Error fetching pre-order detail: $e');
      emit(PreOrderError('ไม่สามารถโหลดรายละเอียดพรีออเดอร์ได้: ${e.toString()}'));
    }
  }

  // รีเซ็ตสถานะ
  void _onResetState(ResetPreOrderState event, Emitter<PreOrderState> emit) {
    emit(PreOrderInitial());
  }

  // ค้นหาพรีออเดอร์ตามเลขที่เอกสาร
  Future<void> _onFetchPreOrderByDocNo(FetchPreOrderByDocNo event, Emitter<PreOrderState> emit) async {
    try {
      emit(PreOrderLoading());

      final preOrder = await _preOrderRepository.getDocPreSale(
        event.customerCode,
        event.docNo,
      );

      emit(PreOrderSearchResult(
        preOrder: preOrder,
        searchQuery: event.docNo,
      ));
    } catch (e) {
      _logger.e('Error searching pre-order by doc no: $e');
      emit(PreOrderError('ไม่สามารถค้นหาพรีออเดอร์ได้: ${e.toString()}'));
    }
  }
}
