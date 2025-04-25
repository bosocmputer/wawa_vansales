// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sales_transaction_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SalesTransactionModel _$SalesTransactionModelFromJson(Map<String, dynamic> json) => SalesTransactionModel(
      id: json['id'] as String,
      docNo: json['docNo'] as String,
      docDate: DateTime.parse(json['docDate'] as String),
      customer: json['customer'] == null ? null : CustomerModel.fromJson(json['customer'] as Map<String, dynamic>),
      items: (json['items'] as List<dynamic>).map((e) => SalesItemModel.fromJson(e as Map<String, dynamic>)).toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      vatAmount: (json['vatAmount'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      paymentType: _$enumDecode(_$PaymentTypeEnumMap, json['paymentType']),
      remark: json['remark'] as String?,
      status: json['status'] as String,
    );

Map<String, dynamic> _$SalesTransactionModelToJson(SalesTransactionModel instance) => <String, dynamic>{
      'id': instance.id,
      'docNo': instance.docNo,
      'docDate': instance.docDate.toIso8601String(),
      'customer': instance.customer?.toJson(),
      'items': instance.items.map((e) => e.toJson()).toList(),
      'subtotal': instance.subtotal,
      'vatAmount': instance.vatAmount,
      'discount': instance.discount,
      'total': instance.total,
      'paymentType': _$PaymentTypeEnumMap[instance.paymentType]!,
      'remark': instance.remark,
      'status': instance.status,
    };

K _$enumDecode<K, V>(Map<K, V> enumValues, Object? source) {
  if (source == null) {
    throw ArgumentError('A value must be provided. Supported values: ${enumValues.values.join(', ')}');
  }
  return enumValues.entries.singleWhere((e) => e.value == source).key;
}

const _$PaymentTypeEnumMap = {
  PaymentType.cash: 'cash',
  PaymentType.transfer: 'transfer',
  PaymentType.creditCard: 'creditCard',
};

SalesItemModel _$SalesItemModelFromJson(Map<String, dynamic> json) => SalesItemModel(
      product: ProductModel.fromJson(json['product'] as Map<String, dynamic>),
      quantity: (json['quantity'] as num).toDouble(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
    );

Map<String, dynamic> _$SalesItemModelToJson(SalesItemModel instance) => <String, dynamic>{
      'product': instance.product.toJson(),
      'quantity': instance.quantity,
      'unitPrice': instance.unitPrice,
      'discount': instance.discount,
      'total': instance.total,
    };
