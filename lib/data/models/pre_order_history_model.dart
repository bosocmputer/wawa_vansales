// /lib/data/models/pre_order_history_model.dart
import 'package:json_annotation/json_annotation.dart';

part 'pre_order_history_model.g.dart';

@JsonSerializable()
class PreOrderHistoryModel {
  @JsonKey(name: 'doc_no', defaultValue: '')
  final String docNo;

  @JsonKey(name: 'doc_date', defaultValue: '')
  final String docDate;

  @JsonKey(name: 'doc_time', defaultValue: '')
  final String docTime;

  @JsonKey(name: 'cust_code', defaultValue: '')
  final String custCode;

  @JsonKey(name: 'cust_name', defaultValue: '')
  final String custName;

  @JsonKey(name: 'total_amount', fromJson: _amountFromJson)
  final double totalAmount;

  @JsonKey(name: 'cash_amount', defaultValue: '0')
  final String cashAmount;

  @JsonKey(name: 'tranfer_amount', defaultValue: '0')
  final String tranferAmount;

  @JsonKey(name: 'card_amount', defaultValue: '0')
  final String cardAmount;

  @JsonKey(name: 'wallet_amount', defaultValue: '0')
  final String walletAmount;

  @JsonKey(name: 'total_credit_charge', defaultValue: '0')
  final String? totalCreditCharge;

  @JsonKey(name: 'total_net_amount', defaultValue: '0')
  final String? totalNetAmount;

  @JsonKey(name: 'total_amount_pay', defaultValue: '0')
  final String? totalAmountPay;

  @JsonKey(name: 'balance_amount', defaultValue: '0')
  final String? balanceAmount;

  @JsonKey(name: 'transfer_ref', defaultValue: '')
  final String? transferRef;

  const PreOrderHistoryModel({
    required this.docNo,
    required this.docDate,
    this.docTime = '',
    required this.custCode,
    required this.custName,
    required this.totalAmount,
    this.cashAmount = '0',
    this.tranferAmount = '0',
    this.cardAmount = '0',
    this.walletAmount = '0',
    this.totalCreditCharge,
    this.totalNetAmount,
    this.totalAmountPay,
    this.balanceAmount,
    this.transferRef,
  });

  // คำนวณยอดรวมในรูปแบบ double
  double get amount => totalAmount;

  // คำนวณยอด wallet payment ในรูปแบบ double
  double get walletAmountValue => double.tryParse(walletAmount) ?? 0.0;

  // คำนวณยอดลดหนี้ในรูปแบบ double
  double get balanceAmountValue => double.tryParse(balanceAmount ?? '0') ?? 0.0;

  factory PreOrderHistoryModel.fromJson(Map<String, dynamic> json) => _$PreOrderHistoryModelFromJson(json);

  Map<String, dynamic> toJson() => _$PreOrderHistoryModelToJson(this);

  // Custom converter for amount
  static double _amountFromJson(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
