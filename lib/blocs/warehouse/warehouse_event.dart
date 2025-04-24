import 'package:equatable/equatable.dart';
import 'package:wawa_vansales/data/models/warehouse_model.dart';
import 'package:wawa_vansales/data/models/location_model.dart';

abstract class WarehouseEvent extends Equatable {
  const WarehouseEvent();

  @override
  List<Object?> get props => [];
}

// ดึงรายการคลัง
class FetchWarehouses extends WarehouseEvent {}

// เลือกคลัง
class SelectWarehouse extends WarehouseEvent {
  final WarehouseModel warehouse;

  const SelectWarehouse(this.warehouse);

  @override
  List<Object?> get props => [warehouse];
}

// ดึงรายการโลเคชั่น
class FetchLocations extends WarehouseEvent {
  final String warehouseCode;

  const FetchLocations(this.warehouseCode);

  @override
  List<Object?> get props => [warehouseCode];
}

// เลือกโลเคชั่น
class SelectLocation extends WarehouseEvent {
  final LocationModel location;

  const SelectLocation(this.location);

  @override
  List<Object?> get props => [location];
}

// บันทึกคลังและโลเคชั่นที่เลือก
class SaveWarehouseAndLocation extends WarehouseEvent {
  final WarehouseModel warehouse;
  final LocationModel location;

  const SaveWarehouseAndLocation({
    required this.warehouse,
    required this.location,
  });

  @override
  List<Object?> get props => [warehouse, location];
}

// ตรวจสอบการเลือกคลังและโลเคชั่น
class CheckWarehouseSelection extends WarehouseEvent {}

// ล้างคลังและโลเคชั่นที่เลือก
class ClearWarehouseAndLocation extends WarehouseEvent {}
