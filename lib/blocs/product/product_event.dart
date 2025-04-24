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

  const FetchProducts({this.searchQuery = ''});

  @override
  List<Object?> get props => [searchQuery];
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

// กำหนดคำค้นหา
class SetProductSearchQuery extends ProductEvent {
  final String query;

  const SetProductSearchQuery(this.query);

  @override
  List<Object?> get props => [query];
}
