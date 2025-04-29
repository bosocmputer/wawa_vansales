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

  SaleHistoryModel({
    required this.custCode,
    required this.totalAmount,
    required this.docNo,
    required this.docDate,
    required this.custName,
    required this.docTime,
  });

  factory SaleHistoryModel.fromJson(Map<String, dynamic> json) => _$SaleHistoryModelFromJson(json);

  Map<String, dynamic> toJson() => _$SaleHistoryModelToJson(this);

  // Get total amount as double
  double get totalAmountValue => double.tryParse(totalAmount) ?? 0.0;
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
