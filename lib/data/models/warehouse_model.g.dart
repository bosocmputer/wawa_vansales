// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'warehouse_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WarehouseModel _$WarehouseModelFromJson(Map<String, dynamic> json) =>
    WarehouseModel(
      code: json['code'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$WarehouseModelToJson(WarehouseModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
    };

WarehouseResponse _$WarehouseResponseFromJson(Map<String, dynamic> json) =>
    WarehouseResponse(
      success: json['success'] as bool,
      data: (json['data'] as List<dynamic>)
          .map((e) => WarehouseModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$WarehouseResponseToJson(WarehouseResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
    };
