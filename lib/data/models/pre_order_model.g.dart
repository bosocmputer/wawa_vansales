// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pre_order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PreOrderModel _$PreOrderModelFromJson(Map<String, dynamic> json) => PreOrderModel(
      custCode: json['cust_code'] as String,
      totalAmount: json['total_amount'] as String,
      docNo: json['doc_no'] as String,
      docDate: json['doc_date'] as String,
      custName: json['cust_name'] as String,
    );

Map<String, dynamic> _$PreOrderModelToJson(PreOrderModel instance) => <String, dynamic>{
      'cust_code': instance.custCode,
      'total_amount': instance.totalAmount,
      'doc_no': instance.docNo,
      'doc_date': instance.docDate,
      'cust_name': instance.custName,
    };

Map<String, dynamic> _$PreOrderResponseToJson(PreOrderResponse instance) => <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
    };

PreOrderDetailModel _$PreOrderDetailModelFromJson(Map<String, dynamic> json) => PreOrderDetailModel(
      itemCode: json['item_code'] as String,
      standValue: json['stand_value'] as String,
      sumAmount: json['sum_amount'] as String,
      price: json['price'] as String,
      qty: json['qty'] as String,
      shelfCode: json['shelf_code'] as String,
      unitCode: json['unit_code'] as String,
      itemName: json['item_name'] as String,
      divideValue: json['divide_value'] as String,
      whCode: json['wh_code'] as String,
      ratio: json['ratio'] as String,
    );

Map<String, dynamic> _$PreOrderDetailModelToJson(PreOrderDetailModel instance) => <String, dynamic>{
      'item_code': instance.itemCode,
      'stand_value': instance.standValue,
      'sum_amount': instance.sumAmount,
      'price': instance.price,
      'qty': instance.qty,
      'shelf_code': instance.shelfCode,
      'unit_code': instance.unitCode,
      'item_name': instance.itemName,
      'divide_value': instance.divideValue,
      'wh_code': instance.whCode,
      'ratio': instance.ratio,
    };

Map<String, dynamic> _$PreOrderDetailResponseToJson(PreOrderDetailResponse instance) => <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
    };
