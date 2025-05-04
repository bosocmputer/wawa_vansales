// lib/blocs/return_product_history/return_product_history_event.dart
import 'package:equatable/equatable.dart';

abstract class ReturnProductHistoryEvent extends Equatable {
  const ReturnProductHistoryEvent();

  @override
  List<Object?> get props => [];
}

// Event สำหรับดึงข้อมูลรายการประวัติการรับคืนสินค้า
class FetchReturnProductHistory extends ReturnProductHistoryEvent {
  final String search;
  final String fromDate;
  final String toDate;

  const FetchReturnProductHistory({
    this.search = '',
    required this.fromDate,
    required this.toDate,
  });

  @override
  List<Object?> get props => [search, fromDate, toDate];
}

// Event สำหรับดึงข้อมูลรายละเอียดของรายการรับคืนสินค้า
class FetchReturnProductHistoryDetail extends ReturnProductHistoryEvent {
  final String docNo;

  const FetchReturnProductHistoryDetail(this.docNo);

  @override
  List<Object?> get props => [docNo];
}

// Event สำหรับล้างสถานะ (เช่น เมื่อกลับไปหน้า list)
class ClearReturnProductHistoryDetail extends ReturnProductHistoryEvent {}
