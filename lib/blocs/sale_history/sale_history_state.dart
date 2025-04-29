import 'package:equatable/equatable.dart';
import 'package:wawa_vansales/data/models/sale_history_model.dart';
import 'package:wawa_vansales/data/models/sale_history_detail_model.dart';

abstract class SaleHistoryState extends Equatable {
  const SaleHistoryState();

  @override
  List<Object?> get props => [];
}

// สถานะเริ่มต้น
class SaleHistoryInitial extends SaleHistoryState {}

// กำลังโหลดข้อมูลประวัติการขาย
class SaleHistoryLoading extends SaleHistoryState {}

// โหลดข้อมูลประวัติการขายสำเร็จ
class SaleHistoryLoaded extends SaleHistoryState {
  final List<SaleHistoryModel> sales;
  final String searchQuery;
  final DateTime? fromDate;
  final DateTime? toDate;

  const SaleHistoryLoaded({
    required this.sales,
    this.searchQuery = '',
    this.fromDate,
    this.toDate,
  });

  @override
  List<Object?> get props => [sales, searchQuery, fromDate, toDate];
}

// โหลดข้อมูลประวัติการขายล้มเหลว
class SaleHistoryError extends SaleHistoryState {
  final String message;

  const SaleHistoryError(this.message);

  @override
  List<Object?> get props => [message];
}

// กำลังโหลดรายละเอียดการขาย
class SaleHistoryDetailLoading extends SaleHistoryState {}

// โหลดรายละเอียดการขายสำเร็จ
class SaleHistoryDetailLoaded extends SaleHistoryState {
  final List<SaleHistoryDetailModel> items;
  final String docNo;

  const SaleHistoryDetailLoaded({
    required this.items,
    required this.docNo,
  });

  @override
  List<Object?> get props => [items, docNo];
}

// โหลดรายละเอียดการขายล้มเหลว
class SaleHistoryDetailError extends SaleHistoryState {
  final String message;

  const SaleHistoryDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
