import 'package:equatable/equatable.dart';

abstract class SalesSummaryEvent extends Equatable {
  const SalesSummaryEvent();

  @override
  List<Object?> get props => [];
}

// ดึงข้อมูลยอดขายวันนี้
class FetchTodaysSalesSummary extends SalesSummaryEvent {}

// รีเฟรชข้อมูลยอดขายวันนี้
class RefreshTodaysSalesSummary extends SalesSummaryEvent {}
