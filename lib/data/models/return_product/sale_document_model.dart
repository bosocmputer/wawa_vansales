// lib/data/models/return_product/sale_document_model.dart
import 'package:json_annotation/json_annotation.dart';

part 'sale_document_model.g.dart';

@JsonSerializable()
class SaleDocumentModel {
  @JsonKey(name: 'doc_no')
  final String docNo;

  @JsonKey(name: 'doc_date')
  final String docDate;

  @JsonKey(name: 'doc_time')
  final String docTime;

  @JsonKey(name: 'cust_code')
  final String custCode;

  @JsonKey(name: 'cust_name')
  final String custName;

  @JsonKey(name: 'total_amount')
  final String totalAmount;

  @JsonKey(name: 'cash_amount')
  String? cashAmount;

  @JsonKey(name: 'card_amount')
  String? cardAmount;

  @JsonKey(name: 'tranfer_amount')
  String? transferAmount;

  SaleDocumentModel({
    required this.docNo,
    required this.docDate,
    required this.docTime,
    required this.custCode,
    required this.custName,
    required this.totalAmount,
    String? cashAmount,
    String? cardAmount,
    String? transferAmount,
  })  : cashAmount = cashAmount ?? '0.00',
        cardAmount = cardAmount ?? '0.00',
        transferAmount = transferAmount ?? '0.00';

  factory SaleDocumentModel.fromJson(Map<String, dynamic> json) => _$SaleDocumentModelFromJson(json);

  Map<String, dynamic> toJson() => _$SaleDocumentModelToJson(this);

  double get totalAmountAsDouble => double.tryParse(totalAmount) ?? 0.0;
}
