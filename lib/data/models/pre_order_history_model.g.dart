// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pre_order_history_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PreOrderHistoryModel _$PreOrderHistoryModelFromJson(
        Map<String, dynamic> json) =>
    PreOrderHistoryModel(
      docNo: json['doc_no'] as String? ?? '',
      docDate: json['doc_date'] as String? ?? '',
      docTime: json['doc_time'] as String? ?? '',
      custCode: json['cust_code'] as String? ?? '',
      custName: json['cust_name'] as String? ?? '',
      totalAmount: PreOrderHistoryModel._amountFromJson(json['total_amount']),
      cashAmount: json['cash_amount'] as String? ?? '0',
      tranferAmount: json['tranfer_amount'] as String? ?? '0',
      cardAmount: json['card_amount'] as String? ?? '0',
      totalCreditCharge: json['total_credit_charge'] as String? ?? '0',
      totalNetAmount: json['total_net_amount'] as String? ?? '0',
      totalAmountPay: json['total_amount_pay'] as String? ?? '0',
      transferRef: json['transfer_ref'] as String? ?? '',
    );

Map<String, dynamic> _$PreOrderHistoryModelToJson(
        PreOrderHistoryModel instance) =>
    <String, dynamic>{
      'doc_no': instance.docNo,
      'doc_date': instance.docDate,
      'doc_time': instance.docTime,
      'cust_code': instance.custCode,
      'cust_name': instance.custName,
      'total_amount': instance.totalAmount,
      'cash_amount': instance.cashAmount,
      'tranfer_amount': instance.tranferAmount,
      'card_amount': instance.cardAmount,
      'total_credit_charge': instance.totalCreditCharge,
      'total_net_amount': instance.totalNetAmount,
      'total_amount_pay': instance.totalAmountPay,
      'transfer_ref': instance.transferRef,
    };
