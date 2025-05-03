// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pre_order_history_detail_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PreOrderHistoryDetailModel _$PreOrderHistoryDetailModelFromJson(
        Map<String, dynamic> json) =>
    PreOrderHistoryDetailModel(
      itemCode: json['item_code'] as String,
      itemName: json['item_name'] as String,
      price: json['price'] as String,
      qty: json['qty'] as String,
      unitCode: json['unit_code'] as String,
      shelfCode: json['shelf_code'] as String,
      standValue: json['stand_value'] as String,
      divideValue: json['divide_value'] as String,
      whCode: json['wh_code'] as String,
      ratio: json['ratio'] as String,
    );

Map<String, dynamic> _$PreOrderHistoryDetailModelToJson(
        PreOrderHistoryDetailModel instance) =>
    <String, dynamic>{
      'item_code': instance.itemCode,
      'item_name': instance.itemName,
      'price': instance.price,
      'qty': instance.qty,
      'unit_code': instance.unitCode,
      'shelf_code': instance.shelfCode,
      'stand_value': instance.standValue,
      'divide_value': instance.divideValue,
      'wh_code': instance.whCode,
      'ratio': instance.ratio,
    };
