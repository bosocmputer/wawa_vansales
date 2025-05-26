// lib/blocs/return_product/return_product_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:wawa_vansales/blocs/return_product/return_product_event.dart';
import 'package:wawa_vansales/blocs/return_product/return_product_state.dart';
import 'package:wawa_vansales/data/models/cart_item_model.dart';
import 'package:wawa_vansales/data/models/return_product/return_product_model.dart';
import 'package:wawa_vansales/data/repositories/return_product_repository.dart';
import 'package:wawa_vansales/utils/local_storage.dart';

class ReturnProductBloc extends Bloc<ReturnProductEvent, ReturnProductState> {
  final ReturnProductRepository _returnProductRepository;
  final LocalStorage _localStorage;
  final Logger _logger = Logger();

  ReturnProductBloc({
    required ReturnProductRepository returnProductRepository,
    required LocalStorage localStorage,
  })  : _returnProductRepository = returnProductRepository,
        _localStorage = localStorage,
        super(ReturnProductInitial()) {
    on<SelectCustomerForReturn>(_onSelectCustomer);
    on<FetchSaleDocuments>(_onFetchSaleDocuments);
    on<SelectSaleDocument>(_onSelectSaleDocument);
    on<FetchSaleDocumentDetails>(_onFetchSaleDocumentDetails);
    on<AddItemToReturnCart>(_onAddItem);
    on<RemoveItemFromReturnCart>(_onRemoveItem);
    on<UpdateReturnItemQuantity>(_onUpdateQuantity);
    on<ClearReturnCart>(_onClearCart);
    on<SubmitReturn>(_onSubmitReturn);
    on<UpdateReturnStep>(_onUpdateStep);
    on<ResetReturnProductState>(_onResetState);
  }

  // เลือกลูกค้า
  void _onSelectCustomer(SelectCustomerForReturn event, Emitter<ReturnProductState> emit) {
    if (state is ReturnProductInitial) {
      emit(ReturnProductLoaded(selectedCustomer: event.customer));
    } else if (state is ReturnProductLoaded) {
      final currentState = state as ReturnProductLoaded;
      emit(currentState.copyWith(
        selectedCustomer: event.customer,
        currentStep: 0,
      ));
    }
  }

  // รีเซ็ตสถานะทั้งหมด
  void _onResetState(ResetReturnProductState event, Emitter<ReturnProductState> emit) {
    emit(ReturnProductInitial());
  }

  // ดึงรายการเอกสารขาย
  Future<void> _onFetchSaleDocuments(FetchSaleDocuments event, Emitter<ReturnProductState> emit) async {
    if (state is ReturnProductLoaded) {
      final currentState = state as ReturnProductLoaded;

      emit(ReturnProductLoading());

      try {
        final saleDocuments = await _returnProductRepository.getSaleDocuments(
          customerCode: event.customerCode,
          search: event.search,
          fromDate: event.fromDate,
          toDate: event.toDate,
        );

        emit(currentState.copyWith(
          saleDocuments: saleDocuments,
          currentStep: 1,
        ));
      } catch (e) {
        _logger.e('Error fetching sale documents: $e');
        emit(ReturnProductError(e.toString()));
        emit(currentState); // กลับไปสถานะเดิม
      }
    }
  }

  // เลือกเอกสารขาย
  void _onSelectSaleDocument(SelectSaleDocument event, Emitter<ReturnProductState> emit) async {
    if (state is ReturnProductLoaded) {
      final currentState = state as ReturnProductLoaded;

      emit(currentState.copyWith(selectedSaleDocument: event.saleDocument));

      add(FetchSaleDocumentDetails(event.saleDocument.docNo));
    }
  }

  // ดึงรายละเอียดเอกสารขาย
  Future<void> _onFetchSaleDocumentDetails(FetchSaleDocumentDetails event, Emitter<ReturnProductState> emit) async {
    if (state is ReturnProductLoaded) {
      final currentState = state as ReturnProductLoaded;

      emit(ReturnProductLoading());

      try {
        final details = await _returnProductRepository.getSaleDocumentDetails(docNo: event.docNo);

        emit(currentState.copyWith(
          documentDetails: details,
          // ไม่เปลี่ยน step อัตโนมัติ เพื่อให้ยังอยู่ที่หน้าเอกสารขาย
          // currentStep: 2,
        ));
      } catch (e) {
        _logger.e('Error fetching sale document details: $e');
        emit(ReturnProductError(e.toString()));
        emit(currentState); // กลับไปสถานะเดิม
      }
    }
  }

