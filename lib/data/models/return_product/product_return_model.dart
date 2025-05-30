import 'package:json_annotation/json_annotation.dart';

part 'product_return_model.g.dart';

@JsonSerializable()
class ProductReturnModel {
  @JsonKey(name: 'item_code')
  final String itemCode;

  @JsonKey(name: 'item_name')
  final String itemName;

  final String barcode;

  final double price;

  @JsonKey(name: 'unit_code')
  final String unitCode;

  @JsonKey(name: 'stand_value')
  final String standValue;

  @JsonKey(name: 'divide_value')
  final String divideValue;

  final String ratio;

  ProductReturnModel({
    required this.itemCode,
    required this.itemName,
    required this.barcode,
    required this.price,
    required this.unitCode,
    required this.standValue,
    required this.divideValue,
    required this.ratio,
  });

  factory ProductReturnModel.fromJson(Map<String, dynamic> json) => _$ProductReturnModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProductReturnModelToJson(this);
}

@JsonSerializable()
class ProductReturnResponse {
  final bool success;
  final List<ProductReturnModel> data;

  ProductReturnResponse({
    required this.success,
    required this.data,
  });

  factory ProductReturnResponse.fromJson(Map<String, dynamic> json) => _$ProductReturnResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ProductReturnResponseToJson(this);
}
