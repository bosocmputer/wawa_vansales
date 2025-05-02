// /lib/blocs/pre_order_history/pre_order_history_event.dart
import 'package:equatable/equatable.dart';

abstract class PreOrderHistoryEvent extends Equatable {
  const PreOrderHistoryEvent();

  @override
  List<Object?> get props => [];
}

// เหตุการณ์ดึงรายการประวัติการขาย (พรีออเดอร์)
class FetchPreOrderHistoryList extends PreOrderHistoryEvent {
  // เพิ่มพารามิเตอร์ fromDate, toDate และ search
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? search;
  final String warehouseCode;

  const FetchPreOrderHistoryList({
    this.fromDate,
    this.toDate,
    this.search,
    required this.warehouseCode,
  });

  @override
  List<Object?> get props => [fromDate, toDate, search];
}

// เหตุการณ์ดึงรายละเอียดประวัติการขาย (พรีออเดอร์)
class FetchPreOrderHistoryDetail extends PreOrderHistoryEvent {
  final String docNo;

  const FetchPreOrderHistoryDetail(this.docNo);

  @override
  List<Object?> get props => [docNo];
}

// เหตุการณ์รีเซ็ตสถานะ
class ResetPreOrderHistoryState extends PreOrderHistoryEvent {}

// เหตุการณ์รีเซ็ตสถานะรายละเอียดของพรีออเดอร์
class ResetPreOrderHistoryDetail extends PreOrderHistoryEvent {}

// เหตุการณ์ตั้งค่าช่วงวันที่
class SetPreOrderDateRange extends PreOrderHistoryEvent {
  final DateTime fromDate;
  final DateTime toDate;

  const SetPreOrderDateRange({
    required this.fromDate,
    required this.toDate,
  });

  @override
  List<Object?> get props => [fromDate, toDate];
}

// เหตุการณ์ตั้งค่าคำค้นหา
class SetPreOrderHistorySearchQuery extends PreOrderHistoryEvent {
  final String query;

  const SetPreOrderHistorySearchQuery(this.query);

  @override
  List<Object?> get props => [query];
}
