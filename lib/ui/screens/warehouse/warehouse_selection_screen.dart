import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wawa_vansales/blocs/warehouse/warehouse_bloc.dart';
import 'package:wawa_vansales/blocs/warehouse/warehouse_event.dart';
import 'package:wawa_vansales/blocs/warehouse/warehouse_state.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/models/location_model.dart';
import 'package:wawa_vansales/data/models/warehouse_model.dart';
import 'package:wawa_vansales/ui/screens/home_screen.dart';
import 'package:wawa_vansales/ui/screens/warehouse/emty_state_widget.dart';
import 'package:wawa_vansales/ui/screens/warehouse/selection_stepper.dart';
import 'package:wawa_vansales/ui/screens/warehouse/warehouse_list_view.dart';
import 'package:wawa_vansales/ui/screens/warehouse/location_list_view.dart';
import 'package:wawa_vansales/ui/screens/warehouse/selection_summary_view.dart';
import 'package:wawa_vansales/ui/widgets/custom_button.dart';

class WarehouseSelectionScreen extends StatefulWidget {
  final WarehouseModel? initialWarehouse;
  final LocationModel? initialLocation;

  const WarehouseSelectionScreen({
    super.key,
    this.initialWarehouse,
    this.initialLocation,
  });

  @override
  State<WarehouseSelectionScreen> createState() => _WarehouseSelectionScreenState();
}

class _WarehouseSelectionScreenState extends State<WarehouseSelectionScreen> {
  // Current step in selection process (0: warehouse, 1: location, 2: confirm)
  int _currentStep = 0;

  // Selection values
  WarehouseModel? _selectedWarehouse;
  LocationModel? _selectedLocation;

  // Cache for data
  List<WarehouseModel> _warehouses = [];
  List<LocationModel> _locations = [];

