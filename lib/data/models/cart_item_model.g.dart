// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CartItemModel _$CartItemModelFromJson(Map<String, dynamic> json) =>
    CartItemModel(
      itemCode: json['item_code'] as String,
      itemName: json['item_name'] as String,
      barcode: json['barcode'] as String,
      price: json['price'] as String,
      sumAmount: json['sum_amount'] as String,
      unitCode: json['unit_code'] as String,
      whCode: json['wh_code'] as String,
      shelfCode: json['shelf_code'] as String,
      ratio: json['ratio'] as String,
      standValue: json['stand_value'] as String,
      divideValue: json['divide_value'] as String,
      qty: json['qty'] as String? ?? '1',
      refRow: json['ref_row'] as String? ?? '',
    );

Map<String, dynamic> _$CartItemModelToJson(CartItemModel instance) =>
    <String, dynamic>{
      'item_code': instance.itemCode,
      'item_name': instance.itemName,
      'barcode': instance.barcode,
      'price': instance.price,
      'sum_amount': instance.sumAmount,
      'unit_code': instance.unitCode,
      'wh_code': instance.whCode,
      'shelf_code': instance.shelfCode,
      'ratio': instance.ratio,
      'stand_value': instance.standValue,
      'divide_value': instance.divideValue,
      'ref_row': instance.refRow,
      'qty': instance.qty,
    };
