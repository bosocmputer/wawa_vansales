// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReceiptModel _$ReceiptModelFromJson(Map<String, dynamic> json) => ReceiptModel(
      docNo: json['docNo'] as String?,
      date: json['date'] as String?,
      customerName: json['customerName'] as String?,
      customerCode: json['customerCode'] as String?,
      warehouseName: json['warehouseName'] as String?,
      employeeName: json['employeeName'] as String?,
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => SaleItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalAmount: json['totalAmount'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
    );

Map<String, dynamic> _$ReceiptModelToJson(ReceiptModel instance) =>
    <String, dynamic>{
      'docNo': instance.docNo,
      'date': instance.date,
      'customerName': instance.customerName,
      'customerCode': instance.customerCode,
      'warehouseName': instance.warehouseName,
      'employeeName': instance.employeeName,
      'items': instance.items,
      'totalAmount': instance.totalAmount,
      'paymentMethod': instance.paymentMethod,
    };
