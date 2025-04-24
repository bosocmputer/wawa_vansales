import 'package:json_annotation/json_annotation.dart';

part 'warehouse_model.g.dart';

@JsonSerializable()
class WarehouseModel {
  final String code;
  final String name;

  WarehouseModel({
    required this.code,
    required this.name,
  });

  factory WarehouseModel.fromJson(Map<String, dynamic> json) => _$WarehouseModelFromJson(json);

  Map<String, dynamic> toJson() => _$WarehouseModelToJson(this);
}

@JsonSerializable()
class WarehouseResponse {
  final bool success;
  final List<WarehouseModel> data;

  WarehouseResponse({
    required this.success,
    required this.data,
  });

  factory WarehouseResponse.fromJson(Map<String, dynamic> json) => _$WarehouseResponseFromJson(json);

  Map<String, dynamic> toJson() => _$WarehouseResponseToJson(this);
}
