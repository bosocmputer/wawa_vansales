import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:wawa_vansales/blocs/pre_order/pre_order_event.dart';
import 'package:wawa_vansales/blocs/pre_order/pre_order_state.dart';
import 'package:wawa_vansales/data/repositories/pre_order_repository.dart';
import 'package:wawa_vansales/data/repositories/sale_repository.dart';
import 'package:wawa_vansales/utils/local_storage.dart';

class PreOrderBloc extends Bloc<PreOrderEvent, PreOrderState> {
  final PreOrderRepository _preOrderRepository;
  final SaleRepository _saleRepository;
  final LocalStorage _localStorage;
  final Logger _logger = Logger();

  PreOrderBloc({
    required PreOrderRepository preOrderRepository,
    required SaleRepository saleRepository,
    required LocalStorage localStorage,
  })  : _preOrderRepository = preOrderRepository,
        _saleRepository = saleRepository,
        _localStorage = localStorage,
        super(PreOrderInitial()) {
    on<FetchPreOrders>(_onFetchPreOrders);
    on<FetchPreOrderDetail>(_onFetchPreOrderDetail);
    on<ResetPreOrderState>(_onResetState);
    on<SubmitPreOrderPayment>(_onSubmitPayment);
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

  // บันทึกการชำระเงิน
  Future<void> _onSubmitPayment(SubmitPreOrderPayment event, Emitter<PreOrderState> emit) async {
    try {
      // ตรวจสอบว่าอยู่ใน state ที่มีข้อมูลรายละเอียดพรีออเดอร์
      if (state is PreOrderDetailLoaded) {
        final currentState = state as PreOrderDetailLoaded;
        emit(PreOrderPaymentSubmitting());

        // ทำการอัปเดตสถานะการชำระเงินไปยัง API
        // ส่งข้อมูลไปยัง endpoint updateTrans
        // สำเร็จ = true ถ้าอัปเดต API สำเร็จ
        bool success = true; // จำลองว่า API call สำเร็จ

        // ถ้าสำเร็จ
        if (success) {
          emit(PreOrderPaymentSuccess(event.docNo));
        } else {
          emit(const PreOrderError('ไม่สามารถบันทึกการชำระเงินได้'));
        }
      } else {
        emit(const PreOrderError('ไม่พบข้อมูลรายละเอียดพรีออเดอร์'));
      }
    } catch (e) {
      _logger.e('Error submitting payment: $e');
      emit(PreOrderError('เกิดข้อผิดพลาดในการบันทึกการชำระเงิน: ${e.toString()}'));
    }
  }
}
