import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wawa_vansales/blocs/return_product_search/product_return_search_bloc.dart';
import 'package:wawa_vansales/blocs/return_product_search/product_return_search_event.dart';
import 'package:wawa_vansales/blocs/return_product_search/product_return_search_state.dart';
import 'package:wawa_vansales/blocs/product_detail/product_detail_bloc.dart';
import 'package:wawa_vansales/blocs/product_detail/product_detail_event.dart';
import 'package:wawa_vansales/blocs/product_detail/product_detail_state.dart';
import 'package:wawa_vansales/config/app_theme.dart';
import 'package:wawa_vansales/data/models/return_product/product_return_model.dart';
import 'package:wawa_vansales/data/models/cart_item_model.dart';

class ProductReturnSearchScreen extends StatefulWidget {
  final String customerCode;

  const ProductReturnSearchScreen({
    super.key,
    required this.customerCode,
  });

  @override
  State<ProductReturnSearchScreen> createState() => _ProductReturnSearchScreenState();
}

class _ProductReturnSearchScreenState extends State<ProductReturnSearchScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  String _searchQuery = '';
  Timer? _debounce;
  ProductReturnModel? _selectedProduct;
  bool _isLoadingDetail = false;
  bool _hasReturnedResult = false;

  @override
  void initState() {
    super.initState();

    // Setup search listener
    _searchController.addListener(_onSearchChanged);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductReturnSearchBloc>().add(FetchProductsReturnSearch(
            custCode: widget.customerCode,
          ));
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Search with debounce to reduce API calls
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      if (_searchQuery != _searchController.text) {
        setState(() {
          _searchQuery = _searchController.text;
        });
        context.read<ProductReturnSearchBloc>().add(SetProductReturnSearchQuery(_searchQuery, widget.customerCode));
      }
    });
  }

  // เมื่อเลือกสินค้า ให้ดึงราคา
  void _onProductSelected(ProductReturnModel product) async {
    // ตั้งค่า flag เพื่อป้องกันการเรียกใช้ซ้ำ
    if (_isLoadingDetail) return;

    setState(() {
      _selectedProduct = product;
      _isLoadingDetail = true;
    });

    // ถ้าราคาเป็น 0 ให้ดึงจาก ProductDetailBloc
    if (product.price == 0) {
      context.read<ProductDetailBloc>().add(
            FetchProductByBarcode(
              barcode: product.barcode,
              customerCode: widget.customerCode,
            ),
          );
    } else {
      // ถ้าราคาไม่เป็น 0 ให้ใช้ราคาเดิม (ป้องกันการ pop กลับไปที่หน้าที่แล้วส่ง event ซ้ำ)
      Future.delayed(const Duration(milliseconds: 100), () {
        _returnProductWithPrice(product.price);
      });
    }
  }

  void _returnProductWithPrice(double price) {
    if (_selectedProduct != null) {
      final cartItem = CartItemModel(
        itemCode: _selectedProduct!.itemCode,
        itemName: _selectedProduct!.itemName,
        barcode: _selectedProduct!.barcode,
        price: price.toString(),
        sumAmount: price.toString(),
        unitCode: _selectedProduct!.unitCode,
        whCode: '',
        shelfCode: '',
        ratio: _selectedProduct!.ratio,
        standValue: _selectedProduct!.standValue,
        divideValue: _selectedProduct!.divideValue,
        qty: '1',
        refRow: '0',
      );

      // ป้องกันการส่งข้อมูลกลับซ้ำหลายครั้ง
      if (mounted && !_hasReturnedResult) {
        _hasReturnedResult = true; // เพิ่ม flag เพื่อป้องกันการ pop ซ้ำ

        // ใช้ Navigator.pop เพียงครั้งเดียว
        Navigator.of(context).pop(cartItem);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ค้นหาสินค้ารับคืน'),
      ),
      body: Column(
        children: [
          // Search field
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'ค้นหาสินค้า',
                hintText: 'ค้นหาจากรหัส, ชื่อสินค้า หรือบาร์โค้ด',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Product list
          Expanded(
            child: BlocListener<ProductDetailBloc, ProductDetailState>(
              listenWhen: (previous, current) {
                // ทำงานเฉพาะเมื่อมีการเปลี่ยนจาก state อื่นเป็น ProductDetailLoaded
                return current is ProductDetailLoaded && previous is! ProductDetailLoaded;
              },
              listener: (context, state) {
                if (state is ProductDetailLoaded) {
                  setState(() {
                    _isLoadingDetail = false;
                  });

                  // ส่งข้อมูลพร้อมราคากลับไป
                  final price = double.tryParse(state.product.price) ?? 0;
                  _returnProductWithPrice(price);
                } else if (state is ProductDetailError) {
                  setState(() {
                    _isLoadingDetail = false;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('เกิดข้อผิดพลาด: ${state.message}'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                } else if (state is ProductDetailNotFound) {
                  setState(() {
                    _isLoadingDetail = false;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ไม่พบข้อมูลราคาสินค้า'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              },
              child: BlocBuilder<ProductReturnSearchBloc, ProductReturnSearchState>(
                builder: (context, state) {
                  if (state is ProductReturnSearchLoading || _isLoadingDetail) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (state is ProductReturnSearchLoaded || state is ProductReturnSelected) {
                    List<ProductReturnModel> products = [];

                    if (state is ProductReturnSearchLoaded) {
                      products = state.products;
                    } else if (state is ProductReturnSelected) {
                      products = state.products;
                    }

                    if (products.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.search_off_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'ไม่พบข้อมูลสินค้ารับคืน',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_searchQuery.isNotEmpty)
                              ElevatedButton.icon(
                                onPressed: () {
                                  _searchController.clear();
                                },
                                icon: const Icon(Icons.clear),
                                label: const Text('ล้างการค้นหา'),
                              ),
                          ],
                        ),
                      );
                    }

                    return Scrollbar(
                      controller: _scrollController,
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(
                                color: Colors.transparent,
                                width: 1,
                              ),
                            ),
                            elevation: 1,
                            child: InkWell(
                              onTap: () => _onProductSelected(product),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // Product code and unit
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '${product.barcode} / ${product.unitCode}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        // Item code
                                        Text(
                                          'รหัสสินค้า: ${product.itemCode}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Product name
                                    Text(
                                      product.itemName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  } else if (state is ProductReturnSearchError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppTheme.errorColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'เกิดข้อผิดพลาด: ${state.message}',
                            style: const TextStyle(
                              color: AppTheme.errorColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              context.read<ProductReturnSearchBloc>().add(FetchProductsReturnSearch(
                                    custCode: widget.customerCode,
                                    searchQuery: _searchQuery,
                                  ));
                              setState(() {
                                _hasReturnedResult = false; // รีเซ็ต flag เมื่อกดลองใหม่
                              });
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('ลองใหม่'),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
