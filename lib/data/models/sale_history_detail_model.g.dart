// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_history_detail_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaleHistoryDetailModel _$SaleHistoryDetailModelFromJson(
        Map<String, dynamic> json) =>
    SaleHistoryDetailModel(
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

Map<String, dynamic> _$SaleHistoryDetailModelToJson(
        SaleHistoryDetailModel instance) =>
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

SaleHistoryDetailResponse _$SaleHistoryDetailResponseFromJson(
        Map<String, dynamic> json) =>
    SaleHistoryDetailResponse(
      success: json['success'] as bool,
      data: (json['data'] as List<dynamic>)
          .map(
              (e) => SaleHistoryDetailModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SaleHistoryDetailResponseToJson(
        SaleHistoryDetailResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
    };
