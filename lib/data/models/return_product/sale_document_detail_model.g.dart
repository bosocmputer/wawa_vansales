// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_document_detail_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaleDocumentDetailModel _$SaleDocumentDetailModelFromJson(
        Map<String, dynamic> json) =>
    SaleDocumentDetailModel(
      itemCode: json['item_code'] as String,
      itemName: json['item_name'] as String,
      unitCode: json['unit_code'] as String,
      price: json['price'] as String,
      qty: json['qty'] as String,
      whCode: json['wh_code'] as String,
      shelfCode: json['shelf_code'] as String,
      standValue: json['stand_value'] as String,
      divideValue: json['divide_value'] as String,
      ratio: json['ratio'] as String,
      refRow: json['ref_row'] as String? ?? '',
      balanceQty: json['balance_qty'] as String? ?? '0',
      returnQty: json['return_qty'] as String? ?? '0',
    );

Map<String, dynamic> _$SaleDocumentDetailModelToJson(
        SaleDocumentDetailModel instance) =>
    <String, dynamic>{
      'item_code': instance.itemCode,
      'item_name': instance.itemName,
      'unit_code': instance.unitCode,
      'price': instance.price,
      'qty': instance.qty,
      'wh_code': instance.whCode,
      'shelf_code': instance.shelfCode,
      'stand_value': instance.standValue,
      'divide_value': instance.divideValue,
      'ratio': instance.ratio,
      'ref_row': instance.refRow,
      'balance_qty': instance.balanceQty,
      'return_qty': instance.returnQty,
    };
