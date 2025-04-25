import 'package:flutter/material.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/models/location_model.dart';
import 'package:wawa_vansales/ui/screens/warehouse/emty_state_widget.dart';
import 'package:wawa_vansales/ui/screens/warehouse/location_cart.dart';
import 'package:wawa_vansales/ui/screens/warehouse/search_box.dart';

class LocationListView extends StatefulWidget {
  final List<LocationModel> locations;
  final LocationModel? selectedLocation;
  final Function(LocationModel) onLocationSelected;
  final bool isLoading;

  const LocationListView({
    super.key,
    required this.locations,
    required this.selectedLocation,
    required this.onLocationSelected,
    required this.isLoading,
  });

  @override
  State<LocationListView> createState() => _LocationListViewState();
}

class _LocationListViewState extends State<LocationListView> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<LocationModel> get _filteredLocations {
    if (_searchQuery.isEmpty) {
      return widget.locations;
    }

    final query = _searchQuery.toLowerCase();
    return widget.locations.where((location) {
      return location.code.toLowerCase().contains(query) || location.name.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Handle loading state
    if (widget.isLoading && widget.locations.isEmpty) {
      return _buildLoadingState();
    }

    // Handle empty state
    if (widget.locations.isEmpty) {
      return _buildEmptyState();
    }

    return Stack(
      children: [
        Column(
          children: [
            // Search and selected count
            _buildSearchHeader(),

            // No results message
            if (_searchQuery.isNotEmpty && _filteredLocations.isEmpty)
              Expanded(
                child: EmptyStateWidget(
                  icon: Icons.search_off,
                  message: 'ไม่พบพื้นที่เก็บที่ค้นหา',
                  actionLabel: 'ล้างการค้นหา',
                  onAction: () {
                    _searchController.clear();
                  },
                ),
              ),

            // Location list
            if (_filteredLocations.isNotEmpty)
              Expanded(
                child: _buildLocationList(),
              ),
          ],
        ),

        // Selected floating badge
        if (widget.selectedLocation != null) _buildSelectedBadge(),
      ],
    );
  }

  Widget _buildSearchHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search box
          SearchBox(
            controller: _searchController,
            hintText: 'ค้นหาพื้นที่เก็บ',
            prefixIcon: Icons.location_on,
          ),

          // Search results info
          if (_searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Text(
                    'ผลการค้นหา ${_filteredLocations.length} รายการ',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      _searchController.clear();
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('ล้างการค้นหา'),
                  ),
                ],
              ),
            ),

          // Selected count
          if (_searchQuery.isEmpty && widget.locations.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Text(
                    'พื้นที่เก็บทั้งหมด ${widget.locations.length} รายการ',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationList() {
    return RawScrollbar(
      thumbVisibility: true,
      radius: const Radius.circular(5),
      thickness: 5,
      thumbColor: AppTheme.primaryColor.withOpacity(0.3),
      controller: _scrollController,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 80.0), // Bottom padding for selected badge
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _filteredLocations.length,
        itemBuilder: (context, index) {
          final location = _filteredLocations[index];
          final isSelected = widget.selectedLocation?.code == location.code;

          return LocationCard(
            location: location,
            isSelected: isSelected,
            onSelected: () => widget.onLocationSelected(location),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('กำลังโหลดข้อมูลพื้นที่เก็บ...'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const EmptyStateWidget(
      icon: Icons.location_off,
      message: 'ไม่พบข้อมูลพื้นที่เก็บ',
      subMessage: 'คลังนี้อาจไม่มีพื้นที่เก็บที่กำหนดไว้ หรืออาจเกิดข้อผิดพลาดในการโหลดข้อมูล',
    );
  }

  Widget _buildSelectedBadge() {
    if (widget.selectedLocation == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'เลือก: ${widget.selectedLocation!.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
