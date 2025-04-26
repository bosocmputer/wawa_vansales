// lib/data/models/receipt_model.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:wawa_vansales/data/models/sale_item_model.dart';

part 'receipt_model.g.dart';

@JsonSerializable()
class ReceiptModel {
  String? docNo;
  String? date;
  String? customerName;
  String? customerCode;
  String? warehouseName;
  String? employeeName;
  List<SaleItemModel>? items;
  String? totalAmount;
  String? paymentMethod;

  ReceiptModel({
    String? docNo,
    String? date,
    String? customerName,
    String? customerCode,
    String? warehouseName,
    String? employeeName,
    List<SaleItemModel>? items,
    String? totalAmount,
    String? paymentMethod,
  })  : docNo = docNo ?? '',
        date = date ?? '',
        customerName = customerName ?? '',
        customerCode = customerCode ?? '',
        warehouseName = warehouseName ?? '',
        employeeName = employeeName ?? '',
        items = items ?? [],
        totalAmount = totalAmount ?? '0.00',
        paymentMethod = paymentMethod ?? '';

  factory ReceiptModel.fromJson(Map<String, dynamic> json) => _$ReceiptModelFromJson(json);
  Map<String, dynamic> toJson() => _$ReceiptModelToJson(this);
}
