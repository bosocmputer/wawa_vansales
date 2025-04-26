import 'package:json_annotation/json_annotation.dart';
part 'sale_item_model.g.dart';

@JsonSerializable()
class SaleItemModel {
  String? barcode;
  String? itemCode;
  String? itemName;
  String? unitCode;
  String? unitName;
  int? quantity;
  double? price;

  SaleItemModel({
    String? barcode,
    String? itemCode,
    String? itemName,
    String? unitCode,
    String? unitName,
    int? quantity,
    double? price,
  })  : barcode = barcode ?? '',
        itemCode = itemCode ?? '',
        itemName = itemName ?? '',
        unitCode = unitCode ?? '',
        unitName = unitName ?? '',
        quantity = quantity ?? 0,
        price = price ?? 0.0;

  factory SaleItemModel.fromJson(Map<String, dynamic> json) => _$SaleItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$SaleItemModelToJson(this);
}
