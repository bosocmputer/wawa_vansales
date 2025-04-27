// lib/blocs/cart/cart_event.dart
import 'package:equatable/equatable.dart';
import 'package:wawa_vansales/data/models/cart_item_model.dart';
import 'package:wawa_vansales/data/models/customer_model.dart';
import 'package:wawa_vansales/data/models/payment_model.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

// เลือกลูกค้า
class SelectCustomerForCart extends CartEvent {
  final CustomerModel customer;

  const SelectCustomerForCart(this.customer);

  @override
  List<Object?> get props => [customer];
}

// เพิ่มสินค้าเข้าตะกร้า
class AddItemToCart extends CartEvent {
  final CartItemModel item;

  const AddItemToCart(this.item);

  @override
  List<Object?> get props => [item];
}

// ลบสินค้าออกจากตะกร้า
class RemoveItemFromCart extends CartEvent {
  final String itemCode;

  const RemoveItemFromCart(this.itemCode);

  @override
  List<Object?> get props => [itemCode];
}

// อัพเดทจำนวนสินค้า
class UpdateItemQuantity extends CartEvent {
  final String itemCode;
  final double quantity;

  const UpdateItemQuantity(this.itemCode, this.quantity);

  @override
  List<Object?> get props => [itemCode, quantity];
}

// ล้างตะกร้า
class ClearCart extends CartEvent {}

// เพิ่มการชำระเงิน
class AddPayment extends CartEvent {
  final PaymentModel payment;

  const AddPayment(this.payment);

  @override
  List<Object?> get props => [payment];
}

// ลบการชำระเงิน
class RemovePayment extends CartEvent {
  final PaymentType paymentType;

  const RemovePayment(this.paymentType);

  @override
  List<Object?> get props => [paymentType];
}

// บันทึกการขาย
class SubmitSale extends CartEvent {
  final String remark;

  const SubmitSale({this.remark = ''});

  @override
  List<Object?> get props => [remark];
}

// อัปเดต step
class UpdateStep extends CartEvent {
  final int step;

  const UpdateStep(this.step);

  @override
  List<Object?> get props => [step];
}
