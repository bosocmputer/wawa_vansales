import 'package:equatable/equatable.dart';
import 'package:wawa_vansales/data/models/customer_model.dart';

abstract class CustomerEvent extends Equatable {
  const CustomerEvent();

  @override
  List<Object?> get props => [];
}

// ดึงรายการลูกค้า
class FetchCustomers extends CustomerEvent {
  final String searchQuery;

  const FetchCustomers({this.searchQuery = ''});

  @override
  List<Object?> get props => [searchQuery];
}

// เลือกลูกค้า
class SelectCustomer extends CustomerEvent {
  final CustomerModel customer;

  const SelectCustomer(this.customer);

  @override
  List<Object?> get props => [customer];
}

// สร้างลูกค้าใหม่
class CreateCustomer extends CustomerEvent {
  final CustomerModel customer;

  const CreateCustomer(this.customer);

  @override
  List<Object?> get props => [customer];
}

// รีเซ็ตสถานะลูกค้าที่เลือก
class ResetSelectedCustomer extends CustomerEvent {}

// กำหนดคำค้นหา
class SetSearchQuery extends CustomerEvent {
  final String query;

  const SetSearchQuery(this.query);

  @override
  List<Object?> get props => [query];
}
