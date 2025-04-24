import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:wawa_vansales/blocs/product/product_event.dart';
import 'package:wawa_vansales/blocs/product/product_state.dart';
import 'package:wawa_vansales/data/models/product_model.dart';
import 'package:wawa_vansales/data/repositories/product_repository.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository _productRepository;
  final Logger _logger = Logger();

  // เก็บรายการสินค้าและสินค้าที่เลือก
  List<ProductModel> _products = [];
  String _searchQuery = '';

  ProductBloc({required ProductRepository productRepository})
      : _productRepository = productRepository,
        super(ProductInitial()) {
    on<FetchProducts>(_onFetchProducts);
    on<SelectProduct>(_onSelectProduct);
    on<ResetSelectedProduct>(_onResetSelectedProduct);
    on<SetProductSearchQuery>(_onSetProductSearchQuery);
  }

  // ดึงรายการสินค้า
  Future<void> _onFetchProducts(
    FetchProducts event,
    Emitter<ProductState> emit,
  ) async {
    _logger.i('Fetching products with search: ${event.searchQuery}');
    emit(ProductsLoading());

    try {
      final products = await _productRepository.getProducts(
        search: event.searchQuery,
      );

      _products = products;
      _searchQuery = event.searchQuery;

      _logger.i('Fetched ${products.length} products');
      emit(ProductsLoaded(
        products: products,
        searchQuery: event.searchQuery,
      ));
    } catch (e) {
      _logger.e('Error fetching products: $e');
      emit(ProductsError(e.toString()));
    }
  }

  // เลือกสินค้า
  void _onSelectProduct(
    SelectProduct event,
    Emitter<ProductState> emit,
  ) {
    _logger.i('Product selected: ${event.product.itemCode} - ${event.product.itemName}');
    emit(ProductSelected(
      product: event.product,
      products: _products,
    ));
  }

  // รีเซ็ตสินค้าที่เลือก
  void _onResetSelectedProduct(
    ResetSelectedProduct event,
    Emitter<ProductState> emit,
  ) {
    _logger.i('Reset selected product');
    emit(ProductsLoaded(
      products: _products,
      searchQuery: _searchQuery,
    ));
  }

  // กำหนดคำค้นหา
  void _onSetProductSearchQuery(
    SetProductSearchQuery event,
    Emitter<ProductState> emit,
  ) {
    _logger.i('Set product search query: ${event.query}');
    _searchQuery = event.query;

    // เรียก fetch products ด้วยคำค้นหาใหม่
    add(FetchProducts(searchQuery: event.query));
  }
}
