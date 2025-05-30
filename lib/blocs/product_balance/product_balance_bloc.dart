import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:wawa_vansales/blocs/product_balance/product_balance_event.dart';
import 'package:wawa_vansales/blocs/product_balance/product_balance_state.dart';
import 'package:wawa_vansales/data/repositories/product_repository.dart';

class ProductBalanceBloc extends Bloc<ProductBalanceEvent, ProductBalanceState> {
  final ProductRepository _productRepository;
  final Logger _logger = Logger();

  ProductBalanceBloc({required ProductRepository productRepository})
      : _productRepository = productRepository,
        super(ProductBalanceInitial()) {
    on<FetchProductBalance>(_onFetchProductBalance);
    on<ResetProductBalanceState>(_onResetProductBalanceState);
    on<SetProductBalanceSearchQuery>(_onSetProductBalanceSearchQuery);
  }

  // ดึงข้อมูลยอดสินค้าคงเหลือ
  Future<void> _onFetchProductBalance(
    FetchProductBalance event,
    Emitter<ProductBalanceState> emit,
  ) async {
    _logger.i('Fetching product balance with search: ${event.searchQuery}');
    emit(ProductBalanceLoading());

    try {
      final balances = await _productRepository.getBalanceWarehouse(
        search: event.searchQuery,
        whCode: event.whCode,
        shelfCode: event.shelfCode,
      );

      _logger.i('Fetched ${balances.length} product balances');
      emit(ProductBalanceLoaded(
        balances: balances,
        searchQuery: event.searchQuery,
      ));
    } catch (e) {
      _logger.e('Error fetching product balances: $e');
      emit(ProductBalanceError(e.toString()));
    }
  }

  // รีเซ็ตสถานะทั้งหมด
  void _onResetProductBalanceState(
    ResetProductBalanceState event,
    Emitter<ProductBalanceState> emit,
  ) {
    _logger.i('Reset entire product balance state');
    emit(ProductBalanceInitial());
  }

  // กำหนดคำค้นหา
  void _onSetProductBalanceSearchQuery(
    SetProductBalanceSearchQuery event,
    Emitter<ProductBalanceState> emit,
  ) {
    _logger.i('Set product balance search query: ${event.query}');

    // เรียก fetch product balances ด้วยคำค้นหาใหม่
    add(FetchProductBalance(
      searchQuery: event.query,
      whCode: event.whCode,
      shelfCode: event.shelfCode,
    ));
  }
}
