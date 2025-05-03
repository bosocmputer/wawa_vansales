// lib/blocs/return_product/return_product_event.dart
import 'package:equatable/equatable.dart';
import 'package:wawa_vansales/data/models/cart_item_model.dart';
import 'package:wawa_vansales/data/models/customer_model.dart';
import 'package:wawa_vansales/data/models/payment_model.dart';
import 'package:wawa_vansales/data/models/return_product/sale_document_model.dart';

abstract class ReturnProductEvent extends Equatable {
  const ReturnProductEvent();

  @override
  List<Object?> get props => [];
}

// เลือกลูกค้า
class SelectCustomerForReturn extends ReturnProductEvent {
  final CustomerModel customer;

  const SelectCustomerForReturn(this.customer);

  @override
  List<Object?> get props => [customer];
}

// ดึงรายการเอกสารขาย
class FetchSaleDocuments extends ReturnProductEvent {
  final String customerCode;
  final String search;
  final String fromDate;
  final String toDate;

  const FetchSaleDocuments({
    required this.customerCode,
    this.search = '',
    required this.fromDate,
    required this.toDate,
  });

  @override
  List<Object?> get props => [customerCode, search, fromDate, toDate];
}

// เลือกเอกสารขาย
class SelectSaleDocument extends ReturnProductEvent {
  final SaleDocumentModel saleDocument;

  const SelectSaleDocument(this.saleDocument);

  @override
  List<Object?> get props => [saleDocument];
}

// ดึงรายละเอียดเอกสารขาย
class FetchSaleDocumentDetails extends ReturnProductEvent {
  final String docNo;

  const FetchSaleDocumentDetails(this.docNo);

  @override
  List<Object?> get props => [docNo];
}

// เพิ่มสินค้าเข้าตะกร้ารับคืน
class AddItemToReturnCart extends ReturnProductEvent {
  final CartItemModel item;

  const AddItemToReturnCart(this.item);

  @override
  List<Object?> get props => [item];
}

// ลบสินค้าออกจากตะกร้ารับคืน
class RemoveItemFromReturnCart extends ReturnProductEvent {
  final String itemCode;
  final String barcode;
  final String unitCode;

  const RemoveItemFromReturnCart({
    required this.itemCode,
    required this.barcode,
    required this.unitCode,
  });

  @override
  List<Object?> get props => [itemCode, barcode, unitCode];
}

// อัพเดทจำนวนสินค้า
class UpdateReturnItemQuantity extends ReturnProductEvent {
  final String itemCode;
  final String barcode;
  final String unitCode;
  final double quantity;

  const UpdateReturnItemQuantity({
    required this.itemCode,
    required this.barcode,
    required this.unitCode,
    required this.quantity,
  });

  @override
  List<Object?> get props => [itemCode, barcode, unitCode, quantity];
}

// ล้างตะกร้า
class ClearReturnCart extends ReturnProductEvent {}

// รีเซ็ตสถานะทั้งหมด (ล้างตะกร้าและข้อมูลลูกค้า)
class ResetReturnProductState extends ReturnProductEvent {}

// เพิ่มการชำระเงิน
class AddReturnPayment extends ReturnProductEvent {
  final PaymentModel payment;

  const AddReturnPayment(this.payment);

  @override
  List<Object?> get props => [payment];
}

// ลบการชำระเงิน
class RemoveReturnPayment extends ReturnProductEvent {
  final PaymentType paymentType;

  const RemoveReturnPayment(this.paymentType);

  @override
  List<Object?> get props => [paymentType];
}

// บันทึกการรับคืน
class SubmitReturn extends ReturnProductEvent {
  final String remark;
  final String docNo;

  const SubmitReturn({this.remark = '', required this.docNo});

  @override
  List<Object?> get props => [remark, docNo];
}

// อัปเดต step
class UpdateReturnStep extends ReturnProductEvent {
  final int step;

  const UpdateReturnStep(this.step);

  @override
  List<Object?> get props => [step];
}
