// lib/blocs/product_detail/product_detail_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:wawa_vansales/blocs/product_detail/product_detail_event.dart';
import 'package:wawa_vansales/blocs/product_detail/product_detail_state.dart';
import 'package:wawa_vansales/data/repositories/product_repository.dart';

class ProductDetailBloc extends Bloc<ProductDetailEvent, ProductDetailState> {
  final ProductRepository _productRepository;
  final Logger _logger = Logger();

  ProductDetailBloc({required ProductRepository productRepository})
      : _productRepository = productRepository,
        super(ProductDetailInitial()) {
    on<FetchProductByBarcode>(_onFetchProductByBarcode);
    on<ResetProductDetail>(_onResetProductDetail);
  }

// ใน ProductDetailBloc
  Future<void> _onFetchProductByBarcode(
    FetchProductByBarcode event,
    Emitter<ProductDetailState> emit,
  ) async {
    // ตรวจสอบว่า state ปัจจุบันไม่ใช่ ProductDetailLoaded
    // เพื่อป้องกันการส่ง event ซ้ำซ้อน
    if (state is ProductDetailLoaded) {
      // ถ้าเป็น state ProductDetailLoaded อยู่แล้ว ให้ reset ก่อน
      emit(ProductDetailInitial());
    }

    _logger.i('Fetching product detail for barcode: ${event.barcode}');
    emit(ProductDetailLoading());

    try {
      final product = await _productRepository.getProductByBarcode(
        event.barcode,
        event.customerCode,
      );

      if (product != null) {
        _logger.i('Product found: ${product.itemName}');
        emit(ProductDetailLoaded(product));
      } else {
        _logger.w('Product not found for barcode: ${event.barcode}');
        emit(ProductDetailNotFound(event.barcode));
      }
    } catch (e) {
      _logger.e('Error fetching product detail: $e');
      emit(ProductDetailError(e.toString()));
    }
  }

  void _onResetProductDetail(
    ResetProductDetail event,
    Emitter<ProductDetailState> emit,
  ) {
    _logger.i('Resetting product detail');
    emit(ProductDetailInitial());
  }
}
