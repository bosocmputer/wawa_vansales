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
  });

  // คำนวณยอดรวมในรูปแบบ double
  double get amount => totalAmount;

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
