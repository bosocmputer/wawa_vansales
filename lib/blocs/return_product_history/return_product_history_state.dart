// lib/blocs/return_product_history/return_product_history_state.dart
import 'package:equatable/equatable.dart';
import 'package:wawa_vansales/data/models/return_product/return_product_history_detail_model.dart';
import 'package:wawa_vansales/data/models/return_product/return_product_history_model.dart';

abstract class ReturnProductHistoryState extends Equatable {
  const ReturnProductHistoryState();

  @override
  List<Object?> get props => [];
}

// สถานะเริ่มต้น
class ReturnProductHistoryInitial extends ReturnProductHistoryState {}

// สถานะกำลังโหลดข้อมูล
class ReturnProductHistoryLoading extends ReturnProductHistoryState {}

// สถานะโหลดข้อมูลสำเร็จ (สำหรับแสดงรายการ)
class ReturnProductHistoryLoaded extends ReturnProductHistoryState {
  final List<ReturnProductHistoryModel> history;

  const ReturnProductHistoryLoaded(this.history);

  @override
  List<Object?> get props => [history];
}

// สถานะโหลดรายละเอียดสำเร็จ
class ReturnProductHistoryDetailLoaded extends ReturnProductHistoryState {
  final String docNo;
  final List<ReturnProductHistoryDetailModel> items;

  const ReturnProductHistoryDetailLoaded({
    required this.docNo,
    required this.items,
  });

  // คำนวณยอดรวมทั้งหมด
  double get totalAmount => items.fold(0, (sum, item) => sum + item.totalAmount);

  @override
  List<Object?> get props => [docNo, items];
}

// สถานะเกิดข้อผิดพลาด
class ReturnProductHistoryError extends ReturnProductHistoryState {
  final String message;

  const ReturnProductHistoryError(this.message);

  @override
  List<Object?> get props => [message];
}