  // เพิ่มสินค้าเข้าตะกร้ารับคืน
  Future<void> _onAddItem(AddItemToReturnCart event, Emitter<ReturnProductState> emit) async {
    if (state is ReturnProductLoaded) {
      final currentState = state as ReturnProductLoaded;
      final List<CartItemModel> updatedItems = List.from(currentState.returnItems);

      // Add additional debugging to check for duplicate logic
      _logger.i('DUPLICATE CHECK: Adding item ${event.item.itemCode} with unit ${event.item.unitCode}');
      _logger.i('DUPLICATE CHECK: Current returnItems count: ${currentState.returnItems.length}');
      for (int i = 0; i < currentState.returnItems.length; i++) {
        _logger.i('DUPLICATE CHECK: Item $i: ${currentState.returnItems[i].itemCode}, unit: ${currentState.returnItems[i].unitCode}');
      }

      // เช็คว่าสินค้านี้มีในเอกสารขายหรือไม่ โดยตรวจสอบทั้ง itemCode และ unitCode
      final existsInDoc = currentState.documentDetails.any((detail) => detail.itemCode == event.item.itemCode && detail.unitCode == event.item.unitCode);

      if (!existsInDoc) {
        // ไม่ emit ReturnProductError เพื่อป้องกัน SnackBar ซ้ำซ้อน
        // การตรวจสอบและแสดงข้อความเตือนนี้จะทำที่ UI layer แทน
        _logger.i('Item not in original sale document: ${event.item.itemCode} with unit ${event.item.unitCode}');
        return;
      }

      _logger.i('Adding item to return cart: ${event.item.itemCode} with unit ${event.item.unitCode}');

      // หา refRow จากรายการสินค้าในเอกสารขาย โดยตรวจสอบทั้ง itemCode และ unitCode
      // final originalDetail = currentState.documentDetails.firstWhere(
      //   (detail) => detail.itemCode == event.item.itemCode && detail.unitCode == event.item.unitCode,
      // );

      // กำหนดค่า refRow จากเอกสารขายเดิม
      String refRow = "0";
      // refRow = originalDetail.refRow;

      // เช็คว่ามีในตะกร้าแล้วหรือยัง
      final existingIndex = updatedItems.indexWhere(
        (item) => item.itemCode == event.item.itemCode && item.unitCode == event.item.unitCode,
      );

      if (existingIndex != -1) {
        // ถ้ามีแล้ว เพิ่มจำนวน
        final existingItem = updatedItems[existingIndex];
        final existingQty = double.tryParse(existingItem.qty) ?? 0;
        final qtyToAdd = double.tryParse(event.item.qty) ?? 1.0;

        // คำนวณราคารวม
        final price = double.tryParse(existingItem.price) ?? 0;
        final newQty = existingQty + qtyToAdd;
        final newAmount = price * newQty;

        updatedItems[existingIndex] = existingItem.copyWith(
          qty: newQty.toString(),
          sumAmount: newAmount.toString(),
        );

        _logger.i('Updated existing item quantity: ${newQty.toString()}');
        _logger.i('DUPLICATE CHECK: Found existing item ${event.item.itemCode} with unit ${event.item.unitCode}');
      } else {
        _logger.i('DUPLICATE CHECK: Item ${event.item.itemCode} with unit ${event.item.unitCode} is not in cart yet');
        // เพิ่มรายการใหม่
        final warehouse = await _localStorage.getWarehouse();
        final location = await _localStorage.getLocation();

        if (warehouse != null && location != null) {
          final newItem = event.item.copyWith(
            whCode: warehouse.code,
            shelfCode: location.code,
            refRow: refRow, // กำหนดค่า refRow ให้กับ item ใหม่
          );
          // ตรวจสอบและอัพเดตค่า sumAmount ให้ถูกต้อง
          final price = double.tryParse(newItem.price) ?? 0;
          final qty = double.tryParse(newItem.qty) ?? 1;
          final amount = price * qty;

          final itemWithAmount = newItem.copyWith(
            sumAmount: amount.toString(),
          );

          updatedItems.add(itemWithAmount);
          _logger.i('Added new item: ${itemWithAmount.itemCode}, qty: ${itemWithAmount.qty}, sumAmount: ${itemWithAmount.sumAmount}, refRow: ${itemWithAmount.refRow}');
        } else {
          emit(const ReturnProductError('กรุณาเลือกคลังและพื้นที่เก็บก่อนเพิ่มสินค้า'));
          return;
        }
      }

      // คำนวณยอดรวมใหม่
      final totalAmount = _calculateTotal(updatedItems);
      _logger.i('New total amount: $totalAmount, items count: ${updatedItems.length}');

      emit(currentState.copyWith(
        returnItems: updatedItems,
        totalAmount: totalAmount,
      ));
    }
  }

