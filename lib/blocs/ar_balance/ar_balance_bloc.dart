// lib/blocs/ar_balance/ar_balance_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:wawa_vansales/blocs/ar_balance/ar_balance_event.dart';
import 'package:wawa_vansales/blocs/ar_balance/ar_balance_state.dart';
import 'package:wawa_vansales/data/models/ar_balance_model.dart';
import 'package:wawa_vansales/data/repositories/ar_balance_repository.dart';

class ArBalanceBloc extends Bloc<ArBalanceEvent, ArBalanceState> {
  final ArBalanceRepository _arBalanceRepository;
  final Logger _logger = Logger();

  ArBalanceBloc({required ArBalanceRepository arBalanceRepository})
      : _arBalanceRepository = arBalanceRepository,
        super(ArBalanceInitial()) {
    on<FetchArBalance>(_onFetchArBalance);
    on<UpdateSelectedAmount>(_onUpdateSelectedAmount);
    on<ConfirmCreditPayment>(_onConfirmCreditPayment);
    on<ResetArBalance>(_onResetArBalance);
  }

  // ดึงข้อมูลเอกสารลดหนี้
  Future<void> _onFetchArBalance(FetchArBalance event, Emitter<ArBalanceState> emit) async {
    emit(ArBalanceLoading());

    try {
      final documents = await _arBalanceRepository.getArBalance(event.customerCode);

      if (documents.isEmpty) {
        emit(const ArBalanceError('ไม่พบเอกสารลดหนี้สำหรับลูกค้านี้'));
      } else {
        emit(ArBalanceLoaded(documents: documents));
      }
    } catch (e) {
      _logger.e('Error fetching AR balance: $e');
      emit(ArBalanceError('เกิดข้อผิดพลาดในการดึงข้อมูล: ${e.toString()}'));
    }
  }

  // อัปเดตจำนวนเงินที่เลือก
  void _onUpdateSelectedAmount(UpdateSelectedAmount event, Emitter<ArBalanceState> emit) {
    if (state is ArBalanceLoaded) {
      final currentState = state as ArBalanceLoaded;
      final documents = List<ArBalanceModel>.from(currentState.documents);

      // หาและอัปเดตเอกสารที่ต้องการ
      final index = documents.indexWhere((doc) => doc.docNo == event.document.docNo);
      if (index != -1) {
        // ตรวจสอบว่าจำนวนไม่เกินยอดคงเหลือ
        final maxAmount = documents[index].balanceAmount;
        final amount = event.amount > maxAmount ? maxAmount : event.amount;

        // สร้างเอกสารใหม่พร้อมค่าที่อัปเดต
        documents[index] = ArBalanceModel(
          custCode: documents[index].custCode,
          balance: documents[index].balance,
          docNo: documents[index].docNo,
          docDate: documents[index].docDate,
          custName: documents[index].custName,
          transFlag: documents[index].transFlag,
          selectedAmount: amount,
        );
      }

      // คำนวณยอดรวมที่เลือก
      final totalAmount = documents.where((doc) => doc.selectedAmount != null && doc.selectedAmount! > 0).fold(0.0, (sum, doc) => sum + (doc.selectedAmount ?? 0));

      emit(currentState.copyWith(
        documents: documents,
        totalSelectedAmount: totalAmount,
      ));
    }
  }

  // ยืนยันการเลือกเอกสารลดหนี้
  void _onConfirmCreditPayment(ConfirmCreditPayment event, Emitter<ArBalanceState> emit) {
    final selectedDocs = event.selectedDocuments.where((doc) => doc.selectedAmount != null && doc.selectedAmount! > 0).toList();

    final totalAmount = selectedDocs.fold(0.0, (sum, doc) => sum + (doc.selectedAmount ?? 0));

    if (selectedDocs.isNotEmpty) {
      emit(ArBalanceSelectionComplete(
        selectedDocuments: selectedDocs,
        totalSelectedAmount: totalAmount,
      ));
    } else {
      emit(const ArBalanceError('กรุณาเลือกอย่างน้อย 1 เอกสารลดหนี้'));
    }
  }

  // รีเซ็ตสถานะ
  void _onResetArBalance(ResetArBalance event, Emitter<ArBalanceState> emit) {
    emit(ArBalanceInitial());
  }
}
