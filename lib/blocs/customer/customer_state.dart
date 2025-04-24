import 'package:equatable/equatable.dart';
import 'package:wawa_vansales/data/models/customer_model.dart';

abstract class CustomerState extends Equatable {
  const CustomerState();

  @override
  List<Object?> get props => [];
}

// สถานะเริ่มต้น
class CustomerInitial extends CustomerState {}

// กำลังโหลดข้อมูลลูกค้า
class CustomersLoading extends CustomerState {}

// โหลดข้อมูลลูกค้าสำเร็จ
class CustomersLoaded extends CustomerState {
  final List<CustomerModel> customers;
  final String searchQuery;

  const CustomersLoaded({
    required this.customers,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [customers, searchQuery];
}

// โหลดข้อมูลลูกค้าล้มเหลว
class CustomersError extends CustomerState {
  final String message;

  const CustomersError(this.message);

  @override
  List<Object?> get props => [message];
}

// เลือกลูกค้าแล้ว
class CustomerSelected extends CustomerState {
  final CustomerModel customer;
  final List<CustomerModel> customers;

  const CustomerSelected({
    required this.customer,
    required this.customers,
  });

  @override
  List<Object?> get props => [customer, customers];
}

// กำลังสร้างลูกค้าใหม่
class CustomerCreating extends CustomerState {}

// สร้างลูกค้าใหม่สำเร็จ
class CustomerCreated extends CustomerState {
  final CustomerModel customer;

  const CustomerCreated(this.customer);

  @override
  List<Object?> get props => [customer];
}

// สร้างลูกค้าใหม่ล้มเหลว
class CustomerCreateError extends CustomerState {
  final String message;

  const CustomerCreateError(this.message);

  @override
  List<Object?> get props => [message];
}
