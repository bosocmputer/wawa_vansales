import 'package:equatable/equatable.dart';
import 'package:wawa_vansales/data/models/product_balance_model.dart';

abstract class ProductBalanceState extends Equatable {
  const ProductBalanceState();

  @override
  List<Object?> get props => [];
}

// สถานะเริ่มต้น
class ProductBalanceInitial extends ProductBalanceState {}

// กำลังโหลดข้อมูลยอดคงเหลือ
class ProductBalanceLoading extends ProductBalanceState {}

// โหลดข้อมูลยอดคงเหลือสำเร็จ
class ProductBalanceLoaded extends ProductBalanceState {
  final List<ProductBalanceModel> balances;
  final String searchQuery;

  const ProductBalanceLoaded({
    required this.balances,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [balances, searchQuery];
}

// โหลดข้อมูลยอดคงเหลือล้มเหลว
class ProductBalanceError extends ProductBalanceState {
  final String message;

  const ProductBalanceError(this.message);

  @override
  List<Object?> get props => [message];
}