  // ลบสินค้าออกจากตะกร้า
  void _onRemoveItem(RemoveItemFromReturnCart event, Emitter<ReturnProductState> emit) {
    if (state is ReturnProductLoaded) {
      final currentState = state as ReturnProductLoaded;
      final updatedItems =
          currentState.returnItems.where((item) => !(item.itemCode == event.itemCode && item.barcode == event.barcode && item.unitCode == event.unitCode)).toList();

      final totalAmount = _calculateTotal(updatedItems);

      emit(currentState.copyWith(
        returnItems: updatedItems,
        totalAmount: totalAmount,
      ));
    }
  }

  // อัพเดทจำนวนสินค้า
  void _onUpdateQuantity(UpdateReturnItemQuantity event, Emitter<ReturnProductState> emit) {
    if (state is ReturnProductLoaded) {
      final currentState = state as ReturnProductLoaded;
      final updatedItems = currentState.returnItems.map((item) {
        if (item.itemCode == event.itemCode && item.barcode == event.barcode && item.unitCode == event.unitCode) {
          return item.copyWith(qty: event.quantity.toString());
        }
        return item;
      }).toList();

      final totalAmount = _calculateTotal(updatedItems);

      emit(currentState.copyWith(
        returnItems: updatedItems,
        totalAmount: totalAmount,
      ));
    }
  }

  // ล้างตะกร้า
  void _onClearCart(ClearReturnCart event, Emitter<ReturnProductState> emit) {
    if (state is ReturnProductLoaded) {
      final currentState = state as ReturnProductLoaded;
      emit(currentState.copyWith(
        returnItems: [],
        totalAmount: 0,
      ));
    }
  }

  // บันทึกการรับคืน
  Future<void> _onSubmitReturn(SubmitReturn event, Emitter<ReturnProductState> emit) async {
    if (state is ReturnProductLoaded) {
      final currentState = state as ReturnProductLoaded;

      // ตรวจสอบข้อมูลที่จำเป็น
      if (currentState.selectedCustomer == null) {
        emit(const ReturnProductError('กรุณาเลือกลูกค้า'));
        return;
      }

      if (currentState.selectedSaleDocument == null) {
        emit(const ReturnProductError('กรุณาเลือกเอกสารขายอ้างอิง'));
        return;
      }

      if (currentState.returnItems.isEmpty) {
        emit(const ReturnProductError('กรุณาเพิ่มสินค้าในรายการรับคืน'));
        return;
      }

      emit(ReturnSubmitting());

      try {
        // ดึงข้อมูลที่จำเป็น
        final user = await _localStorage.getUserData();
        final now = DateTime.now();
        final docDate = DateFormat('yyyy-MM-dd').format(now);
        final docTime = DateFormat('HH:mm').format(now);

        // คำนวณยอดรวมใหม่จากรายการสินค้าในตะกร้า
        final calculatedTotal = _calculateTotal(currentState.returnItems);
        final totalAmountStr = calculatedTotal.toString();

        // สร้าง transaction model
        final transaction = ReturnProductModel(
          custCode: currentState.selectedCustomer!.code!,
          empCode: user?.userCode ?? 'TEST',
          docDate: docDate,
          docTime: docTime,
          docNo: event.docNo,
          refDocDate: currentState.selectedSaleDocument!.docDate,
          refDocNo: currentState.selectedSaleDocument!.docNo,
          refAmount: currentState.selectedSaleDocument!.totalAmount,
          items: currentState.returnItems,
          paymentDetail: currentState.payments,
          transferAmount: '0',
          creditAmount: '0',
          cashAmount: '0',
          cardAmount: '0',
          totalAmount: totalAmountStr,
          totalValue: totalAmountStr,
          remark: event.remark,
        );

        // บันทึกข้อมูล
        final success = await _returnProductRepository.saveReturnProduct(transaction);

        if (success) {
          emit(ReturnSubmitSuccess(
            documentNumber: event.docNo,
            customer: currentState.selectedCustomer!,
            items: currentState.returnItems,
            payments: currentState.payments,
            totalAmount: calculatedTotal,
            refSaleDocument: currentState.selectedSaleDocument!,
          ));
        } else {
          emit(const ReturnProductError('ไม่สามารถบันทึกการรับคืนสินค้าได้'));
        }
      } catch (e) {
        _logger.e('Submit return error: $e');
        emit(ReturnProductError('เกิดข้อผิดพลาด: ${e.toString()}'));
      }
    }
  }

  // อัปเดต step
  void _onUpdateStep(UpdateReturnStep event, Emitter<ReturnProductState> emit) {
    if (state is ReturnProductLoaded) {
      final currentState = state as ReturnProductLoaded;
      emit(currentState.copyWith(currentStep: event.step));
    }
  }

  // คำนวณยอดรวม
  double _calculateTotal(List<CartItemModel> items) {
    return items.fold(0, (sum, item) => sum + item.totalAmount);
  }
}
