// lib/blocs/return_product/return_product_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:wawa_vansales/blocs/return_product/return_product_event.dart';
import 'package:wawa_vansales/blocs/return_product/return_product_state.dart';
import 'package:wawa_vansales/data/models/cart_item_model.dart';
import 'package:wawa_vansales/data/models/payment_model.dart';
import 'package:wawa_vansales/data/models/return_product/return_product_model.dart';
import 'package:wawa_vansales/data/repositories/return_product_repository.dart';
import 'package:wawa_vansales/utils/global.dart';
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
    on<AddReturnPayment>(_onAddPayment);
    on<RemoveReturnPayment>(_onRemovePayment);
    on<SubmitReturn>(_onSubmitReturn);
    on<UpdateReturnStep>(_onUpdateStep);
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
          currentStep: 2,
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

      // เช็คว่าสินค้านี้มีในเอกสารขายหรือไม่
      final existsInDoc = currentState.documentDetails.any((detail) => detail.itemCode == event.item.itemCode && detail.unitCode == event.item.unitCode);

      if (!existsInDoc) {
        emit(ReturnProductError('รหัสสินค้า ${event.item.itemCode} ไม่มีในบิลขาย'));
        return;
      }

      // เช็คว่ามีในตะกร้าแล้วหรือยัง
      final existingIndex = updatedItems.indexWhere(
        (item) => item.itemCode == event.item.itemCode && item.barcode == event.item.barcode && item.unitCode == event.item.unitCode,
      );

      if (existingIndex != -1) {
        // ถ้ามีแล้ว เพิ่มจำนวน
        final existingItem = updatedItems[existingIndex];
        final existingQty = double.tryParse(existingItem.qty) ?? 0;
        final qtyToAdd = double.tryParse(event.item.qty) ?? 1.0;

        updatedItems[existingIndex] = existingItem.copyWith(
          qty: (existingQty + qtyToAdd).toString(),
        );
      } else {
        // เพิ่มรายการใหม่
        final warehouse = await _localStorage.getWarehouse();
        final location = await _localStorage.getLocation();

        if (warehouse != null && location != null) {
          final newItem = event.item.copyWith(
            whCode: warehouse.code,
            shelfCode: location.code,
          );
          updatedItems.add(newItem);
        } else {
          emit(const ReturnProductError('กรุณาเลือกคลังและพื้นที่เก็บก่อนเพิ่มสินค้า'));
          return;
        }
      }

      // คำนวณยอดรวม
      final totalAmount = _calculateTotal(updatedItems);

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

  // เพิ่มการชำระเงิน
// เพิ่มการชำระเงิน
  void _onAddPayment(AddReturnPayment event, Emitter<ReturnProductState> emit) {
    if (state is ReturnProductLoaded) {
      final currentState = state as ReturnProductLoaded;
      final updatedPayments = List<PaymentModel>.from(currentState.payments);

      // ตรวจสอบว่ามีการชำระเงินประเภทนี้แล้วหรือไม่
      final existingIndex = updatedPayments.indexWhere(
        (payment) => payment.payType == event.payment.payType,
      );

      if (existingIndex != -1) {
        // ถ้ามีแล้ว แทนที่ด้วยข้อมูลใหม่
        updatedPayments[existingIndex] = event.payment;
      } else {
        // ถ้ายังไม่มี เพิ่มเข้าไปใหม่
        updatedPayments.add(event.payment);
      }

      emit(currentState.copyWith(
        payments: updatedPayments,
      ));
    }
  }

  // ลบการชำระเงิน
  void _onRemovePayment(RemoveReturnPayment event, Emitter<ReturnProductState> emit) {
    if (state is ReturnProductLoaded) {
      final currentState = state as ReturnProductLoaded;
      final updatedPayments = currentState.payments.where((payment) => PaymentModel.intToPaymentType(payment.payType) != event.paymentType).toList();

      emit(currentState.copyWith(
        payments: updatedPayments,
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

      if (!currentState.isFullyPaid) {
        emit(const ReturnProductError('กรุณาชำระเงินให้ครบจำนวน'));
        return;
      }

      emit(ReturnSubmitting());

      try {
        // ดึงข้อมูลที่จำเป็น
        final user = await _localStorage.getUserData();
        final warehouse = await _localStorage.getWarehouse();
        final now = DateTime.now();
        final docDate = DateFormat('yyyy-MM-dd').format(now);
        final docTime = DateFormat('HH:mm').format(now);

        // สร้างเลขที่เอกสาร
        final docNo = await Global.generateReturnDocumentNumber(warehouse!.code);

        // คำนวณยอดชำระแต่ละประเภท
        double cashAmount = 0;
        double transferAmount = 0;
        double cardAmount = 0;

        for (var payment in currentState.payments) {
          switch (PaymentModel.intToPaymentType(payment.payType)) {
            case PaymentType.cash:
              cashAmount += payment.payAmount;
              break;
            case PaymentType.transfer:
              transferAmount += payment.payAmount;
              break;
            case PaymentType.creditCard:
              cardAmount += payment.payAmount;
              break;
          }
        }

        // สร้าง transaction model
        final transaction = ReturnProductModel(
          custCode: currentState.selectedCustomer!.code!,
          empCode: user?.userCode ?? 'TEST',
          docDate: docDate,
          docTime: docTime,
          docNo: docNo,
          refDocDate: currentState.selectedSaleDocument!.docDate,
          refDocNo: currentState.selectedSaleDocument!.docNo,
          refAmount: currentState.selectedSaleDocument!.totalAmount,
          items: currentState.returnItems,
          paymentDetail: currentState.payments,
          transferAmount: transferAmount.toString(),
          creditAmount: '0',
          cashAmount: cashAmount.toString(),
          cardAmount: cardAmount.toString(),
          totalAmount: currentState.totalAmount.toString(),
          totalValue: currentState.totalAmount.toString(),
          remark: event.remark,
        );

        // บันทึกข้อมูล
        final success = await _returnProductRepository.saveReturnProduct(transaction);

        if (success) {
          emit(ReturnSubmitSuccess(
            documentNumber: docNo,
            customer: currentState.selectedCustomer!,
            items: currentState.returnItems,
            payments: currentState.payments,
            totalAmount: currentState.totalAmount,
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
