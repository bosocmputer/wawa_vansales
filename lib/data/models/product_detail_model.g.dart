// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_detail_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductDetailModel _$ProductDetailModelFromJson(Map<String, dynamic> json) =>
    ProductDetailModel(
      itemCode: json['item_code'] as String,
      itemName: json['item_name'] as String,
      barcode: json['barcode'] as String,
      price: json['price'] as String,
      unitCode: json['unit_code'] as String,
      standValue: json['stand_value'] as String,
      divideValue: json['divide_value'] as String,
      ratio: json['ratio'] as String,
    );

Map<String, dynamic> _$ProductDetailModelToJson(ProductDetailModel instance) =>
    <String, dynamic>{
      'item_code': instance.itemCode,
      'item_name': instance.itemName,
      'barcode': instance.barcode,
      'price': instance.price,
      'unit_code': instance.unitCode,
      'stand_value': instance.standValue,
      'divide_value': instance.divideValue,
      'ratio': instance.ratio,
    };

ProductDetailResponse _$ProductDetailResponseFromJson(
        Map<String, dynamic> json) =>
    ProductDetailResponse(
      success: json['success'] as bool,
      data: (json['data'] as List<dynamic>)
          .map((e) => ProductDetailModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ProductDetailResponseToJson(
        ProductDetailResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
    };