  @override
  void initState() {
    super.initState();

    // Set initial values if provided
    _selectedWarehouse = widget.initialWarehouse;
    _selectedLocation = widget.initialLocation;

    // If we have pre-selected values, start at appropriate step
    if (_selectedWarehouse != null) {
      if (_selectedLocation != null) {
        _currentStep = 2; // Go to confirmation step
      } else {
        _currentStep = 1; // Go to location selection
      }
    }

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Always fetch warehouses list
      context.read<WarehouseBloc>().add(FetchWarehouses());

      // If warehouse is selected, fetch locations
      if (_selectedWarehouse != null) {
        context.read<WarehouseBloc>().add(SelectWarehouse(_selectedWarehouse!));
      }
    });
  }

  // Handle warehouse selection
  void _onWarehouseSelected(WarehouseModel warehouse) {
    setState(() {
      _selectedWarehouse = warehouse;
      _selectedLocation = null; // Reset location when warehouse changes
      _currentStep = 1; // Move to location selection step
    });

    // Fetch locations for selected warehouse
    context.read<WarehouseBloc>().add(SelectWarehouse(warehouse));
  }

  // Handle location selection
  void _onLocationSelected(LocationModel location) {
    setState(() {
      _selectedLocation = location;
      _currentStep = 2; // Move to confirmation step
    });

    context.read<WarehouseBloc>().add(SelectLocation(location));
  }

  // Navigation methods
  void _goBack() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
      });
    }
  }

  void _goToNextStep() {
    setState(() {
      _currentStep += 1;
    });
  }

  // Save final selection and proceed
  void _saveSelection() {
    if (_selectedWarehouse != null && _selectedLocation != null) {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('กำลังบันทึกข้อมูล...'),
              ],
            ),
          );
        },
      );

      // Save the data
      context.read<WarehouseBloc>().add(
            SaveWarehouseAndLocation(
              warehouse: _selectedWarehouse!,
              location: _selectedLocation!,
            ),
          );
    }
  }

  // Reset the current step's selection
  void _resetCurrentSelection() {
    setState(() {
      switch (_currentStep) {
        case 0:
          _selectedWarehouse = null;
          _selectedLocation = null;
          break;
        case 1:
          _selectedLocation = null;
          break;
        case 2:
          // Confirmation step - reset not applicable
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เลือกคลังและพื้นที่จัดเก็บ'),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _goBack,
              )
            : null,
        actions: [
          // Reset button - only show when there's something to reset
          if ((_currentStep == 0 && _selectedWarehouse != null) || (_currentStep == 1 && _selectedLocation != null))
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetCurrentSelection,
              tooltip: 'เลือกใหม่',
            ),
        ],
      ),
      body: BlocListener<WarehouseBloc, WarehouseState>(
        listener: (context, state) {
          // Handle state changes
          if (state is WarehouseAndLocationSaved) {
            // Close loading dialog and navigate to home
            Navigator.of(context).popUntil((route) => route.isFirst);
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          } else if (state is WarehousesLoaded) {
            setState(() {
              _warehouses = state.warehouses;
            });
          } else if (state is LocationsLoaded) {
            setState(() {
              _locations = state.locations;
            });
          } else if (state is WarehousesError || state is LocationsError) {
            final errorMessage = state is WarehousesError ? state.message : (state as LocationsError).message;

            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('เกิดข้อผิดพลาด: $errorMessage'),
                backgroundColor: AppTheme.errorColor,
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'ลองใหม่',
                  textColor: Colors.white,
                  onPressed: () {
                    if (state is WarehousesError) {
                      context.read<WarehouseBloc>().add(FetchWarehouses());
                    } else if (state is LocationsError && _selectedWarehouse != null) {
                      context.read<WarehouseBloc>().add(SelectWarehouse(_selectedWarehouse!));
                    }
                  },
                ),
              ),
            );
          }
        },
        child: Column(
          children: [
            // Stepper showing progression through the flow
            SelectionStepper(
              currentStep: _currentStep,
              warehouseSelected: _selectedWarehouse != null,
              locationSelected: _selectedLocation != null,
            ),

            // Main content area - changes based on current step
            Expanded(
              child: _buildCurrentStepContent(),
            ),

            // Bottom navigation buttons
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    Widget content;

    switch (_currentStep) {
      case 0:
        // Warehouse selection step
        content = WarehouseListView(
          warehouses: _warehouses,
          selectedWarehouse: _selectedWarehouse,
          onWarehouseSelected: _onWarehouseSelected,
          isLoading: context.watch<WarehouseBloc>().state is WarehousesLoading,
        );
        break;

      case 1:
        // Location selection step
        content = LocationListView(
          locations: _locations,
          selectedLocation: _selectedLocation,
          onLocationSelected: _onLocationSelected,
          isLoading: context.watch<WarehouseBloc>().state is LocationsLoading,
        );
        break;

      case 2:
        // Confirmation step
        content = SelectionSummaryView(
          warehouse: _selectedWarehouse!,
          location: _selectedLocation!,
        );
        break;

      default:
        content = const EmptyStateWidget(
          icon: Icons.error_outline,
          message: 'ขั้นตอนไม่ถูกต้อง',
        );
    }

    // Wrap in animated switcher for smooth transitions
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: content,
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button (except for first step)
          if (_currentStep > 0)
            Expanded(
              flex: 1,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: const Text('ย้อนกลับ'),
                onPressed: _goBack,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

          if (_currentStep > 0) const SizedBox(width: 12),

          // Next/Submit button
          Expanded(
            flex: 2,
            child: CustomButton(
              text: _currentStep == 2
                  ? 'บันทึกและเข้าสู่ระบบ'
                  : _currentStep == 0 && _selectedWarehouse != null
                      ? 'ถัดไป'
                      : _currentStep == 1 && _selectedLocation != null
                          ? 'ถัดไป'
                          : _currentStep == 0
                              ? 'เลือกคลัง'
                              : 'เลือกพื้นที่เก็บ',
              icon: _currentStep == 2 ? const Icon(Icons.save, color: Colors.white, size: 20) : const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              buttonType: ButtonType.primary,
              isLoading: context.watch<WarehouseBloc>().state is WarehousesLoading || context.watch<WarehouseBloc>().state is LocationsLoading,
              onPressed: () {
                if (_currentStep == 0 && _selectedWarehouse != null) {
                  _goToNextStep();
                } else if (_currentStep == 1 && _selectedLocation != null) {
                  _goToNextStep();
                } else if (_currentStep == 2) {
                  _saveSelection();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
