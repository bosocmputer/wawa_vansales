// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_history_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaleHistoryModel _$SaleHistoryModelFromJson(Map<String, dynamic> json) =>
    SaleHistoryModel(
      custCode: json['cust_code'] as String,
      totalAmount: json['total_amount'] as String,
      docNo: json['doc_no'] as String,
      docDate: json['doc_date'] as String,
      custName: json['cust_name'] as String,
      docTime: json['doc_time'] as String,
    );

Map<String, dynamic> _$SaleHistoryModelToJson(SaleHistoryModel instance) =>
    <String, dynamic>{
      'cust_code': instance.custCode,
      'total_amount': instance.totalAmount,
      'doc_no': instance.docNo,
      'doc_date': instance.docDate,
      'cust_name': instance.custName,
      'doc_time': instance.docTime,
    };

SaleHistoryResponse _$SaleHistoryResponseFromJson(Map<String, dynamic> json) =>
    SaleHistoryResponse(
      success: json['success'] as bool,
      data: (json['data'] as List<dynamic>)
          .map((e) => SaleHistoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SaleHistoryResponseToJson(
        SaleHistoryResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
    };
