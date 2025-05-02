// /lib/data/models/pre_order_history_detail_model.dart
import 'package:json_annotation/json_annotation.dart';

part 'pre_order_history_detail_model.g.dart';

@JsonSerializable()
class PreOrderHistoryDetailModel {
  @JsonKey(name: 'item_code')
  final String itemCode;

  @JsonKey(name: 'item_name')
  final String itemName;

  @JsonKey(name: 'price')
  final String price;

  @JsonKey(name: 'qty')
  final String qty;

  @JsonKey(name: 'unit_code')
  final String unitCode;

  @JsonKey(name: 'shelf_code')
  final String shelfCode;

  @JsonKey(name: 'stand_value')
  final String standValue;

  @JsonKey(name: 'divide_value')
  final String divideValue;

  @JsonKey(name: 'wh_code')
  final String whCode;

  @JsonKey(name: 'ratio')
  final String ratio;

  PreOrderHistoryDetailModel({
    required this.itemCode,
    required this.itemName,
    required this.price,
    required this.qty,
    required this.unitCode,
    required this.shelfCode,
    required this.standValue,
    required this.divideValue,
    required this.whCode,
    required this.ratio,
  });

  factory PreOrderHistoryDetailModel.fromJson(Map<String, dynamic> json) => _$PreOrderHistoryDetailModelFromJson(json);

  Map<String, dynamic> toJson() => _$PreOrderHistoryDetailModelToJson(this);
}
