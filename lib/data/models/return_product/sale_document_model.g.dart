// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_document_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaleDocumentModel _$SaleDocumentModelFromJson(Map<String, dynamic> json) =>
    SaleDocumentModel(
      docNo: json['doc_no'] as String,
      docDate: json['doc_date'] as String,
      docTime: json['doc_time'] as String,
      custCode: json['cust_code'] as String,
      custName: json['cust_name'] as String,
      totalAmount: json['total_amount'] as String,
      cashAmount: json['cash_amount'] as String,
      cardAmount: json['card_amount'] as String,
      transferAmount: json['tranfer_amount'] as String,
    );

Map<String, dynamic> _$SaleDocumentModelToJson(SaleDocumentModel instance) =>
    <String, dynamic>{
      'doc_no': instance.docNo,
      'doc_date': instance.docDate,
      'doc_time': instance.docTime,
      'cust_code': instance.custCode,
      'cust_name': instance.custName,
      'total_amount': instance.totalAmount,
      'cash_amount': instance.cashAmount,
      'card_amount': instance.cardAmount,
      'tranfer_amount': instance.transferAmount,
    };
