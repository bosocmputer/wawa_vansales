// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_return_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductReturnModel _$ProductReturnModelFromJson(Map<String, dynamic> json) =>
    ProductReturnModel(
      itemCode: json['item_code'] as String,
      itemName: json['item_name'] as String,
      barcode: json['barcode'] as String,
      price: (json['price'] as num).toDouble(),
      unitCode: json['unit_code'] as String,
      standValue: json['stand_value'] as String,
      divideValue: json['divide_value'] as String,
      ratio: json['ratio'] as String,
    );

Map<String, dynamic> _$ProductReturnModelToJson(ProductReturnModel instance) =>
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

ProductReturnResponse _$ProductReturnResponseFromJson(
        Map<String, dynamic> json) =>
    ProductReturnResponse(
      success: json['success'] as bool,
      data: (json['data'] as List<dynamic>)
          .map((e) => ProductReturnModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ProductReturnResponseToJson(
        ProductReturnResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
    };
