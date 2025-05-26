// lib/data/models/cart_item_model.dart
import 'package:json_annotation/json_annotation.dart';

part 'cart_item_model.g.dart';

@JsonSerializable()
class CartItemModel {
  @JsonKey(name: 'item_code')
  final String itemCode;

  @JsonKey(name: 'item_name')
  final String itemName;

  final String barcode;

  final String price;

  @JsonKey(name: 'sum_amount')
  final String sumAmount;

  @JsonKey(name: 'unit_code')
  final String unitCode;

  @JsonKey(name: 'wh_code')
  final String whCode;

  @JsonKey(name: 'shelf_code')
  final String shelfCode;

  final String ratio;

  @JsonKey(name: 'stand_value')
  final String standValue;

  @JsonKey(name: 'divide_value')
  final String divideValue;

  /// ref_row
  @JsonKey(name: 'ref_row')
  final String refRow;

  String qty;

  CartItemModel({
    required this.itemCode,
    required this.itemName,
    required this.barcode,
    required this.price,
    required this.sumAmount,
    required this.unitCode,
    required this.whCode,
    required this.shelfCode,
    required this.ratio,
    required this.standValue,
    required this.divideValue,
    this.qty = '1',
    this.refRow = '0',
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) => _$CartItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$CartItemModelToJson(this);

  // คำนวณยอดรวมสำหรับรายการนี้
  double get totalAmount => (double.tryParse(price) ?? 0) * (double.tryParse(qty) ?? 0);

  // สร้าง copy with method
  CartItemModel copyWith({
    String? itemCode,
    String? itemName,
    String? barcode,
    String? price,
    String? sumAmount,
    String? unitCode,
    String? whCode,
    String? shelfCode,
    String? ratio,
    String? standValue,
    String? divideValue,
    String? qty,
    String? refRow,
  }) {
    return CartItemModel(
      itemCode: itemCode ?? this.itemCode,
      itemName: itemName ?? this.itemName,
      barcode: barcode ?? this.barcode,
      price: price ?? this.price,
      sumAmount: sumAmount ?? this.sumAmount,
      unitCode: unitCode ?? this.unitCode,
      whCode: whCode ?? this.whCode,
      shelfCode: shelfCode ?? this.shelfCode,
      ratio: ratio ?? this.ratio,
      standValue: standValue ?? this.standValue,
      divideValue: divideValue ?? this.divideValue,
      qty: qty ?? this.qty,
      refRow: refRow ?? this.refRow,
    );
  }
}
