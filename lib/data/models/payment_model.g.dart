// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentModel _$PaymentModelFromJson(Map<String, dynamic> json) => PaymentModel(
      payType: (json['pay_type'] as num).toInt(),
      transNumber: json['trans_number'] as String,
      payAmount: (json['pay_amount'] as num).toDouble(),
      charge: (json['charge'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$PaymentModelToJson(PaymentModel instance) =>
    <String, dynamic>{
      'pay_type': instance.payType,
      'trans_number': instance.transNumber,
      'pay_amount': instance.payAmount,
      'charge': instance.charge,
    };
