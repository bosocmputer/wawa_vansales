// lib/data/models/return_product/return_product_history_detail_model.dart
import 'package:json_annotation/json_annotation.dart';

part 'return_product_history_detail_model.g.dart';

@JsonSerializable()
class ReturnProductHistoryDetailModel {
  @JsonKey(name: 'item_code')
  final String itemCode;

  @JsonKey(name: 'stand_value')
  final String standValue;

  @JsonKey(name: 'price')
  final String price;

  @JsonKey(name: 'qty')
  final String qty;

  @JsonKey(name: 'shelf_code')
  final String shelfCode;

  @JsonKey(name: 'unit_code')
  final String unitCode;

  @JsonKey(name: 'item_name')
  final String itemName;

  @JsonKey(name: 'divide_value')
  final String divideValue;

  @JsonKey(name: 'wh_code')
  final String whCode;

  @JsonKey(name: 'ratio')
  final String ratio;

  // เพิ่มคำนวณราคารวม
  double get totalAmount => (double.tryParse(price) ?? 0) * (double.tryParse(qty) ?? 0);

  ReturnProductHistoryDetailModel({
    required this.itemCode,
    required this.standValue,
    required this.price,
    required this.qty,
    required this.shelfCode,
    required this.unitCode,
    required this.itemName,
    required this.divideValue,
    required this.whCode,
    required this.ratio,
  });

  factory ReturnProductHistoryDetailModel.fromJson(Map<String, dynamic> json) => _$ReturnProductHistoryDetailModelFromJson(json);

  Map<String, dynamic> toJson() => _$ReturnProductHistoryDetailModelToJson(this);
}
