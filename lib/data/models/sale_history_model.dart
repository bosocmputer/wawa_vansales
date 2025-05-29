import 'package:json_annotation/json_annotation.dart';

part 'sale_history_model.g.dart';

@JsonSerializable()
class SaleHistoryModel {
  @JsonKey(name: 'cust_code')
  final String custCode;

  @JsonKey(name: 'total_amount')
  final String totalAmount;

  @JsonKey(name: 'doc_no')
  final String docNo;

  @JsonKey(name: 'doc_date')
  final String docDate;

  @JsonKey(name: 'cust_name')
  final String custName;

  @JsonKey(name: 'doc_time')
  final String docTime;

  @JsonKey(name: 'cash_amount')
  final String? cashAmount;

  @JsonKey(name: 'tranfer_amount')
  final String? tranferAmount;

  @JsonKey(name: 'card_amount')
  final String? cardAmount;

  @JsonKey(name: 'total_credit_charge')
  final String? totalCreditCharge;

  @JsonKey(name: 'total_net_amount')
  final String? totalNetAmount;

  @JsonKey(name: 'total_amount_pay')
  final String? totalAmountPay;

  @JsonKey(name: 'wallet_amount')
  final String? walletAmount;

  SaleHistoryModel({
    required this.custCode,
    required this.totalAmount,
    required this.docNo,
    required this.docDate,
    required this.custName,
    required this.docTime,
    this.cashAmount,
    this.tranferAmount,
    this.cardAmount,
    this.totalCreditCharge,
    this.totalNetAmount,
    this.totalAmountPay,
    this.walletAmount,
  });

  factory SaleHistoryModel.fromJson(Map<String, dynamic> json) => _$SaleHistoryModelFromJson(json);

  Map<String, dynamic> toJson() => _$SaleHistoryModelToJson(this);

  // Get total amount as double
  double get totalAmountValue => double.tryParse(totalAmount) ?? 0.0;

  // Get total credit charge as double
  double get totalCreditChargeValue => double.tryParse(totalCreditCharge ?? '0') ?? 0.0;

  // Get total net amount as double
  double get totalNetAmountValue => double.tryParse(totalNetAmount ?? totalAmount) ?? totalAmountValue;

  // Get total amount pay as double
  double get totalAmountPayValue => double.tryParse(totalAmountPay ?? totalAmount) ?? totalAmountValue;

  // Get wallet amount as double (QR Code)
  double get walletAmountValue => double.tryParse(walletAmount ?? '0') ?? 0.0;
}

@JsonSerializable()
class SaleHistoryResponse {
  final bool success;
  final List<SaleHistoryModel> data;

  SaleHistoryResponse({
    required this.success,
    required this.data,
  });

  factory SaleHistoryResponse.fromJson(Map<String, dynamic> json) => _$SaleHistoryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SaleHistoryResponseToJson(this);
}
