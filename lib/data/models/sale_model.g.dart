// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaleModel _$SaleModelFromJson(Map<String, dynamic> json) => SaleModel(
      docno: json['docno'] as String?,
      docdate: json['docdate'] as String?,
      custcode: json['custcode'] as String?,
      custname: json['custname'] as String?,
      empcode: json['empcode'] as String?,
      empname: json['empname'] as String?,
      whcode: json['whcode'] as String?,
      whname: json['whname'] as String?,
      locationcode: json['locationcode'] as String?,
      locationname: json['locationname'] as String?,
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => SaleItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalamount: json['totalamount'] as String?,
    );

Map<String, dynamic> _$SaleModelToJson(SaleModel instance) => <String, dynamic>{
      'docno': instance.docno,
      'docdate': instance.docdate,
      'custcode': instance.custcode,
      'custname': instance.custname,
      'empcode': instance.empcode,
      'empname': instance.empname,
      'whcode': instance.whcode,
      'whname': instance.whname,
      'locationcode': instance.locationcode,
      'locationname': instance.locationname,
      'items': instance.items,
      'totalamount': instance.totalamount,
    };
