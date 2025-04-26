// lib/data/models/product_detail_model.dart
import 'package:json_annotation/json_annotation.dart';

part 'product_detail_model.g.dart';

@JsonSerializable()
class ProductDetailModel {
  @JsonKey(name: 'item_code')
  final String itemCode;

  @JsonKey(name: 'item_name')
  final String itemName;

  final String barcode;

  final String price;

  @JsonKey(name: 'unit_code')
  final String unitCode;

  @JsonKey(name: 'stand_value')
  final String standValue;

  @JsonKey(name: 'divide_value')
  final String divideValue;

  final String ratio;

  ProductDetailModel({
    required this.itemCode,
    required this.itemName,
    required this.barcode,
    required this.price,
    required this.unitCode,
    required this.standValue,
    required this.divideValue,
    required this.ratio,
  });

  factory ProductDetailModel.fromJson(Map<String, dynamic> json) => _$ProductDetailModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductDetailModelToJson(this);
}

@JsonSerializable()
class ProductDetailResponse {
  final bool success;
  final List<ProductDetailModel> data;

  ProductDetailResponse({
    required this.success,
    required this.data,
  });

  factory ProductDetailResponse.fromJson(Map<String, dynamic> json) => _$ProductDetailResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ProductDetailResponseToJson(this);
}
