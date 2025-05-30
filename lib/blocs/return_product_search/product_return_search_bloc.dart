import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:wawa_vansales/blocs/return_product_search/product_return_search_event.dart';
import 'package:wawa_vansales/blocs/return_product_search/product_return_search_state.dart';
import 'package:wawa_vansales/data/models/return_product/product_return_model.dart';
import 'package:wawa_vansales/data/repositories/product_return_search_repository.dart';

class ProductReturnSearchBloc extends Bloc<ProductReturnSearchEvent, ProductReturnSearchState> {
  final ProductReturnSearchRepository _productRepository;
  final Logger _logger = Logger();

  // เก็บรายการสินค้าและสินค้าที่เลือก
  List<ProductReturnModel> _products = [];
  String _searchQuery = '';

  ProductReturnSearchBloc({required ProductReturnSearchRepository productRepository})
      : _productRepository = productRepository,
        super(ProductReturnSearchInitial()) {
    on<FetchProductsReturnSearch>(_onFetchProductsReturnSearch);
    on<SelectProductReturn>(_onSelectProductReturn);
    on<ResetSelectedProductReturn>(_onResetSelectedProductReturn);
    on<SetProductReturnSearchQuery>(_onSetProductReturnSearchQuery);
    on<ResetProductReturnSearchState>(_onResetProductReturnSearchState);
  }

  // ดึงรายการสินค้ารับคืน
  Future<void> _onFetchProductsReturnSearch(
    FetchProductsReturnSearch event,
    Emitter<ProductReturnSearchState> emit,
  ) async {
    _logger.i('Fetching product returns with search: ${event.searchQuery} for customer: ${event.custCode}');
    emit(ProductReturnSearchLoading());

    try {
      final products = await _productRepository.getProductsReturn(
        search: event.searchQuery,
        custCode: event.custCode,
      );

      _products = products;
      _searchQuery = event.searchQuery;

      _logger.i('Fetched ${products.length} product returns');
      emit(ProductReturnSearchLoaded(
        products: products,
        searchQuery: event.searchQuery,
      ));
    } catch (e) {
      _logger.e('Error fetching product returns: $e');
      emit(ProductReturnSearchError(e.toString()));
    }
  }

  // เลือกสินค้า
  void _onSelectProductReturn(
    SelectProductReturn event,
    Emitter<ProductReturnSearchState> emit,
  ) {
    _logger.i('Product return selected: ${event.product.itemCode} - ${event.product.itemName}');
    emit(ProductReturnSelected(
      product: event.product,
      products: _products,
    ));
  }

  // รีเซ็ตสินค้าที่เลือก
  void _onResetSelectedProductReturn(
    ResetSelectedProductReturn event,
    Emitter<ProductReturnSearchState> emit,
  ) {
    _logger.i('Reset selected product return');
    emit(ProductReturnSearchLoaded(
      products: _products,
      searchQuery: _searchQuery,
    ));
  }

  // ตั้งค่า search query
  Future<void> _onSetProductReturnSearchQuery(
    SetProductReturnSearchQuery event,
    Emitter<ProductReturnSearchState> emit,
  ) async {
    _logger.i('Set product return search query: ${event.searchQuery}');

    if (_searchQuery != event.searchQuery) {
      emit(ProductReturnSearchLoading());
      try {
        final products = await _productRepository.getProductsReturn(
          search: event.searchQuery,
          custCode: event.custCode,
        );

        _products = products;
        _searchQuery = event.searchQuery;

        emit(ProductReturnSearchLoaded(
          products: products,
          searchQuery: event.searchQuery,
        ));
      } catch (e) {
        _logger.e('Error setting product return search query: $e');
        emit(ProductReturnSearchError(e.toString()));
      }
    }
  }

  // รีเซ็ตสถานะทั้งหมด
  void _onResetProductReturnSearchState(
    ResetProductReturnSearchState event,
    Emitter<ProductReturnSearchState> emit,
  ) {
    _logger.i('Reset product return search state');
    _products = [];
    _searchQuery = '';
    emit(ProductReturnSearchInitial());
  }
}
