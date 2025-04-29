import 'package:equatable/equatable.dart';

abstract class SalesSummaryState extends Equatable {
  const SalesSummaryState();

  @override
  List<Object?> get props => [];
}

// สถานะเริ่มต้น
class SalesSummaryInitial extends SalesSummaryState {}

// กำลังโหลดข้อมูลยอดขาย
class SalesSummaryLoading extends SalesSummaryState {}

// โหลดข้อมูลยอดขายสำเร็จ
class SalesSummaryLoaded extends SalesSummaryState {
  final double totalAmount;
  final int billCount;
  final DateTime timestamp; // เพิ่มเพื่อให้รู้ว่าข้อมูลอัปเดตเมื่อไร

  const SalesSummaryLoaded({
    required this.totalAmount,
    required this.billCount,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [totalAmount, billCount, timestamp];
}

// โหลดข้อมูลยอดขายล้มเหลว
class SalesSummaryError extends SalesSummaryState {
  final String message;

  const SalesSummaryError(this.message);

  @override
  List<Object?> get props => [message];
}
