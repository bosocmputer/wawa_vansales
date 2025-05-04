import 'package:equatable/equatable.dart';

abstract class SaleHistoryEvent extends Equatable {
  const SaleHistoryEvent();

  @override
  List<Object?> get props => [];
}

// ดึงประวัติการขาย
class FetchSaleHistory extends SaleHistoryEvent {
  final String search;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? warehouseCode;

  const FetchSaleHistory({
    this.search = '',
    this.fromDate,
    this.toDate,
    this.warehouseCode,
  });

  @override
  List<Object?> get props => [search, fromDate, toDate, warehouseCode];
}

// ดึงรายละเอียดการขาย
class FetchSaleHistoryDetail extends SaleHistoryEvent {
  final String docNo;

  const FetchSaleHistoryDetail(this.docNo);

  @override
  List<Object?> get props => [docNo];
}

// กำหนดช่วงวันที่
class SetDateRange extends SaleHistoryEvent {
  final DateTime fromDate;
  final DateTime toDate;

  const SetDateRange({
    required this.fromDate,
    required this.toDate,
  });

  @override
  List<Object?> get props => [fromDate, toDate];
}

// กำหนดการค้นหา
class SetHistorySearchQuery extends SaleHistoryEvent {
  final String query;

  const SetHistorySearchQuery(this.query);

  @override
  List<Object?> get props => [query];
}

// รีเซ็ตข้อมูลรายละเอียด
class ResetSaleHistoryDetail extends SaleHistoryEvent {}

// รีเซ็ตสถานะทั้งหมด
class ResetSaleHistoryState extends SaleHistoryEvent {}
