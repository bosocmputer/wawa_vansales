import 'package:equatable/equatable.dart';

abstract class PreOrderSummaryState extends Equatable {
  const PreOrderSummaryState();

  @override
  List<Object?> get props => [];
}

// สถานะเริ่มต้น
class PreOrderSummaryInitial extends PreOrderSummaryState {}

// กำลังโหลดข้อมูลยอดพรีออเดอร์
class PreOrderSummaryLoading extends PreOrderSummaryState {}

// โหลดข้อมูลยอดพรีออเดอร์สำเร็จ
class PreOrderSummaryLoaded extends PreOrderSummaryState {
  final double totalAmount;
  final int billCount;
  final DateTime timestamp; // เพิ่มเพื่อให้รู้ว่าข้อมูลอัปเดตเมื่อไร

  const PreOrderSummaryLoaded({
    required this.totalAmount,
    required this.billCount,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [totalAmount, billCount, timestamp];
}

// โหลดข้อมูลยอดพรีออเดอร์ล้มเหลว
class PreOrderSummaryError extends PreOrderSummaryState {
  final String message;

  const PreOrderSummaryError(this.message);

  @override
  List<Object?> get props => [message];
}
