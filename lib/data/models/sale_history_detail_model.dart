import 'package:json_annotation/json_annotation.dart';

part 'sale_history_detail_model.g.dart';

@JsonSerializable()
class SaleHistoryDetailModel {
  @JsonKey(name: 'item_code')
  final String itemCode;

  @JsonKey(name: 'stand_value')
  final String standValue;

  @JsonKey(name: 'price')
  final String price;

  final String qty;

  @JsonKey(name: 'shelf_code')
  final String shelfCode;

  @JsonKey(name: 'unit_code')
  final String unitCode;

  @JsonKey(name: 'item_name')
  final String itemName;

  @JsonKey(name: 'divide_value')
  final String divideValue;

  @JsonKey(name: 'wh_code')
  final String whCode;

  final String ratio;

  SaleHistoryDetailModel({
    required this.itemCode,
    required this.standValue,
    required this.price,
    required this.qty,
    required this.shelfCode,
    required this.unitCode,
    required this.itemName,
    required this.divideValue,
    required this.whCode,
    required this.ratio,
  });

  factory SaleHistoryDetailModel.fromJson(Map<String, dynamic> json) => _$SaleHistoryDetailModelFromJson(json);

  Map<String, dynamic> toJson() => _$SaleHistoryDetailModelToJson(this);

  // Calculate item total amount
  double get totalAmount {
    final priceValue = double.tryParse(price) ?? 0.0;
    final qtyValue = double.tryParse(qty) ?? 0.0;
    return priceValue * qtyValue;
  }
}

@JsonSerializable()
class SaleHistoryDetailResponse {
  final bool success;
  final List<SaleHistoryDetailModel> data;

  SaleHistoryDetailResponse({
    required this.success,
    required this.data,
  });

  factory SaleHistoryDetailResponse.fromJson(Map<String, dynamic> json) => _$SaleHistoryDetailResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SaleHistoryDetailResponseToJson(this);
}
