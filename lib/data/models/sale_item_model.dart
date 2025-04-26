import 'package:json_annotation/json_annotation.dart';
part 'sale_item_model.g.dart';

@JsonSerializable()
class SaleItemModel {
  String? barcode;
  String? itemCode;
  String? itemName;
  String? unitCode;
  String? unitName;
  String? quantity;
  String? price;

  SaleItemModel({
    String? barcode,
    String? itemCode,
    String? itemName,
    String? unitCode,
    String? unitName,
    String? quantity,
    String? price,
  })  : barcode = barcode ?? '',
        itemCode = itemCode ?? '',
        itemName = itemName ?? '',
        unitCode = unitCode ?? '',
        unitName = unitName ?? '',
        quantity = quantity ?? '',
        price = price ?? '';

  factory SaleItemModel.fromJson(Map<String, dynamic> json) => _$SaleItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$SaleItemModelToJson(this);
}
