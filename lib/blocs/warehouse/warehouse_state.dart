import 'package:equatable/equatable.dart';
import 'package:wawa_vansales/data/models/warehouse_model.dart';
import 'package:wawa_vansales/data/models/location_model.dart';

abstract class WarehouseState extends Equatable {
  const WarehouseState();

  @override
  List<Object?> get props => [];
}

// สถานะเริ่มต้น
class WarehouseInitial extends WarehouseState {}

// กำลังโหลดข้อมูลคลัง
class WarehousesLoading extends WarehouseState {}

// โหลดข้อมูลคลังสำเร็จ
class WarehousesLoaded extends WarehouseState {
  final List<WarehouseModel> warehouses;

  const WarehousesLoaded(this.warehouses);

  @override
  List<Object?> get props => [warehouses];
}

// โหลดข้อมูลคลังล้มเหลว
class WarehousesError extends WarehouseState {
  final String message;

  const WarehousesError(this.message);

  @override
  List<Object?> get props => [message];
}

// เลือกคลังแล้ว
class WarehouseSelected extends WarehouseState {
  final WarehouseModel warehouse;

  const WarehouseSelected(this.warehouse);

  @override
  List<Object?> get props => [warehouse];
}

// กำลังโหลดข้อมูลโลเคชั่น
class LocationsLoading extends WarehouseState {
  final WarehouseModel warehouse;

  const LocationsLoading(this.warehouse);

  @override
  List<Object?> get props => [warehouse];
}

// โหลดข้อมูลโลเคชั่นสำเร็จ
class LocationsLoaded extends WarehouseState {
  final WarehouseModel warehouse;
  final List<LocationModel> locations;

  const LocationsLoaded({
    required this.warehouse,
    required this.locations,
  });

  @override
  List<Object?> get props => [warehouse, locations];
}

// โหลดข้อมูลโลเคชั่นล้มเหลว
class LocationsError extends WarehouseState {
  final WarehouseModel warehouse;
  final String message;

  const LocationsError({
    required this.warehouse,
    required this.message,
  });

  @override
  List<Object?> get props => [warehouse, message];
}

// เลือกโลเคชั่นแล้ว
class LocationSelected extends WarehouseState {
  final WarehouseModel warehouse;
  final LocationModel location;

  const LocationSelected({
    required this.warehouse,
    required this.location,
  });

  @override
  List<Object?> get props => [warehouse, location];
}

// บันทึกคลังและโลเคชั่นเรียบร้อยแล้ว
class WarehouseAndLocationSaved extends WarehouseState {
  final WarehouseModel warehouse;
  final LocationModel location;

  const WarehouseAndLocationSaved({
    required this.warehouse,
    required this.location,
  });

  @override
  List<Object?> get props => [warehouse, location];
}

// ผู้ใช้ยังไม่ได้เลือกคลังและโลเคชั่น
class WarehouseSelectionRequired extends WarehouseState {}

// ผู้ใช้เลือกคลังและโลเคชั่นแล้ว
class WarehouseSelectionComplete extends WarehouseState {
  final WarehouseModel warehouse;
  final LocationModel location;

  const WarehouseSelectionComplete({
    required this.warehouse,
    required this.location,
  });

  @override
  List<Object?> get props => [warehouse, location];
}
