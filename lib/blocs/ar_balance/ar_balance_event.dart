// lib/blocs/ar_balance/ar_balance_event.dart
import 'package:equatable/equatable.dart';
import 'package:wawa_vansales/data/models/ar_balance_model.dart';

abstract class ArBalanceEvent extends Equatable {
  const ArBalanceEvent();

  @override
  List<Object?> get props => [];
}

// เรียกข้อมูล AR Balance
class FetchArBalance extends ArBalanceEvent {
  final String customerCode;

  const FetchArBalance(this.customerCode);

  @override
  List<Object?> get props => [customerCode];
}

// อัปเดตจำนวนเงินที่เลือกใช้ลดหนี้
class UpdateSelectedAmount extends ArBalanceEvent {
  final ArBalanceModel document;
  final double amount;

  const UpdateSelectedAmount({
    required this.document,
    required this.amount,
  });

  @override
  List<Object?> get props => [document, amount];
}

// ยืนยันการเลือกเอกสารลดหนี้
class ConfirmCreditPayment extends ArBalanceEvent {
  final List<ArBalanceModel> selectedDocuments;

  const ConfirmCreditPayment(this.selectedDocuments);

  @override
  List<Object?> get props => [selectedDocuments];
}

// รีเซ็ตสถานะทั้งหมด
class ResetArBalance extends ArBalanceEvent {}
