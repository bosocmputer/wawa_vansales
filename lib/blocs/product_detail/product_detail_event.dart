// lib/blocs/product_detail/product_detail_event.dart
import 'package:equatable/equatable.dart';

abstract class ProductDetailEvent extends Equatable {
  const ProductDetailEvent();

  @override
  List<Object?> get props => [];
}

class FetchProductByBarcode extends ProductDetailEvent {
  final String barcode;
  final String customerCode;

  const FetchProductByBarcode({
    required this.barcode,
    required this.customerCode,
  });

  @override
  List<Object?> get props => [barcode, customerCode];
}

class ResetProductDetail extends ProductDetailEvent {}
