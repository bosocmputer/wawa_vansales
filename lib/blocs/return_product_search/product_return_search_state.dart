import 'package:equatable/equatable.dart';
import 'package:wawa_vansales/data/models/return_product/product_return_model.dart';

abstract class ProductReturnSearchState extends Equatable {
  const ProductReturnSearchState();

  @override
  List<Object?> get props => [];
}

class ProductReturnSearchInitial extends ProductReturnSearchState {}

class ProductReturnSearchLoading extends ProductReturnSearchState {}

class ProductReturnSearchLoaded extends ProductReturnSearchState {
  final List<ProductReturnModel> products;
  final String searchQuery;

  const ProductReturnSearchLoaded({
    required this.products,
    required this.searchQuery,
  });

  @override
  List<Object?> get props => [products, searchQuery];
}

class ProductReturnSelected extends ProductReturnSearchState {
  final ProductReturnModel product;
  final List<ProductReturnModel> products;

  const ProductReturnSelected({
    required this.product,
    required this.products,
  });

  @override
  List<Object?> get props => [product, products];
}

class ProductReturnSearchError extends ProductReturnSearchState {
  final String message;

  const ProductReturnSearchError(this.message);

  @override
  List<Object?> get props => [message];
}
