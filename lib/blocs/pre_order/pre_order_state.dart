import 'package:equatable/equatable.dart';
import 'package:wawa_vansales/data/models/pre_order_model.dart';

abstract class PreOrderState extends Equatable {
  const PreOrderState();

  @override
  List<Object?> get props => [];
}

// สถานะเริ่มต้น
class PreOrderInitial extends PreOrderState {}

// สถานะกำลังโหลดรายการพรีออเดอร์
class PreOrderLoading extends PreOrderState {}

// สถานะโหลดรายการพรีออเดอร์สำเร็จ
class PreOrdersLoaded extends PreOrderState {
  final List<PreOrderModel> preOrders;

  const PreOrdersLoaded(this.preOrders);

  @override
  List<Object?> get props => [preOrders];
}

// สถานะค้นหาพรีออเดอร์ด้วยเลขที่เอกสารสำเร็จ
class PreOrderSearchResult extends PreOrderState {
  final PreOrderModel? preOrder;
  final String searchQuery;

  const PreOrderSearchResult({
    this.preOrder,
    required this.searchQuery,
  });

  @override
  List<Object?> get props => [preOrder, searchQuery];
}

// สถานะกำลังโหลดรายละเอียดพรีออเดอร์
class PreOrderDetailLoading extends PreOrderState {}

// สถานะโหลดรายละเอียดพรีออเดอร์สำเร็จ
class PreOrderDetailLoaded extends PreOrderState {
  final String docNo;
  final List<PreOrderDetailModel> items;
  final double totalAmount;

  const PreOrderDetailLoaded({
    required this.docNo,
    required this.items,
    required this.totalAmount,
  });

  @override
  List<Object?> get props => [docNo, items, totalAmount];
}

// สถานะเกิดข้อผิดพลาด
class PreOrderError extends PreOrderState {
  final String message;

  const PreOrderError(this.message);

  @override
  List<Object?> get props => [message];
}
