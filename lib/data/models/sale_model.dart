import 'package:json_annotation/json_annotation.dart';
import 'package:wawa_vansales/data/models/sale_item_model.dart';

part 'sale_model.g.dart';

@JsonSerializable()
class SaleModel {
  String docno;
  String docdate;
  String custcode;
  String custname;
  String empcode;
  String empname;
  String whcode;
  String whname;
  String locationcode;
  String locationname;
  List<SaleItemModel>? items;

  SaleModel({
    String? docno,
    String? docdate,
    String? custcode,
    String? custname,
    String? empcode,
    String? empname,
    String? whcode,
    String? whname,
    String? locationcode,
    String? locationname,
    List<SaleItemModel>? items,
  })  : docno = docno ?? '',
        docdate = docdate ?? '',
        custcode = custcode ?? '',
        custname = custname ?? '',
        empcode = empcode ?? '',
        empname = empname ?? '',
        whcode = whcode ?? '',
        whname = whname ?? '',
        locationcode = locationcode ?? '',
        locationname = locationname ?? '',
        items = items ?? [];
  factory SaleModel.fromJson(Map<String, dynamic> json) => _$SaleModelFromJson(json);
  Map<String, dynamic> toJson() => _$SaleModelToJson(this);
}
