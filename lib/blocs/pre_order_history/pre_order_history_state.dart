// /lib/blocs/pre_order_history/pre_order_history_state.dart
import 'package:equatable/equatable.dart';
import 'package:wawa_vansales/data/models/pre_order_history_detail_model.dart';
import 'package:wawa_vansales/data/models/pre_order_history_model.dart';

abstract class PreOrderHistoryState extends Equatable {
  const PreOrderHistoryState();

  @override
  List<Object?> get props => [];
}

// สถานะเริ่มต้น
class PreOrderHistoryInitial extends PreOrderHistoryState {}

// สถานะกำลังโหลดข้อมูล
class PreOrderHistoryLoading extends PreOrderHistoryState {}

// สถานะโหลดรายการสำเร็จ
class PreOrderHistoryListLoaded extends PreOrderHistoryState {
  final List<PreOrderHistoryModel> preOrderHistoryList;

  const PreOrderHistoryListLoaded(this.preOrderHistoryList);

  @override
  List<Object?> get props => [preOrderHistoryList];
}

// สถานะกำลังโหลดรายละเอียด
class PreOrderHistoryDetailLoading extends PreOrderHistoryState {}

// สถานะโหลดรายละเอียดสำเร็จ
class PreOrderHistoryDetailLoaded extends PreOrderHistoryState {
  final String docNo;
  final List<PreOrderHistoryDetailModel> items;
  final double totalAmount;

  const PreOrderHistoryDetailLoaded({
    required this.docNo,
    required this.items,
    required this.totalAmount,
  });

  @override
  List<Object?> get props => [docNo, items, totalAmount];
}

// สถานะเกิดข้อผิดพลาด
class PreOrderHistoryError extends PreOrderHistoryState {
  final String message;

  const PreOrderHistoryError(this.message);

  @override
  List<Object?> get props => [message];
}
