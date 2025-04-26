// lib/blocs/product_detail/product_detail_state.dart
import 'package:equatable/equatable.dart';
import 'package:wawa_vansales/data/models/product_detail_model.dart';

abstract class ProductDetailState extends Equatable {
  const ProductDetailState();

  @override
  List<Object?> get props => [];
}

class ProductDetailInitial extends ProductDetailState {}

class ProductDetailLoading extends ProductDetailState {}

class ProductDetailLoaded extends ProductDetailState {
  final ProductDetailModel product;

  const ProductDetailLoaded(this.product);

  @override
  List<Object?> get props => [product];
}

class ProductDetailError extends ProductDetailState {
  final String message;

  const ProductDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

class ProductDetailNotFound extends ProductDetailState {
  final String barcode;

  const ProductDetailNotFound(this.barcode);

  @override
  List<Object?> get props => [barcode];
}
