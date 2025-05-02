import 'package:json_annotation/json_annotation.dart';

part 'sale_document_detail_model.g.dart';

@JsonSerializable()
class SaleDocumentDetailModel {
  @JsonKey(name: 'item_code')
  final String itemCode;

  @JsonKey(name: 'item_name')
  final String itemName;

  @JsonKey(name: 'unit_code')
  final String unitCode;

  @JsonKey(name: 'price')
  final String price;

  @JsonKey(name: 'qty')
  final String qty;

  @JsonKey(name: 'wh_code')
  final String whCode;

  @JsonKey(name: 'shelf_code')
  final String shelfCode;

  @JsonKey(name: 'stand_value')
  final String standValue;

  @JsonKey(name: 'divide_value')
  final String divideValue;

  @JsonKey(name: 'ratio')
  final String ratio;

  @JsonKey(name: 'ref_row')
  final String refRow;

  SaleDocumentDetailModel({
    required this.itemCode,
    required this.itemName,
    required this.unitCode,
    required this.price,
    required this.qty,
    required this.whCode,
    required this.shelfCode,
    required this.standValue,
    required this.divideValue,
    required this.ratio,
    required this.refRow,
  });

  factory SaleDocumentDetailModel.fromJson(Map<String, dynamic> json) => _$SaleDocumentDetailModelFromJson(json);

  Map<String, dynamic> toJson() => _$SaleDocumentDetailModelToJson(this);

  double get priceAsDouble => double.tryParse(price) ?? 0.0;
  double get qtyAsDouble => double.tryParse(qty) ?? 0.0;
  double get totalAmount => priceAsDouble * qtyAsDouble;
}
