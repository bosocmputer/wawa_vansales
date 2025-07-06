import 'package:equatable/equatable.dart';

abstract class PreOrderSummaryEvent extends Equatable {
  const PreOrderSummaryEvent();

  @override
  List<Object?> get props => [];
}

// ดึงข้อมูลยอดพรีออเดอร์วันนี้
class FetchTodaysPreOrderSummary extends PreOrderSummaryEvent {}

// รีเฟรชข้อมูลยอดพรีออเดอร์วันนี้
class RefreshTodaysPreOrderSummary extends PreOrderSummaryEvent {}
