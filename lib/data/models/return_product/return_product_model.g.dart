// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'return_product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReturnProductModel _$ReturnProductModelFromJson(Map<String, dynamic> json) =>
    ReturnProductModel(
      custCode: json['cust_code'] as String,
      empCode: json['emp_code'] as String,
      docDate: json['doc_date'] as String,
      docTime: json['doc_time'] as String,
      docNo: json['doc_no'] as String,
      refDocDate: json['ref_doc_date'] as String,
      refDocNo: json['ref_doc_no'] as String,
      refAmount: json['ref_amount'] as String,
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
      totalAmount: json['total_amount'] as String,
      totalValue: json['total_value'] as String,
      remark: json['remark'] as String,
    );

Map<String, dynamic> _$ReturnProductModelToJson(ReturnProductModel instance) =>
    <String, dynamic>{
      'cust_code': instance.custCode,
      'emp_code': instance.empCode,
      'doc_date': instance.docDate,
      'doc_time': instance.docTime,
      'doc_no': instance.docNo,
      'ref_doc_date': instance.refDocDate,
      'ref_doc_no': instance.refDocNo,
      'ref_amount': instance.refAmount,
      'items': instance.items,
      'payment_detail': instance.paymentDetail,
      'tranfer_amount': instance.transferAmount,
      'credit_amount': instance.creditAmount,
      'cash_amount': instance.cashAmount,
      'card_amount': instance.cardAmount,
      'total_amount': instance.totalAmount,
      'total_value': instance.totalValue,
      'remark': instance.remark,
    };
