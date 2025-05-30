import 'package:equatable/equatable.dart';
import 'package:wawa_vansales/data/models/product_model.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

// ดึงรายการสินค้า
class FetchProducts extends ProductEvent {
  final String searchQuery;
  final String whCode;
  final String shelfCode;

  const FetchProducts({
    this.searchQuery = '',
    required this.whCode,
    required this.shelfCode,
  });

  @override
  List<Object?> get props => [searchQuery, whCode, shelfCode];
}

// ดึงรายการสินค้า รับคืน
class FetchProductReturns extends ProductEvent {
  final String searchQuery;
  final String custCode;

  const FetchProductReturns({
    this.searchQuery = '',
    required this.custCode,
  });

  @override
  List<Object?> get props => [searchQuery, custCode];
}

// เลือกสินค้า
class SelectProduct extends ProductEvent {
  final ProductModel product;

  const SelectProduct(this.product);

  @override
  List<Object?> get props => [product];
}

// รีเซ็ตสถานะสินค้าที่เลือก
class ResetSelectedProduct extends ProductEvent {}

// รีเซ็ตสถานะทั้งหมด
class ResetProductState extends ProductEvent {}

// กำหนดคำค้นหา
class SetProductSearchQuery extends ProductEvent {
  final String query;
  final String whCode;
  final String shelfCode;

  const SetProductSearchQuery(this.query, this.whCode, this.shelfCode);

  @override
  List<Object?> get props => [query];
}
