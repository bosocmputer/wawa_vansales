// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'return_product_history_detail_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReturnProductHistoryDetailModel _$ReturnProductHistoryDetailModelFromJson(
        Map<String, dynamic> json) =>
    ReturnProductHistoryDetailModel(
      itemCode: json['item_code'] as String,
      standValue: json['stand_value'] as String,
      price: json['price'] as String,
      qty: json['qty'] as String,
      shelfCode: json['shelf_code'] as String,
      unitCode: json['unit_code'] as String,
      itemName: json['item_name'] as String,
      divideValue: json['divide_value'] as String,
      whCode: json['wh_code'] as String,
      ratio: json['ratio'] as String,
    );

Map<String, dynamic> _$ReturnProductHistoryDetailModelToJson(
        ReturnProductHistoryDetailModel instance) =>
    <String, dynamic>{
      'item_code': instance.itemCode,
      'stand_value': instance.standValue,
      'price': instance.price,
      'qty': instance.qty,
      'shelf_code': instance.shelfCode,
      'unit_code': instance.unitCode,
      'item_name': instance.itemName,
      'divide_value': instance.divideValue,
      'wh_code': instance.whCode,
      'ratio': instance.ratio,
    };
