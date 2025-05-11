// lib/data/models/ar_balance_model.dart
import 'package:json_annotation/json_annotation.dart';

part 'ar_balance_model.g.dart';

@JsonSerializable()
class ArBalanceModel {
  @JsonKey(name: 'cust_code')
  final String custCode;

  final String balance;

  @JsonKey(name: 'doc_no')
  final String docNo;

  @JsonKey(name: 'doc_date')
  final String docDate;

  @JsonKey(name: 'cust_name')
  final String custName;

  @JsonKey(name: 'trans_flag')
  final String transFlag;

  // ฟิลด์เพิ่มเติมสำหรับการคำนวณ
  double? selectedAmount; // จำนวนเงินที่เลือกใช้ลดหนี้

  ArBalanceModel({
    required this.custCode,
    required this.balance,
    required this.docNo,
    required this.docDate,
    required this.custName,
    required this.transFlag,
    this.selectedAmount,
  });

  // คำนวณยอดเงินที่ใช้ได้
  double get balanceAmount => double.tryParse(balance) ?? 0;

  factory ArBalanceModel.fromJson(Map<String, dynamic> json) => _$ArBalanceModelFromJson(json);

  Map<String, dynamic> toJson() => _$ArBalanceModelToJson(this);
}

@JsonSerializable()
class ArBalanceResponse {
  final bool success;
  final List<ArBalanceModel> data;

  ArBalanceResponse({
    required this.success,
    required this.data,
  });

  factory ArBalanceResponse.fromJson(Map<String, dynamic> json) => _$ArBalanceResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ArBalanceResponseToJson(this);
}