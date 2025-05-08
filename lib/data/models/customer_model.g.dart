// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerModel _$CustomerModelFromJson(Map<String, dynamic> json) =>
    CustomerModel(
      code: json['code'] as String?,
      address: json['address'] as String?,
      name: json['name'] as String?,
      telephone: json['telephone'] as String?,
      taxId: json['tax_id'] as String?,
      arstatus: json['ar_status'] as String?,
      website: json['website'] as String?,
      priceLevel: json['price_level'] as String?,
    );

Map<String, dynamic> _$CustomerModelToJson(CustomerModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'address': instance.address,
      'name': instance.name,
      'telephone': instance.telephone,
      'tax_id': instance.taxId,
      'ar_status': instance.arstatus,
      'website': instance.website,
      'price_level': instance.priceLevel,
    };

CustomerResponse _$CustomerResponseFromJson(Map<String, dynamic> json) =>
    CustomerResponse(
      success: json['success'] as bool,
      data: (json['data'] as List<dynamic>)
          .map((e) => CustomerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CustomerResponseToJson(CustomerResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
    };

CreateResponse _$CreateResponseFromJson(Map<String, dynamic> json) =>
    CreateResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
    );

Map<String, dynamic> _$CreateResponseToJson(CreateResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
    };
