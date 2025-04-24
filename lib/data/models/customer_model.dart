import 'package:json_annotation/json_annotation.dart';

part 'customer_model.g.dart';

@JsonSerializable()
class CustomerModel {
  final String? code;
  final String? address;
  final String? name;
  final String? telephone;
  @JsonKey(name: 'tax_id')
  final String? taxId;
  @JsonKey(name: 'ar_status')
  final String? arstatus;

  CustomerModel({
    String? code,
    String? address,
    String? name,
    String? telephone,
    String? taxId,
    String? arstatus,
  })  : code = code ?? '',
        address = address ?? '',
        name = name ?? '',
        telephone = telephone ?? '',
        taxId = taxId ?? '',
        arstatus = arstatus ?? '';

  factory CustomerModel.fromJson(Map<String, dynamic> json) => _$CustomerModelFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerModelToJson(this);
}

@JsonSerializable()
class CustomerResponse {
  final bool success;
  final List<CustomerModel> data;

  CustomerResponse({
    required this.success,
    required this.data,
  });

  factory CustomerResponse.fromJson(Map<String, dynamic> json) => _$CustomerResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerResponseToJson(this);
}

@JsonSerializable()
class CreateResponse {
  final bool success;
  final String message;

  CreateResponse({
    required this.success,
    required this.message,
  });

  factory CreateResponse.fromJson(Map<String, dynamic> json) => _$CreateResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CreateResponseToJson(this);
}
