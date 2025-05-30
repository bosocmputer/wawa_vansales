// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_balance_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductBalanceModel _$ProductBalanceModelFromJson(Map<String, dynamic> json) =>
    ProductBalanceModel(
      itemCode: json['item_code'] as String,
      itemName: json['item_name'] as String,
      whCode: json['wh_code'] as String,
      whName: json['wh_name'] as String,
      shelfCode: json['shelf_code'] as String,
      shelfName: json['shelf_name'] as String,
      barcode: json['barcode'] as String,
      unitCode: json['unit_code'] as String,
      balanceQty: json['balance_qty'] as String,
      price: json['price'] as String,
      qtyWord: json['qty_word'] as String,
    );

Map<String, dynamic> _$ProductBalanceModelToJson(
        ProductBalanceModel instance) =>
    <String, dynamic>{
      'item_code': instance.itemCode,
      'item_name': instance.itemName,
      'wh_code': instance.whCode,
      'wh_name': instance.whName,
      'shelf_code': instance.shelfCode,
      'shelf_name': instance.shelfName,
      'barcode': instance.barcode,
      'unit_code': instance.unitCode,
      'balance_qty': instance.balanceQty,
      'price': instance.price,
      'qty_word': instance.qtyWord,
    };

ProductBalanceResponse _$ProductBalanceResponseFromJson(
        Map<String, dynamic> json) =>
    ProductBalanceResponse(
      success: json['success'] as bool,
      data: (json['data'] as List<dynamic>)
          .map((e) => ProductBalanceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ProductBalanceResponseToJson(
        ProductBalanceResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
    };
