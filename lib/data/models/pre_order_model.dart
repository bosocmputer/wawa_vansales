import 'package:json_annotation/json_annotation.dart';

part 'pre_order_model.g.dart';

@JsonSerializable()
class PreOrderModel {
  @JsonKey(name: 'cust_code')
  final String custCode;

  @JsonKey(name: 'total_amount')
  final String totalAmount;

  @JsonKey(name: 'doc_no')
  final String docNo;

  @JsonKey(name: 'doc_date')
  final String docDate;

  @JsonKey(name: 'cust_name')
  final String custName;

  PreOrderModel({
    required this.custCode,
    required this.totalAmount,
    required this.docNo,
    required this.docDate,
    required this.custName,
  });

  factory PreOrderModel.fromJson(Map<String, dynamic> json) => _$PreOrderModelFromJson(json);
  Map<String, dynamic> toJson() => _$PreOrderModelToJson(this);
}

@JsonSerializable()
class PreOrderResponse {
  final bool success;
  final List<PreOrderModel> data;

  PreOrderResponse({
    required this.success,
    required this.data,
  });

  factory PreOrderResponse.fromJson(Map<String, dynamic> json) {
    return PreOrderResponse(
      success: json['success'] ?? true,
      data: (json['data'] as List).map((e) => PreOrderModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() => _$PreOrderResponseToJson(this);
}

@JsonSerializable()
class PreOrderDetailModel {
  @JsonKey(name: 'item_code')
  final String itemCode;

  @JsonKey(name: 'stand_value')
  final String standValue;

  @JsonKey(name: 'price')
  final String price;

  @JsonKey(name: 'qty')
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

  @JsonKey(name: 'ratio')
  final String ratio;

  double get totalAmount => (double.tryParse(price) ?? 0) * (double.tryParse(qty) ?? 0);

  PreOrderDetailModel({
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

  factory PreOrderDetailModel.fromJson(Map<String, dynamic> json) => _$PreOrderDetailModelFromJson(json);
  Map<String, dynamic> toJson() => _$PreOrderDetailModelToJson(this);
}

@JsonSerializable()
class PreOrderDetailResponse {
  final bool success;
  final List<PreOrderDetailModel> data;

  PreOrderDetailResponse({
    required this.success,
    required this.data,
  });

  factory PreOrderDetailResponse.fromJson(Map<String, dynamic> json) {
    return PreOrderDetailResponse(
      success: json['success'] ?? true,
      data: (json['data'] as List).map((e) => PreOrderDetailModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() => _$PreOrderDetailResponseToJson(this);
}
