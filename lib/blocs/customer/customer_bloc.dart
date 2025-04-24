import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:wawa_vansales/blocs/customer/customer_event.dart';
import 'package:wawa_vansales/blocs/customer/customer_state.dart';
import 'package:wawa_vansales/data/models/customer_model.dart';
import 'package:wawa_vansales/data/repositories/customer_repository.dart';

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final CustomerRepository _customerRepository;
  final Logger _logger = Logger();

  // เก็บรายการลูกค้าและลูกค้าที่เลือก
  List<CustomerModel> _customers = [];
  String _searchQuery = '';

  CustomerBloc({required CustomerRepository customerRepository})
      : _customerRepository = customerRepository,
        super(CustomerInitial()) {
    on<FetchCustomers>(_onFetchCustomers);
    on<SelectCustomer>(_onSelectCustomer);
    on<CreateCustomer>(_onCreateCustomer);
    on<ResetSelectedCustomer>(_onResetSelectedCustomer);
    on<SetSearchQuery>(_onSetSearchQuery);
  }

  // ดึงรายการลูกค้า
  Future<void> _onFetchCustomers(
    FetchCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    _logger.i('Fetching customers with search: ${event.searchQuery}');
    emit(CustomersLoading());

    try {
      final customers = await _customerRepository.getCustomers(
        search: event.searchQuery,
      );

      _customers = customers;
      _searchQuery = event.searchQuery;

      _logger.i('Fetched ${customers.length} customers');
      emit(CustomersLoaded(
        customers: customers,
        searchQuery: event.searchQuery,
      ));
    } catch (e) {
      _logger.e('Error fetching customers: $e');
      emit(CustomersError(e.toString()));
    }
  }

  // เลือกลูกค้า
  void _onSelectCustomer(
    SelectCustomer event,
    Emitter<CustomerState> emit,
  ) {
    _logger.i('Customer selected: ${event.customer.code} - ${event.customer.name}');
    emit(CustomerSelected(
      customer: event.customer,
      customers: _customers,
    ));
  }

  // รีเซ็ตลูกค้าที่เลือก
  void _onResetSelectedCustomer(
    ResetSelectedCustomer event,
    Emitter<CustomerState> emit,
  ) {
    _logger.i('Reset selected customer');
    emit(CustomersLoaded(
      customers: _customers,
      searchQuery: _searchQuery,
    ));
  }

  // สร้างลูกค้าใหม่
  Future<void> _onCreateCustomer(
    CreateCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    _logger.i('Creating new customer: ${event.customer.code} - ${event.customer.name}');
    emit(CustomerCreating());

    try {
      final success = await _customerRepository.createCustomer(event.customer);

      if (success) {
        _logger.i('Customer created successfully');

        // เพิ่มลูกค้าใหม่เข้าไปในรายการ
        _customers = [event.customer, ..._customers];

        emit(CustomerCreated(event.customer));

        // อัพเดท state เป็น CustomersLoaded หลังจากสร้างลูกค้าเสร็จ
        emit(CustomersLoaded(
          customers: _customers,
          searchQuery: _searchQuery,
        ));
      } else {
        _logger.e('Failed to create customer');
        emit(const CustomerCreateError('ไม่สามารถสร้างลูกค้าใหม่ได้'));
      }
    } catch (e) {
      _logger.e('Error creating customer: $e');
      emit(CustomerCreateError(e.toString()));
    }
  }

  // กำหนดคำค้นหา
  void _onSetSearchQuery(
    SetSearchQuery event,
    Emitter<CustomerState> emit,
  ) {
    _logger.i('Set search query: ${event.query}');
    _searchQuery = event.query;

    // เรียก fetch customers ด้วยคำค้นหาใหม่
    add(FetchCustomers(searchQuery: event.query));
  }
}
