// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'balance_detail_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BalanceDetailModel _$BalanceDetailModelFromJson(Map<String, dynamic> json) =>
    BalanceDetailModel(
      transFlag: json['trans_flag'] as String,
      docNo: json['doc_no'] as String,
      docDate: json['doc_date'] as String,
      amount: json['amount'] as String,
      balanceRef: json['balance_ref'] as String,
    );

Map<String, dynamic> _$BalanceDetailModelToJson(BalanceDetailModel instance) =>
    <String, dynamic>{
      'trans_flag': instance.transFlag,
      'doc_no': instance.docNo,
      'doc_date': instance.docDate,
      'amount': instance.amount,
      'balance_ref': instance.balanceRef,
    };

BalanceDetailResponse _$BalanceDetailResponseFromJson(
        Map<String, dynamic> json) =>
    BalanceDetailResponse(
      success: json['success'] as bool,
      data: (json['data'] as List<dynamic>)
          .map((e) => BalanceDetailModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BalanceDetailResponseToJson(
        BalanceDetailResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
    };
