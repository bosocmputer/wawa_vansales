// lib/data/models/return_product/return_product_model.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:wawa_vansales/data/models/cart_item_model.dart';
import 'package:wawa_vansales/data/models/payment_model.dart';

part 'return_product_model.g.dart';

@JsonSerializable()
class ReturnProductModel {
  @JsonKey(name: 'cust_code')
  final String custCode;

  @JsonKey(name: 'emp_code')
  final String empCode;

  @JsonKey(name: 'doc_date')
  final String docDate;

  @JsonKey(name: 'doc_time')
  final String docTime;

  @JsonKey(name: 'doc_no')
  final String docNo;

  @JsonKey(name: 'ref_doc_date')
  final String refDocDate;

  @JsonKey(name: 'ref_doc_no')
  final String refDocNo;

  @JsonKey(name: 'ref_amount')
  final String refAmount;

  @JsonKey(name: 'items')
  final List<CartItemModel> items;

  @JsonKey(name: 'payment_detail')
  final List<PaymentModel> paymentDetail;

  @JsonKey(name: 'tranfer_amount')
  final String transferAmount;

  @JsonKey(name: 'credit_amount')
  final String creditAmount;

  @JsonKey(name: 'cash_amount')
  final String cashAmount;

  @JsonKey(name: 'card_amount')
  final String cardAmount;

  @JsonKey(name: 'total_amount')
  final String totalAmount;

  @JsonKey(name: 'total_value')
  final String totalValue;

  @JsonKey(name: 'remark')
  final String remark;

  ReturnProductModel({
    required this.custCode,
    required this.empCode,
    required this.docDate,
    required this.docTime,
    required this.docNo,
    required this.refDocDate,
    required this.refDocNo,
    required this.refAmount,
    required this.items,
    required this.paymentDetail,
    required this.transferAmount,
    required this.creditAmount,
    required this.cashAmount,
    required this.cardAmount,
    required this.totalAmount,
    required this.totalValue,
    required this.remark,
  });

  factory ReturnProductModel.fromJson(Map<String, dynamic> json) => _$ReturnProductModelFromJson(json);

  Map<String, dynamic> toJson() => _$ReturnProductModelToJson(this);
}
