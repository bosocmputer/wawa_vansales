// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaleItemModel _$SaleItemModelFromJson(Map<String, dynamic> json) =>
    SaleItemModel(
      barcode: json['barcode'] as String?,
      itemCode: json['itemCode'] as String?,
      itemName: json['itemName'] as String?,
      unitCode: json['unitCode'] as String?,
      unitName: json['unitName'] as String?,
      quantity: json['quantity'] as String?,
      price: json['price'] as String?,
    );

Map<String, dynamic> _$SaleItemModelToJson(SaleItemModel instance) =>
    <String, dynamic>{
      'barcode': instance.barcode,
      'itemCode': instance.itemCode,
      'itemName': instance.itemName,
      'unitCode': instance.unitCode,
      'unitName': instance.unitName,
      'quantity': instance.quantity,
      'price': instance.price,
    };
