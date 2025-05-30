import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:wawa_vansales/blocs/warehouse/warehouse_event.dart';
import 'package:wawa_vansales/blocs/warehouse/warehouse_state.dart';
import 'package:wawa_vansales/data/models/location_model.dart';
import 'package:wawa_vansales/data/models/warehouse_model.dart';
import 'package:wawa_vansales/data/repositories/warehouse_repository.dart';

class WarehouseBloc extends Bloc<WarehouseEvent, WarehouseState> {
  final WarehouseRepository _warehouseRepository;
  final Logger _logger = Logger();

  // เก็บข้อมูลคลังและโลเคชั่นปัจจุบัน
  WarehouseModel? _selectedWarehouse;
  // ignore: unused_field
  LocationModel? _selectedLocation;

  WarehouseBloc({required WarehouseRepository warehouseRepository})
      : _warehouseRepository = warehouseRepository,
        super(WarehouseInitial()) {
    on<FetchWarehouses>(_onFetchWarehouses);
    on<SelectWarehouse>(_onSelectWarehouse);
    on<FetchLocations>(_onFetchLocations);
    on<SelectLocation>(_onSelectLocation);
    on<SaveWarehouseAndLocation>(_onSaveWarehouseAndLocation);
    on<CheckWarehouseSelection>(_onCheckWarehouseSelection);
    on<ClearWarehouseAndLocation>(_onClearWarehouseAndLocation);
  }

  // ดึงรายการคลังทั้งหมด
  Future<void> _onFetchWarehouses(
    FetchWarehouses event,
    Emitter<WarehouseState> emit,
  ) async {
    _logger.i('Fetching warehouses');
    emit(WarehousesLoading());

    try {
      final warehouses = await _warehouseRepository.getWarehouses();
      _logger.i('Fetched ${warehouses.length} warehouses');
      emit(WarehousesLoaded(warehouses));
    } catch (e) {
      _logger.e('Error fetching warehouses: $e');
      emit(WarehousesError(e.toString()));
    }
  }

  // เลือกคลัง
  Future<void> _onSelectWarehouse(
    SelectWarehouse event,
    Emitter<WarehouseState> emit,
  ) async {
    _logger.i('Warehouse selected: ${event.warehouse.code} - ${event.warehouse.name}');
    _selectedWarehouse = event.warehouse;
    emit(WarehouseSelected(event.warehouse));

    // ดึงรายการโลเคชั่นอัตโนมัติหลังจากเลือกคลัง
    add(FetchLocations(event.warehouse.code));
  }

  // ดึงรายการโลเคชั่นตามรหัสคลัง
  Future<void> _onFetchLocations(
    FetchLocations event,
    Emitter<WarehouseState> emit,
  ) async {
    if (_selectedWarehouse == null) {
      _logger.e('No warehouse selected');
      return;
    }

    _logger.i('Fetching locations for warehouse: ${event.warehouseCode}');
    emit(LocationsLoading(_selectedWarehouse!));

    try {
      final locations = await _warehouseRepository.getLocations(event.warehouseCode);
      _logger.i('Fetched ${locations.length} locations');
      emit(LocationsLoaded(warehouse: _selectedWarehouse!, locations: locations));
    } catch (e) {
      _logger.e('Error fetching locations: $e');
      emit(LocationsError(warehouse: _selectedWarehouse!, message: e.toString()));
    }
  }

  // เลือกโลเคชั่น
  Future<void> _onSelectLocation(
    SelectLocation event,
    Emitter<WarehouseState> emit,
  ) async {
    if (_selectedWarehouse == null) {
      _logger.e('No warehouse selected');
      return;
    }

    _logger.i('Location selected: ${event.location.code} - ${event.location.name}');
    _selectedLocation = event.location;
    emit(LocationSelected(warehouse: _selectedWarehouse!, location: event.location));
  }

  // บันทึกคลังและโลเคชั่นที่เลือก
  Future<void> _onSaveWarehouseAndLocation(
    SaveWarehouseAndLocation event,
    Emitter<WarehouseState> emit,
  ) async {
    _logger.i('Saving warehouse and location: ${event.warehouse.code}, ${event.location.code}');

    try {
      await _warehouseRepository.saveWarehouseAndLocation(event.warehouse, event.location);
      _selectedWarehouse = event.warehouse;
      _selectedLocation = event.location;
      _logger.i('Warehouse and location saved successfully');
      emit(WarehouseAndLocationSaved(warehouse: event.warehouse, location: event.location));
    } catch (e) {
      _logger.e('Error saving warehouse and location: $e');
      emit(WarehousesError('ไม่สามารถบันทึกข้อมูลคลังและโลเคชั่นได้: ${e.toString()}'));
    }
  }

  // ตรวจสอบว่ามีการเลือกคลังและโลเคชั่นแล้วหรือไม่
  Future<void> _onCheckWarehouseSelection(
    CheckWarehouseSelection event,
    Emitter<WarehouseState> emit,
  ) async {
    _logger.i('Checking if warehouse and location are selected');

    try {
      final isSelected = await _warehouseRepository.isWarehouseSelected();

      if (isSelected) {
        final warehouse = await _warehouseRepository.getSelectedWarehouse();
        final location = await _warehouseRepository.getSelectedLocation();

        if (warehouse != null && location != null) {
          _selectedWarehouse = warehouse;
          _selectedLocation = location;
          _logger.i('Warehouse and location already selected: ${warehouse.code}, ${location.code}');
          emit(WarehouseSelectionComplete(warehouse: warehouse, location: location));
        } else {
          _logger.w('Warehouse or location is null despite status being selected');
          emit(WarehouseSelectionRequired());
        }
      } else {
        _logger.i('Warehouse and location not selected yet');
        emit(WarehouseSelectionRequired());
      }
    } catch (e) {
      _logger.e('Error checking warehouse selection: $e');
      emit(WarehouseError(e.toString()));
    }
  }

  // ล้างข้อมูลคลังและโลเคชั่นที่เลือก
  Future<void> _onClearWarehouseAndLocation(
    ClearWarehouseAndLocation event,
    Emitter<WarehouseState> emit,
  ) async {
    _logger.i('Clearing warehouse and location selection');

    try {
      await _warehouseRepository.clearWarehouseAndLocation();
      _selectedWarehouse = null;
      _selectedLocation = null;
      _logger.i('Warehouse and location cleared successfully');
      emit(WarehouseInitial());
    } catch (e) {
      _logger.e('Error clearing warehouse and location: $e');
      emit(WarehousesError('ไม่สามารถล้างข้อมูลคลังและโลเคชั่นได้: ${e.toString()}'));
    }
  }
}
