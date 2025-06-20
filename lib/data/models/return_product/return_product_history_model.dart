// lib/data/models/return_product/return_product_history_model.dart
import 'package:json_annotation/json_annotation.dart';

part 'return_product_history_model.g.dart';

@JsonSerializable()
class ReturnProductHistoryModel {
  @JsonKey(name: 'cust_code')
  final String custCode;

  @JsonKey(name: 'doc_no')
  final String docNo;

  @JsonKey(name: 'doc_date')
  final String docDate;

  @JsonKey(name: 'cust_name')
  final String custName;

  @JsonKey(name: 'remark')
  final String remark;

  @JsonKey(name: 'inv_no')
  final String invNo;

  @JsonKey(name: 'doc_time')
  final String docTime;

  @JsonKey(name: 'total_amount')
  final String totalAmount;

  ReturnProductHistoryModel({
    required this.custCode,
    required this.docNo,
    required this.docDate,
    required this.custName,
    required this.remark,
    required this.invNo,
    required this.docTime,
    required this.totalAmount,
  });

  factory ReturnProductHistoryModel.fromJson(Map<String, dynamic> json) => _$ReturnProductHistoryModelFromJson(json);

  Map<String, dynamic> toJson() => _$ReturnProductHistoryModelToJson(this);
}
