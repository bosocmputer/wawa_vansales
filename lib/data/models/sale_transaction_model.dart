// lib/data/models/sale_transaction_model.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:wawa_vansales/data/models/balance_detail_model.dart';
import 'package:wawa_vansales/data/models/cart_item_model.dart';
import 'package:wawa_vansales/data/models/payment_model.dart';

part 'sale_transaction_model.g.dart';

@JsonSerializable()
class SaleTransactionModel {
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

  @JsonKey(name: 'wallet_amount')
  final String walletAmount;

  @JsonKey(name: 'total_amount')
  final String totalAmount;

  @JsonKey(name: 'total_value')
  final String totalValue;

  @JsonKey(name: 'total_credit_charge')
  final String totalCreditCharge;

  @JsonKey(name: 'total_net_amount')
  final String totalNetAmount;

  @JsonKey(name: 'total_amount_pay')
  final String? totalAmountPay;

  // เพิ่มฟิลด์ใหม่สำหรับยอดลดหนี้
  @JsonKey(name: 'balance_amount')
  final String balanceAmount;

  // เพิ่มฟิลด์ใหม่สำหรับรายละเอียดการลดหนี้
  @JsonKey(name: 'balance_detail')
  final List<BalanceDetailModel> balanceDetail;

  final String remark;

  @JsonKey(name: 'car_code')
  final String? carCode;

  @JsonKey(name: 'partial_pay')
  final String? partialPay;

  SaleTransactionModel({
    required this.custCode,
    required this.empCode,
    required this.docDate,
    required this.docTime,
    required this.docNo,
    required this.items,
    required this.paymentDetail,
    required this.transferAmount,
    required this.creditAmount,
    required this.cashAmount,
    required this.cardAmount,
    required this.walletAmount,
    required this.totalAmount,
    required this.totalValue,
    required this.totalCreditCharge,
    required this.totalNetAmount,
    this.totalAmountPay,
    required this.balanceAmount,
    required this.balanceDetail,
    this.remark = '',
    this.carCode,
    this.partialPay = '0', // เพิ่มค่าเริ่มต้นเป็น 0 (ชำระเต็มจำนวน)
  });

  factory SaleTransactionModel.fromJson(Map<String, dynamic> json) => _$SaleTransactionModelFromJson(json);

  Map<String, dynamic> toJson() => _$SaleTransactionModelToJson(this);
}

@JsonSerializable()
class SaleTransactionResponse {
  final bool success;
  final String message;

  SaleTransactionResponse({
    required this.success,
    required this.message,
  });

  factory SaleTransactionResponse.fromJson(Map<String, dynamic> json) => _$SaleTransactionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SaleTransactionResponseToJson(this);
}
