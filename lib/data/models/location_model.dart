import 'package:json_annotation/json_annotation.dart';

part 'location_model.g.dart';

@JsonSerializable()
class LocationModel {
  final String code;
  final String name;

  LocationModel({
    required this.code,
    required this.name,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) => _$LocationModelFromJson(json);

  Map<String, dynamic> toJson() => _$LocationModelToJson(this);
}

@JsonSerializable()
class LocationResponse {
  final bool success;
  final List<LocationModel> data;

  LocationResponse({
    required this.success,
    required this.data,
  });

  factory LocationResponse.fromJson(Map<String, dynamic> json) => _$LocationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LocationResponseToJson(this);
}
