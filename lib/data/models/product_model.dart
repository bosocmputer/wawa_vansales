import 'package:json_annotation/json_annotation.dart';

part 'product_model.g.dart';

@JsonSerializable()
class ProductModel {
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

  ProductModel({
    required this.itemCode,
    required this.itemName,
    required this.barcode,
    required this.price,
    required this.unitCode,
    required this.standValue,
    required this.divideValue,
    required this.ratio,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) => _$ProductModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProductModelToJson(this);
}

@JsonSerializable()
class ProductResponse {
  final bool success;
  final List<ProductModel> data;

  ProductResponse({
    required this.success,
    required this.data,
  });

  factory ProductResponse.fromJson(Map<String, dynamic> json) => _$ProductResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ProductResponseToJson(this);
}
