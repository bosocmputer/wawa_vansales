import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wawa_vansales/blocs/warehouse/warehouse_bloc.dart';
import 'package:wawa_vansales/blocs/warehouse/warehouse_event.dart';
import 'package:wawa_vansales/blocs/warehouse/warehouse_state.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/models/location_model.dart';
import 'package:wawa_vansales/data/models/warehouse_model.dart';
import 'package:wawa_vansales/ui/screens/home_screen.dart';
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

class _WarehouseSelectionScreenState extends State<WarehouseSelectionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  WarehouseModel? _selectedWarehouse;
  LocationModel? _selectedLocation;

  // เก็บรายการคลังและ location เพื่อไม่ให้หายไปเมื่อเลือก
  List<WarehouseModel> _allWarehouses = [];
  List<LocationModel> _allLocations = [];

  final _searchWarehouseController = TextEditingController();
  final _searchLocationController = TextEditingController();

  String _warehouseSearchQuery = '';
  String _locationSearchQuery = '';

  // ใช้ ScrollController เพื่อให้สามารถเลื่อนดูรายการได้
  final _warehouseScrollController = ScrollController();
  final _locationScrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // สร้าง animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();

    // กำหนดค่าเริ่มต้นจาก initialWarehouse และ initialLocation (ถ้ามี)
    _selectedWarehouse = widget.initialWarehouse;
    _selectedLocation = widget.initialLocation;

    // ดึงข้อมูลคลัง
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WarehouseBloc>().add(FetchWarehouses());

      // ถ้ามีคลังที่เลือกไว้แล้ว ให้ดึง location ด้วย
      if (_selectedWarehouse != null) {
        context.read<WarehouseBloc>().add(SelectWarehouse(_selectedWarehouse!));
      }
    });

    _searchWarehouseController.addListener(() {
      setState(() {
        _warehouseSearchQuery = _searchWarehouseController.text;
      });
    });

    _searchLocationController.addListener(() {
      setState(() {
        _locationSearchQuery = _searchLocationController.text;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchWarehouseController.dispose();
    _searchLocationController.dispose();
    _warehouseScrollController.dispose();
    _locationScrollController.dispose();
    super.dispose();
  }

  void _selectWarehouse(WarehouseModel warehouse) {
    setState(() {
      _selectedWarehouse = warehouse;
      _selectedLocation = null; // รีเซ็ตโลเคชั่นที่เลือกเมื่อเลือกคลังใหม่
      _searchLocationController.clear();
      _locationSearchQuery = '';
      _allLocations = []; // ล้างรายการ location เก่า
    });

    // ดึงข้อมูล location ตามคลังที่เลือก
    context.read<WarehouseBloc>().add(SelectWarehouse(warehouse));
  }

  void _selectLocation(LocationModel location) {
    if (_selectedWarehouse != null) {
      setState(() {
        _selectedLocation = location;
      });
      context.read<WarehouseBloc>().add(SelectLocation(location));
    }
  }

  void _saveSelection() {
    if (_selectedWarehouse != null && _selectedLocation != null) {
      // แสดง loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Column(
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

      // บันทึกข้อมูล
      context.read<WarehouseBloc>().add(
            SaveWarehouseAndLocation(
              warehouse: _selectedWarehouse!,
              location: _selectedLocation!,
            ),
          );
    } else {
      // แสดงข้อความเตือนหากยังไม่ได้เลือกคลังหรือพื้นที่เก็บ
      String message = '';
      if (_selectedWarehouse == null) {
        message = 'กรุณาเลือกคลังสินค้าก่อน';
      } else if (_selectedLocation == null) {
        message = 'กรุณาเลือกพื้นที่เก็บก่อน';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<WarehouseModel> _getFilteredWarehouses(List<WarehouseModel> warehouses) {
    if (_warehouseSearchQuery.isEmpty) {
      return warehouses;
    }

    final query = _warehouseSearchQuery.toLowerCase();
    return warehouses.where((warehouse) {
      return warehouse.code.toLowerCase().contains(query) || warehouse.name.toLowerCase().contains(query);
    }).toList();
  }

  List<LocationModel> _getFilteredLocations(List<LocationModel> locations) {
    if (_locationSearchQuery.isEmpty) {
      return locations;
    }

    final query = _locationSearchQuery.toLowerCase();
    return locations.where((location) {
      return location.code.toLowerCase().contains(query) || location.name.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เลือกคลังสินค้าและพื้นที่เก็บ'),
        automaticallyImplyLeading: true, // แสดงปุ่มกลับ
      ),
      body: BlocListener<WarehouseBloc, WarehouseState>(
        listener: (context, state) {
          if (state is WarehouseAndLocationSaved) {
            // ปิด loading dialog ถ้ามี
            Navigator.of(context).popUntil((route) => route.isFirst);

            // นำทางไปยังหน้าหลัก
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          } else if (state is WarehousesLoaded) {
            // เก็บรายการคลังทั้งหมดไว้
            setState(() {
              _allWarehouses = state.warehouses;
            });
          } else if (state is LocationsLoaded) {
            // เก็บรายการ location ทั้งหมดไว้
            setState(() {
              _allLocations = state.locations;
            });
          }
        },
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ส่วนแสดงสถานะการเลือก
                  _buildSelectionStatus(),

                  // ส่วนเลือกคลังสินค้า
                  Row(
                    children: [
                      const Icon(Icons.warehouse, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      const Text(
                        'เลือกคลังสินค้า',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // ปุ่มล้างการเลือกคลัง
                      if (_selectedWarehouse != null)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedWarehouse = null;
                              _selectedLocation = null;
                              _searchWarehouseController.clear();
                              _warehouseSearchQuery = '';
                            });
                          },
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('เลือกใหม่'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildWarehouseSearch(),
                  const SizedBox(height: 8),
                  _buildWarehouseList(),
                  const SizedBox(height: 16),

                  // ส่วนเลือกพื้นที่เก็บ
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      const Text(
                        'เลือกพื้นที่เก็บ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // ปุ่มล้างการเลือกพื้นที่เก็บ
                      if (_selectedLocation != null)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedLocation = null;
                              _searchLocationController.clear();
                              _locationSearchQuery = '';
                            });
                          },
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('เลือกใหม่'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildLocationSearch(),
                  const SizedBox(height: 8),
                  _buildLocationList(),
                  const SizedBox(height: 16),

                  // ปุ่มบันทึก
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionStatus() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // สถานะการเลือกคลัง
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      _selectedWarehouse != null ? Icons.check_circle : Icons.circle_outlined,
                      color: _selectedWarehouse != null ? Colors.green : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'คลังสินค้า',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              // สถานะการเลือกพื้นที่เก็บ
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      _selectedLocation != null ? Icons.check_circle : Icons.circle_outlined,
                      color: _selectedLocation != null ? Colors.green : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'พื้นที่เก็บ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // แสดงข้อมูลที่เลือก
          if (_selectedWarehouse != null || _selectedLocation != null) ...[
            const Divider(height: 16),
            if (_selectedWarehouse != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Text(
                      'คลังที่เลือก: ',
                      style: TextStyle(fontSize: 13),
                    ),
                    Expanded(
                      child: Text(
                        '${_selectedWarehouse!.name} (${_selectedWarehouse!.code})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppTheme.primaryColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            if (_selectedLocation != null)
              Row(
                children: [
                  const Text(
                    'พื้นที่เก็บที่เลือก: ',
                    style: TextStyle(fontSize: 13),
                  ),
                  Expanded(
                    child: Text(
                      '${_selectedLocation!.name} (${_selectedLocation!.code})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppTheme.primaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildWarehouseSearch() {
    return TextField(
      controller: _searchWarehouseController,
      decoration: InputDecoration(
        hintText: 'ค้นหาคลังสินค้า',
        prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
        suffixIcon: _warehouseSearchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                onPressed: () {
                  _searchWarehouseController.clear();
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }

  Widget _buildWarehouseList() {
    return Expanded(
      flex: 1,
      child: BlocBuilder<WarehouseBloc, WarehouseState>(
        builder: (context, state) {
          if (_allWarehouses.isEmpty && state is WarehousesLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ใช้รายการที่เก็บไว้แล้ว
          final warehouses = _allWarehouses;
          final filteredWarehouses = _getFilteredWarehouses(warehouses);

          if (filteredWarehouses.isEmpty) {
            if (_warehouseSearchQuery.isNotEmpty) {
              // กรณีค้นหาแล้วไม่พบข้อมูล
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off, color: AppTheme.textSecondary, size: 40),
                    const SizedBox(height: 8),
                    const Text(
                      'ไม่พบคลังสินค้าที่ค้นหา',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    TextButton(
                      onPressed: () {
                        _searchWarehouseController.clear();
                      },
                      child: const Text('ล้างการค้นหา'),
                    ),
                  ],
                ),
              );
            } else if (state is WarehousesError) {
              // กรณีเกิดข้อผิดพลาด
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppTheme.errorColor,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'เกิดข้อผิดพลาด: ${state.message}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => context.read<WarehouseBloc>().add(FetchWarehouses()),
                      icon: const Icon(Icons.refresh),
                      label: const Text('ลองใหม่'),
                    ),
                  ],
                ),
              );
            } else {
              // กรณีไม่มีข้อมูล
              return const Center(
                child: Text('ไม่พบคลังสินค้า'),
              );
            }
          }

          // แสดงรายการคลัง
          return RawScrollbar(
            controller: _warehouseScrollController,
            thumbVisibility: true,
            thickness: 5,
            radius: const Radius.circular(5),
            thumbColor: AppTheme.primaryColor.withOpacity(0.3),
            child: ListView.builder(
              controller: _warehouseScrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: filteredWarehouses.length,
              itemBuilder: (context, index) {
                final warehouse = filteredWarehouses[index];
                final isSelected = _selectedWarehouse?.code == warehouse.code;

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  elevation: isSelected ? 4 : 1,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: InkWell(
                    onTap: () => _selectWarehouse(warehouse),
                    borderRadius: BorderRadius.circular(12),
                    child: ListTile(
                      title: Text(
                        warehouse.name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        'รหัส: ${warehouse.code}',
                        style: TextStyle(
                          color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                        ),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: isSelected ? AppTheme.primaryColor : AppTheme.primaryColorLight.withOpacity(0.2),
                        child: Icon(
                          Icons.warehouse,
                          color: isSelected ? Colors.white : AppTheme.primaryColor,
                        ),
                      ),
                      trailing:
                          isSelected ? const Icon(Icons.check_circle, color: AppTheme.primaryColor) : const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textSecondary),
                      selected: isSelected,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationSearch() {
    return TextField(
      controller: _searchLocationController,
      decoration: InputDecoration(
        hintText: _selectedWarehouse == null ? 'กรุณาเลือกคลังสินค้าก่อน' : 'ค้นหาพื้นที่เก็บ',
        prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
        suffixIcon: _locationSearchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                onPressed: () {
                  _searchLocationController.clear();
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabled: _selectedWarehouse != null,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        // ขอบสีส้มเมื่อเลือกคลังแล้วแต่ยังไม่ได้เลือกพื้นที่เก็บ
        enabledBorder: _selectedWarehouse != null && _selectedLocation == null
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.orange.shade300, width: 2),
              )
            : null,
      ),
    );
  }

  Widget _buildLocationList() {
    return Expanded(
      flex: 1,
      child: BlocBuilder<WarehouseBloc, WarehouseState>(
        builder: (context, state) {
          if (_selectedWarehouse == null) {
            // ยังไม่ได้เลือกคลัง
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warehouse_outlined,
                    color: AppTheme.textLight.withOpacity(0.5),
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'กรุณาเลือกคลังสินค้าก่อน',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          } else if (_allLocations.isEmpty && state is LocationsLoading) {
            // กำลังโหลดข้อมูล
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ใช้รายการที่เก็บไว้แล้ว
          final locations = _allLocations;
          final filteredLocations = _getFilteredLocations(locations);

          if (filteredLocations.isEmpty) {
            if (_locationSearchQuery.isNotEmpty) {
              // กรณีค้นหาแล้วไม่พบข้อมูล
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off, color: AppTheme.textSecondary, size: 40),
                    const SizedBox(height: 8),
                    const Text(
                      'ไม่พบพื้นที่เก็บที่ค้นหา',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    TextButton(
                      onPressed: () {
                        _searchLocationController.clear();
                      },
                      child: const Text('ล้างการค้นหา'),
                    ),
                  ],
                ),
              );
            } else if (state is LocationsError) {
              // กรณีเกิดข้อผิดพลาด
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppTheme.errorColor,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'เกิดข้อผิดพลาด: ${state.message}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => context.read<WarehouseBloc>().add(FetchLocations(_selectedWarehouse!.code)),
                      icon: const Icon(Icons.refresh),
                      label: const Text('ลองใหม่'),
                    ),
                  ],
                ),
              );
            } else if (_allLocations.isEmpty && state is! LocationsLoading) {
              // ยังไม่มีข้อมูล location
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'กำลังโหลดข้อมูลพื้นที่เก็บ...',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => context.read<WarehouseBloc>().add(FetchLocations(_selectedWarehouse!.code)),
                      icon: const Icon(Icons.refresh),
                      label: const Text('โหลดข้อมูล'),
                    ),
                  ],
                ),
              );
            }
          }

          // แสดงรายการพื้นที่เก็บ
          return RawScrollbar(
            controller: _locationScrollController,
            thumbVisibility: true,
            thickness: 5,
            radius: const Radius.circular(5),
            thumbColor: AppTheme.primaryColor.withOpacity(0.3),
            child: ListView.builder(
              controller: _locationScrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: filteredLocations.length,
              itemBuilder: (context, index) {
                final location = filteredLocations[index];
                final isSelected = _selectedLocation?.code == location.code;

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  elevation: isSelected ? 4 : 1,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: InkWell(
                    onTap: () => _selectLocation(location),
                    borderRadius: BorderRadius.circular(12),
                    child: ListTile(
                      title: Text(
                        location.name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        'รหัส: ${location.code}',
                        style: TextStyle(
                          color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                        ),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: isSelected ? AppTheme.primaryColor : AppTheme.primaryColorLight.withOpacity(0.2),
                        child: Icon(
                          Icons.location_on,
                          color: isSelected ? Colors.white : AppTheme.primaryColor,
                        ),
                      ),
                      trailing:
                          isSelected ? const Icon(Icons.check_circle, color: AppTheme.primaryColor) : const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textSecondary),
                      selected: isSelected,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSaveButton() {
    return BlocBuilder<WarehouseBloc, WarehouseState>(
      builder: (context, state) {
        final bool isLoading = state is WarehousesLoading || state is LocationsLoading;
        final bool isEnabled = _selectedWarehouse != null && _selectedLocation != null;

        return CustomButton(
          text: 'บันทึกและเข้าสู่ระบบ',
          isLoading: isLoading,
          onPressed: isEnabled ? _saveSelection : null,
          icon: const Icon(Icons.save, color: Colors.white, size: 20),
          buttonType: ButtonType.primary,
        );
      },
    );
  }
}
