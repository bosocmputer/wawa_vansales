import 'package:equatable/equatable.dart';
import 'package:wawa_vansales/data/models/return_product/product_return_model.dart';

abstract class ProductReturnSearchEvent extends Equatable {
  const ProductReturnSearchEvent();

  @override
  List<Object?> get props => [];
}

// ดึงรายการสินค้ารับคืน
class FetchProductsReturnSearch extends ProductReturnSearchEvent {
  final String searchQuery;
  final String custCode;

  const FetchProductsReturnSearch({
    this.searchQuery = '',
    required this.custCode,
  });

  @override
  List<Object?> get props => [searchQuery, custCode];
}

// เลือกสินค้า
class SelectProductReturn extends ProductReturnSearchEvent {
  final ProductReturnModel product;

  const SelectProductReturn(this.product);

  @override
  List<Object?> get props => [product];
}

// รีเซ็ตสถานะสินค้าที่เลือก
class ResetSelectedProductReturn extends ProductReturnSearchEvent {}

// ตั้งค่า search query
class SetProductReturnSearchQuery extends ProductReturnSearchEvent {
  final String searchQuery;
  final String custCode;

  const SetProductReturnSearchQuery(this.searchQuery, this.custCode);

  @override
  List<Object?> get props => [searchQuery, custCode];
}

// รีเซ็ตสถานะทั้งหมด
class ResetProductReturnSearchState extends ProductReturnSearchEvent {}
