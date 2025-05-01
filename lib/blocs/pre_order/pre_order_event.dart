import 'package:equatable/equatable.dart';

abstract class PreOrderEvent extends Equatable {
  const PreOrderEvent();

  @override
  List<Object?> get props => [];
}

// Event สำหรับดึงรายการพรีออเดอร์ตามลูกค้า
class FetchPreOrders extends PreOrderEvent {
  final String customerCode;

  const FetchPreOrders(this.customerCode);

  @override
  List<Object?> get props => [customerCode];
}

// Event สำหรับดึงรายละเอียดของพรีออเดอร์
class FetchPreOrderDetail extends PreOrderEvent {
  final String docNo;

  const FetchPreOrderDetail(this.docNo);

  @override
  List<Object?> get props => [docNo];
}

// Event สำหรับรีเซ็ตสถานะ
class ResetPreOrderState extends PreOrderEvent {}

// Event สำหรับบันทึกการจ่ายเงินพรีออเดอร์
class SubmitPreOrderPayment extends PreOrderEvent {
  final String docNo;
  final String remark;

  const SubmitPreOrderPayment({
    required this.docNo,
    this.remark = '',
  });

  @override
  List<Object?> get props => [docNo, remark];
}
