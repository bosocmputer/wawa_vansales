// lib/data/models/balance_detail_model.dart
import 'package:json_annotation/json_annotation.dart';

part 'balance_detail_model.g.dart';

@JsonSerializable()
class BalanceDetailModel {
  @JsonKey(name: 'trans_flag')
  final String transFlag;

  @JsonKey(name: 'doc_no')
  final String docNo;

  @JsonKey(name: 'doc_date')
  final String docDate;

  final String amount;

  @JsonKey(name: 'balance_ref')
  final String balanceRef;

  BalanceDetailModel({
    required this.transFlag,
    required this.docNo,
    required this.docDate,
    required this.amount,
    required this.balanceRef,
  });

  // แปลง string เป็น double
  double get amountValue => double.tryParse(amount) ?? 0.0;

  // แปลง string เป็น double
  double get balanceRefValue => double.tryParse(balanceRef) ?? 0.0;

  factory BalanceDetailModel.fromJson(Map<String, dynamic> json) => _$BalanceDetailModelFromJson(json);

  Map<String, dynamic> toJson() => _$BalanceDetailModelToJson(this);
}

@JsonSerializable()
class BalanceDetailResponse {
  final bool success;
  final List<BalanceDetailModel> data;

  BalanceDetailResponse({
    required this.success,
    required this.data,
  });

  factory BalanceDetailResponse.fromJson(Map<String, dynamic> json) => _$BalanceDetailResponseFromJson(json);

  Map<String, dynamic> toJson() => _$BalanceDetailResponseToJson(this);
}
