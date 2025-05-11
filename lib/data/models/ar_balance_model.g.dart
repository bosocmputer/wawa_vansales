// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ar_balance_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ArBalanceModel _$ArBalanceModelFromJson(Map<String, dynamic> json) =>
    ArBalanceModel(
      custCode: json['cust_code'] as String,
      balance: json['balance'] as String,
      docNo: json['doc_no'] as String,
      docDate: json['doc_date'] as String,
      custName: json['cust_name'] as String,
      transFlag: json['trans_flag'] as String,
      selectedAmount: (json['selectedAmount'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ArBalanceModelToJson(ArBalanceModel instance) =>
    <String, dynamic>{
      'cust_code': instance.custCode,
      'balance': instance.balance,
      'doc_no': instance.docNo,
      'doc_date': instance.docDate,
      'cust_name': instance.custName,
      'trans_flag': instance.transFlag,
      'selectedAmount': instance.selectedAmount,
    };

ArBalanceResponse _$ArBalanceResponseFromJson(Map<String, dynamic> json) =>
    ArBalanceResponse(
      success: json['success'] as bool,
      data: (json['data'] as List<dynamic>)
          .map((e) => ArBalanceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ArBalanceResponseToJson(ArBalanceResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
    };
