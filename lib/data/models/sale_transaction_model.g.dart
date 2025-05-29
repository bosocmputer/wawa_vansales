// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_transaction_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaleTransactionModel _$SaleTransactionModelFromJson(
        Map<String, dynamic> json) =>
    SaleTransactionModel(
      custCode: json['cust_code'] as String,
      empCode: json['emp_code'] as String,
      docDate: json['doc_date'] as String,
      docTime: json['doc_time'] as String,
      docNo: json['doc_no'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      paymentDetail: (json['payment_detail'] as List<dynamic>)
          .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      transferAmount: json['tranfer_amount'] as String,
      creditAmount: json['credit_amount'] as String,
      cashAmount: json['cash_amount'] as String,
      cardAmount: json['card_amount'] as String,
      walletAmount: json['wallet_amount'] as String,
      totalAmount: json['total_amount'] as String,
      totalValue: json['total_value'] as String,
      totalCreditCharge: json['total_credit_charge'] as String,
      totalNetAmount: json['total_net_amount'] as String,
      totalAmountPay: json['total_amount_pay'] as String?,
      balanceAmount: json['balance_amount'] as String,
      balanceDetail: (json['balance_detail'] as List<dynamic>)
          .map((e) => BalanceDetailModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      remark: json['remark'] as String? ?? '',
      carCode: json['car_code'] as String?,
      partialPay: json['partial_pay'] as String? ?? '0',
    );

Map<String, dynamic> _$SaleTransactionModelToJson(
        SaleTransactionModel instance) =>
    <String, dynamic>{
      'cust_code': instance.custCode,
      'emp_code': instance.empCode,
      'doc_date': instance.docDate,
      'doc_time': instance.docTime,
      'doc_no': instance.docNo,
      'items': instance.items,
      'payment_detail': instance.paymentDetail,
      'tranfer_amount': instance.transferAmount,
      'credit_amount': instance.creditAmount,
      'cash_amount': instance.cashAmount,
      'card_amount': instance.cardAmount,
      'wallet_amount': instance.walletAmount,
      'total_amount': instance.totalAmount,
      'total_value': instance.totalValue,
      'total_credit_charge': instance.totalCreditCharge,
      'total_net_amount': instance.totalNetAmount,
      'total_amount_pay': instance.totalAmountPay,
      'balance_amount': instance.balanceAmount,
      'balance_detail': instance.balanceDetail,
      'remark': instance.remark,
      'car_code': instance.carCode,
      'partial_pay': instance.partialPay,
    };

SaleTransactionResponse _$SaleTransactionResponseFromJson(
        Map<String, dynamic> json) =>
    SaleTransactionResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
    );

Map<String, dynamic> _$SaleTransactionResponseToJson(
        SaleTransactionResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
    };
