import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wawa_vansales/blocs/warehouse/warehouse_bloc.dart';
import 'package:wawa_vansales/blocs/warehouse/warehouse_state.dart';
import 'package:wawa_vansales/ui/screens/search_screen/customer_search_screen.dart';

// Import components
import 'sale_header.dart';
import 'barcode_scanner.dart';
import 'sale_item_list.dart';
import 'empty_cart.dart';
import 'sale_summary.dart';

// Import models
import 'package:wawa_vansales/data/models/customer_model.dart';
import 'package:wawa_vansales/data/models/sale_item_model.dart';
import 'package:wawa_vansales/data/models/sale_model.dart';

class SaleScreen extends StatefulWidget {
  const SaleScreen({super.key});

  @override
  State<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  // Controllers
  final _barcodeController = TextEditingController();
  final _barcodeNode = FocusNode();

  // State variables
  SaleModel? _transaction;
  CustomerModel? _selectedCustomer;
  bool _isLoadingProduct = false;
  String _errorMessage = '';
  final List<SaleItemModel> _salesItems = [];

  @override
  void initState() {
    super.initState();
    _initTransaction();

    // Request focus for barcode field after the first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _barcodeNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _barcodeNode.dispose();
    super.dispose();
  }

  void _initTransaction() {
    final now = DateTime.now();
    final docNo = 'S${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';

    setState(() {
      _transaction = SaleModel(
        docno: docNo,
        docdate: now.toString(),
        custcode: '',
        custname: '',
        empcode: '',
        empname: '',
        whcode: '',
        whname: '',
        locationcode: '',
        locationname: '',
        items: [],
      );
    });
  }

  Future<void> _selectCustomer() async {
    // Remove focus from barcode field to prevent keyboard issues
    _barcodeNode.unfocus();

    // Navigate to customer search screen
    final CustomerModel? result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CustomerSearchScreen())) as CustomerModel?;

    if (result != null) {
      setState(() {
        _selectedCustomer = result;
        if (_transaction != null) {
          _transaction!.custcode = result.code ?? '';
          _transaction!.custname = result.name ?? '';
        }
      });
    }

    // Refocus barcode field after returning
    _barcodeNode.requestFocus();
  }

  Future<void> _onBarcodeScanned(String barcode) async {
    if (barcode.isEmpty) return;

    // Check if customer is selected
    if (_selectedCustomer == null) {
      setState(() {
        _errorMessage = 'กรุณาเลือกลูกค้าก่อนทำการสแกนบาร์โค้ด';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกลูกค้าก่อนทำการสแกนบาร์โค้ด'),
          duration: Duration(seconds: 2),
        ),
      );

      return;
    }

    setState(() {
      _isLoadingProduct = true;
      _errorMessage = '';
    });

    try {
      // Mock API call with delay
      await Future.delayed(const Duration(milliseconds: 300));

      // Simulate product fetch from API
      final mockProduct = SaleItemModel(
        itemCode: barcode,
        itemName: 'สินค้า $barcode',
        quantity: 1,
        price: 100.0,
        barcode: barcode,
        unitCode: 'PCS',
        unitName: 'ชิ้น',
      );

      setState(() {
        // Add item or increase quantity if already exists
        final existingItemIndex = _salesItems.indexWhere((item) => item.itemCode == barcode);

        if (existingItemIndex >= 0) {
          // Update existing item quantity
          final updatedItem = _salesItems[existingItemIndex];
          updatedItem.quantity = (updatedItem.quantity ?? 0) + 1;

          // Update UI with temporary message
          _errorMessage = 'เพิ่มจำนวนสินค้า: ${updatedItem.itemName}';
        } else {
          // Add new item
          _salesItems.add(mockProduct);

          // Update transaction items
          if (_transaction != null) {
            _transaction!.items = _salesItems;
          }
        }

        _isLoadingProduct = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'ไม่พบข้อมูลสินค้า: $barcode';
        _isLoadingProduct = false;
      });
    }

    // We'll let the BarcodeScanner widget handle refocusing
    // after processing is complete
  }

  void _saveTransaction() async {
    // Validate required fields
    if (_selectedCustomer == null) {
      _showErrorSnackBar('กรุณาเลือกลูกค้าก่อนบันทึกรายการ');
      return;
    }

    if (_salesItems.isEmpty) {
      _showErrorSnackBar('กรุณาเพิ่มสินค้าอย่างน้อย 1 รายการ');
      return;
    }

    final warehouseState = context.read<WarehouseBloc>().state;
    if (warehouseState is! WarehouseSelectionComplete) {
      _showErrorSnackBar('กรุณาเลือกคลังก่อนบันทึกรายการ');
      return;
    }

    // Show loading
    setState(() => _isLoadingProduct = true);

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Show success dialog
      if (!mounted) return;

      setState(() => _isLoadingProduct = false);

      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoadingProduct = false);
      _showErrorSnackBar('เกิดข้อผิดพลาด: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('บันทึกรายการสำเร็จ'),
        content: Text('บันทึกรายการขายเลขที่ ${_transaction?.docno} เรียบร้อยแล้ว'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
            },
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ขายสินค้า'),
        actions: [
          if (_salesItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveTransaction,
            ),
        ],
      ),
      // ไม่ต้องการ resize เมื่อคีย์บอร์ดปรากฏ
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            // Header section with customer info
            SaleHeader(
              transaction: _transaction,
              selectedCustomer: _selectedCustomer,
              onSelectCustomer: _selectCustomer,
            ),

            // Barcode scanner section
            BarcodeScanner(
              controller: _barcodeController,
              focusNode: _barcodeNode,
              isLoading: _isLoadingProduct,
              errorMessage: _errorMessage,
              onSubmitted: _onBarcodeScanned,
            ),

            // Divider
            const Divider(height: 1),

            // Item list or empty state
            Expanded(
              child: _salesItems.isEmpty ? const EmptyCart() : SaleItemList(items: _salesItems),
            ),

            // Summary section (visible when items exist)
            if (_salesItems.isNotEmpty) SaleSummary(items: _salesItems),
          ],
        ),
      ),
    );
  }
}
