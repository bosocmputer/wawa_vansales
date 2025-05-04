// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'return_product_history_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReturnProductHistoryModel _$ReturnProductHistoryModelFromJson(
        Map<String, dynamic> json) =>
    ReturnProductHistoryModel(
      custCode: json['cust_code'] as String,
      docNo: json['doc_no'] as String,
      docDate: json['doc_date'] as String,
      custName: json['cust_name'] as String,
      invNo: json['inv_no'] as String,
      docTime: json['doc_time'] as String,
    );

Map<String, dynamic> _$ReturnProductHistoryModelToJson(
        ReturnProductHistoryModel instance) =>
    <String, dynamic>{
      'cust_code': instance.custCode,
      'doc_no': instance.docNo,
      'doc_date': instance.docDate,
      'cust_name': instance.custName,
      'inv_no': instance.invNo,
      'doc_time': instance.docTime,
    };
