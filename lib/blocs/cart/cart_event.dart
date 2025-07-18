// lib/blocs/cart/cart_event.dart
import 'package:equatable/equatable.dart';
import 'package:wawa_vansales/data/models/balance_detail_model.dart';
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

// เพิ่มสินค้าหลายรายการพร้อมกัน
class AddItemsToCart extends CartEvent {
  final List<CartItemModel> items;

  const AddItemsToCart(this.items);

  @override
  List<Object?> get props => [items];
}

// ลบสินค้าออกจากตะกร้า
class RemoveItemFromCart extends CartEvent {
  final String itemCode;
  final String barcode;
  final String unitCode;

  const RemoveItemFromCart({
    required this.itemCode,
    required this.barcode,
    required this.unitCode,
  });

  @override
  List<Object?> get props => [itemCode, barcode, unitCode];
}

// อัพเดทจำนวนสินค้า
class UpdateItemQuantity extends CartEvent {
  final String itemCode;
  final String barcode;
  final String unitCode;
  final double quantity;

  const UpdateItemQuantity({
    required this.itemCode,
    required this.barcode,
    required this.unitCode,
    required this.quantity,
  });

  @override
  List<Object?> get props => [itemCode, barcode, unitCode, quantity];
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

// รีเซ็ตสถานะทั้งหมดของ Cart
class ResetCartState extends CartEvent {}

// Event สำหรับตั้งค่าเอกสารพรีออเดอร์
class SetPreOrderDocument extends CartEvent {
  final String docNo;

  const SetPreOrderDocument(this.docNo);

  @override
  List<Object?> get props => [docNo];
}

// Event สำหรับตั้งค่าเลขที่เอกสาร
class SetDocumentNumber extends CartEvent {
  final String documentNumber;

  const SetDocumentNumber(this.documentNumber);

  @override
  List<Object?> get props => [documentNumber];
}

// Event สำหรับอัปเดตรายละเอียดการชำระเงินทั้งหมด (รวมค่าธรรมเนียมบัตรเครดิต)
class UpdatePaymentDetails extends CartEvent {
  final List<PaymentModel> payments;

  const UpdatePaymentDetails(this.payments);

  @override
  List<Object?> get props => [payments];
}

// Event สำหรับเพิ่มรายการลดหนี้
class AddBalanceDetail extends CartEvent {
  final BalanceDetailModel balanceDetail;

  const AddBalanceDetail(this.balanceDetail);

  @override
  List<Object?> get props => [balanceDetail];
}

// Event สำหรับอัปเดตรายการลดหนี้ทั้งหมด
class UpdateBalanceDetails extends CartEvent {
  final List<BalanceDetailModel> balanceDetails;
  final double totalBalanceAmount;

  const UpdateBalanceDetails({
    required this.balanceDetails,
    required this.totalBalanceAmount,
  });

  @override
  List<Object?> get props => [balanceDetails, totalBalanceAmount];
}

// Event สำหรับอัพเดตสถานะการชำระเงินบางส่วน
class UpdatePartialPayStatus extends CartEvent {
  final String partialPayStatus; // "0" = ชำระเต็มจำนวน, "1" = ชำระบางส่วน

  const UpdatePartialPayStatus(this.partialPayStatus);

  @override
  List<Object?> get props => [partialPayStatus];
}

// Event สำหรับตั้งค่ายอด total_amount จาก API getDocPreSaleList (ใช้สำหรับขั้นตอนชำระเงิน)
class SetPreOrderApiTotalAmount extends CartEvent {
  final double totalAmount;

  const SetPreOrderApiTotalAmount(this.totalAmount);

  @override
  List<Object?> get props => [totalAmount];
}
