// lib/blocs/ar_balance/ar_balance_state.dart
import 'package:equatable/equatable.dart';
import 'package:wawa_vansales/data/models/ar_balance_model.dart';

abstract class ArBalanceState extends Equatable {
  const ArBalanceState();

  @override
  List<Object?> get props => [];
}

// สถานะเริ่มต้น
class ArBalanceInitial extends ArBalanceState {}

// กำลังโหลดข้อมูล
class ArBalanceLoading extends ArBalanceState {}

// โหลดข้อมูลสำเร็จ
class ArBalanceLoaded extends ArBalanceState {
  final List<ArBalanceModel> documents;
  final double totalSelectedAmount;

  const ArBalanceLoaded({
    required this.documents,
    this.totalSelectedAmount = 0.0,
  });

  @override
  List<Object?> get props => [documents, totalSelectedAmount];

  // สร้าง state ใหม่เมื่อมีการอัปเดตข้อมูล
  ArBalanceLoaded copyWith({
    List<ArBalanceModel>? documents,
    double? totalSelectedAmount,
  }) {
    return ArBalanceLoaded(
      documents: documents ?? this.documents,
      totalSelectedAmount: totalSelectedAmount ?? this.totalSelectedAmount,
    );
  }
}

// เลือกเอกสารลดหนี้สำเร็จ
class ArBalanceSelectionComplete extends ArBalanceState {
  final List<ArBalanceModel> selectedDocuments;
  final double totalSelectedAmount;

  const ArBalanceSelectionComplete({
    required this.selectedDocuments,
    required this.totalSelectedAmount,
  });

  @override
  List<Object?> get props => [selectedDocuments, totalSelectedAmount];
}

// เกิดข้อผิดพลาด
class ArBalanceError extends ArBalanceState {
  final String message;

  const ArBalanceError(this.message);

  @override
  List<Object> get props => [message];
}
