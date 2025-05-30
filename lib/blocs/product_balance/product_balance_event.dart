import 'package:equatable/equatable.dart';

abstract class ProductBalanceEvent extends Equatable {
  const ProductBalanceEvent();

  @override
  List<Object?> get props => [];
}

// ดึงข้อมูลยอดสินค้าคงเหลือ
class FetchProductBalance extends ProductBalanceEvent {
  final String searchQuery;
  final String whCode;
  final String shelfCode;

  const FetchProductBalance({
    this.searchQuery = '',
    required this.whCode,
    required this.shelfCode,
  });

  @override
  List<Object?> get props => [searchQuery, whCode, shelfCode];
}

// รีเซ็ตสถานะทั้งหมด
class ResetProductBalanceState extends ProductBalanceEvent {}

// กำหนดคำค้นหา
class SetProductBalanceSearchQuery extends ProductBalanceEvent {
  final String query;
  final String whCode;
  final String shelfCode;

  const SetProductBalanceSearchQuery(this.query, this.whCode, this.shelfCode);

  @override
  List<Object?> get props => [query, whCode, shelfCode];
}
