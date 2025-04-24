import 'package:equatable/equatable.dart';
import 'package:wawa_vansales/data/models/product_model.dart';

abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object?> get props => [];
}

// สถานะเริ่มต้น
class ProductInitial extends ProductState {}

// กำลังโหลดข้อมูลสินค้า
class ProductsLoading extends ProductState {}

// โหลดข้อมูลสินค้าสำเร็จ
class ProductsLoaded extends ProductState {
  final List<ProductModel> products;
  final String searchQuery;

  const ProductsLoaded({
    required this.products,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [products, searchQuery];
}

// โหลดข้อมูลสินค้าล้มเหลว
class ProductsError extends ProductState {
  final String message;

  const ProductsError(this.message);

  @override
  List<Object?> get props => [message];
}

// เลือกสินค้าแล้ว
class ProductSelected extends ProductState {
  final ProductModel product;
  final List<ProductModel> products;

  const ProductSelected({
    required this.product,
    required this.products,
  });

  @override
  List<Object?> get props => [product, products];
}
