// lib/ui/screens/sale/sale_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wawa_vansales/blocs/product_detail/product_detail_bloc.dart';
import 'package:wawa_vansales/blocs/product_detail/product_detail_event.dart';
import 'package:wawa_vansales/blocs/product_detail/product_detail_state.dart';
import 'package:wawa_vansales/blocs/warehouse/warehouse_bloc.dart';
import 'package:wawa_vansales/blocs/warehouse/warehouse_state.dart';
import 'package:wawa_vansales/data/models/product_detail_model.dart';
import 'package:wawa_vansales/data/models/receipt_model.dart';
import 'package:wawa_vansales/data/services/printer_service.dart';
import 'package:wawa_vansales/ui/screens/sale/receipt_template.dart';
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

  final PrinterService _printerService = PrinterService();

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

    // เรียกใช้ ProductDetailBloc เพื่อดึงข้อมูลสินค้า
    context.read<ProductDetailBloc>().add(
          FetchProductByBarcode(
            barcode: barcode,
            customerCode: _selectedCustomer!.code!,
          ),
        );
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
      await Future.delayed(const Duration(seconds: 2));

      // Show success dialog
      if (!mounted) return;

      setState(() => _isLoadingProduct = false);

      // แสดง dialog ถามว่าต้องการพิมพ์ใบเสร็จหรือไม่
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('บันทึกรายการสำเร็จ'),
          content: Text('บันทึกรายการขายเลขที่ ${_transaction?.docno} เรียบร้อยแล้ว\n\nต้องการพิมพ์ใบเสร็จหรือไม่?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back
              },
              child: const Text('ไม่พิมพ์'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                await _printReceipt(); // พิมพ์ใบเสร็จ

                _initTransaction();
              },
              child: const Text('พิมพ์ใบเสร็จ'),
            ),
          ],
        ),
      );
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

  // เพิ่มสินค้าจาก ProductDetailModel เข้าไปใน _salesItems
  void _addProductToSaleItems(ProductDetailModel product) {
    final existingItemIndex = _salesItems.indexWhere((item) => item.barcode == product.barcode);

    if (existingItemIndex >= 0) {
      // Update existing item quantity
      setState(() {
        final updatedItem = _salesItems[existingItemIndex];
        updatedItem.quantity = (int.parse(updatedItem.quantity ?? '0') + 1).toString();
        _errorMessage = 'เพิ่มจำนวนสินค้า: ${updatedItem.itemName}';
      });
    } else {
      // Convert ProductDetailModel to SaleItemModel
      final saleItem = SaleItemModel(
        itemCode: product.itemCode,
        itemName: product.itemName,
        quantity: '1',
        price: int.parse(product.price).toString(),
        barcode: product.barcode,
        unitCode: product.unitCode,
        unitName: product.unitCode,
      );

      setState(() {
        // Add new item
        _salesItems.add(saleItem);

        // Update transaction items
        if (_transaction != null) {
          _transaction!.items = _salesItems;
        }
      });
    }
  }

  void _cancelSearch() {
    setState(() {
      _isLoadingProduct = false;
      _errorMessage = 'ยกเลิกการค้นหา';
    });

    // รีเซ็ต state ใน ProductDetailBloc ด้วย
    context.read<ProductDetailBloc>().add(ResetProductDetail());
  }

  Future<void> _printReceipt() async {
    if (_transaction == null) return;

    setState(() => _isLoadingProduct = true);

    try {
      // สร้าง Receipt Model

      final receipt = ReceiptModel(
        date: _transaction?.docdate,
        docNo: _transaction?.docno,
        customerName: _transaction?.custname,
        customerCode: _transaction?.custcode,
        warehouseName: _transaction?.whname,
        employeeName: _transaction?.empname,
        items: _transaction!.items!,
        totalAmount: _transaction!.totalamount,
        paymentMethod: 'เงินสด',
      );

      // สร้างรูปภาพใบเสร็จ
      final imageBytes = await ReceiptTemplate.generateReceiptImage(receipt);

      // พิมพ์
      final success = await _printerService.printImageBytes(imageBytes);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('พิมพ์ใบเสร็จสำเร็จ')),
        );
      } else {
        throw Exception('ไม่สามารถเชื่อมต่อเครื่องพิมพ์');
      }
    } catch (e) {
      debugPrint('Error printing receipt: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('พิมพ์ใบเสร็จไม่สำเร็จ: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoadingProduct = false);
    }
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
      body: BlocListener<ProductDetailBloc, ProductDetailState>(
        listener: (context, state) {
          if (state is ProductDetailLoading) {
            setState(() {
              _isLoadingProduct = true;
            });
          } else if (state is ProductDetailLoaded) {
            setState(() {
              _isLoadingProduct = false;
              _errorMessage = '';
            });
            // เพิ่มสินค้าลงในรายการ
            _addProductToSaleItems(state.product);
          } else if (state is ProductDetailNotFound) {
            setState(() {
              _isLoadingProduct = false;
              _errorMessage = 'ไม่พบข้อมูลสินค้า: ${state.barcode}';
            });
          } else if (state is ProductDetailError) {
            setState(() {
              _isLoadingProduct = false;
              _errorMessage = 'เกิดข้อผิดพลาด: ${state.message}';
            });
          }
        },
        child: SafeArea(
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
                onCancel: _cancelSearch,
              ),

              // Item list or empty state
              Expanded(
                child: _salesItems.isEmpty ? const EmptyCart() : SaleItemList(items: _salesItems),
              ),

              // Summary section (visible when items exist)
              if (_salesItems.isNotEmpty) SaleSummary(items: _salesItems),
            ],
          ),
        ),
      ),
    );
  }
}
