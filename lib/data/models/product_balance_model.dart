import 'package:json_annotation/json_annotation.dart';

part 'product_balance_model.g.dart';

@JsonSerializable()
class ProductBalanceModel {
  @JsonKey(name: 'item_code')
  final String itemCode;

  @JsonKey(name: 'item_name')
  final String itemName;

  @JsonKey(name: 'wh_code')
  final String whCode;

  @JsonKey(name: 'wh_name')
  final String whName;

  @JsonKey(name: 'shelf_code')
  final String shelfCode;

  @JsonKey(name: 'shelf_name')
  final String shelfName;

  final String barcode;

  @JsonKey(name: 'unit_code')
  final String unitCode;

  @JsonKey(name: 'balance_qty')
  final String balanceQty;

  final String price;

  @JsonKey(name: 'qty_word')
  final String qtyWord;

  ProductBalanceModel({
    required this.itemCode,
    required this.itemName,
    required this.whCode,
    required this.whName,
    required this.shelfCode,
    required this.shelfName,
    required this.barcode,
    required this.unitCode,
    required this.balanceQty,
    required this.price,
    required this.qtyWord,
  });

  factory ProductBalanceModel.fromJson(Map<String, dynamic> json) => _$ProductBalanceModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProductBalanceModelToJson(this);
}

@JsonSerializable()
class ProductBalanceResponse {
  final bool success;
  final List<ProductBalanceModel> data;

  ProductBalanceResponse({
    required this.success,
    required this.data,
  });

  factory ProductBalanceResponse.fromJson(Map<String, dynamic> json) => _$ProductBalanceResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ProductBalanceResponseToJson(this);
}
