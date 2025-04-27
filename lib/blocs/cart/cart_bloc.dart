// lib/blocs/cart/cart_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:wawa_vansales/blocs/cart/cart_event.dart';
import 'package:wawa_vansales/blocs/cart/cart_state.dart';
import 'package:wawa_vansales/data/models/cart_item_model.dart';
import 'package:wawa_vansales/data/models/payment_model.dart';
import 'package:wawa_vansales/data/models/sale_transaction_model.dart';
import 'package:wawa_vansales/data/repositories/sale_repository.dart';
import 'package:wawa_vansales/utils/local_storage.dart';
import 'package:intl/intl.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final SaleRepository _saleRepository;
  final LocalStorage _localStorage;
  final Logger _logger = Logger();

  CartBloc({
    required SaleRepository saleRepository,
    required LocalStorage localStorage,
  })  : _saleRepository = saleRepository,
        _localStorage = localStorage,
        super(const CartLoaded()) {
    on<SelectCustomerForCart>(_onSelectCustomer);
    on<AddItemToCart>(_onAddItem);
    on<RemoveItemFromCart>(_onRemoveItem);
    on<UpdateItemQuantity>(_onUpdateQuantity);
    on<ClearCart>(_onClearCart);
    on<AddPayment>(_onAddPayment);
    on<RemovePayment>(_onRemovePayment);
    on<SubmitSale>(_onSubmitSale);
    on<UpdateStep>(_onUpdateStep);
  }

  // เลือกลูกค้า
  void _onSelectCustomer(SelectCustomerForCart event, Emitter<CartState> emit) {
    if (state is CartLoaded) {
      final currentState = state as CartLoaded;
      emit(currentState.copyWith(
        selectedCustomer: event.customer,
        currentStep: 0, // ไปยังขั้นตอนถัดไป
      ));
    }
  }

  // อัปเดต step ปัจจุบัน
  void _onUpdateStep(UpdateStep event, Emitter<CartState> emit) {
    if (state is CartLoaded) {
      final currentState = state as CartLoaded;
      emit(currentState.copyWith(currentStep: event.step));
    }
  }

  // เพิ่มสินค้าเข้าตะกร้า
  Future<void> _onAddItem(AddItemToCart event, Emitter<CartState> emit) async {
    if (state is CartLoaded) {
      final currentState = state as CartLoaded;
      final List<CartItemModel> updatedItems = List.from(currentState.items);

      // ตรวจสอบว่ามีสินค้านี้ในตะกร้าแล้วหรือไม่
      final existingIndex = updatedItems.indexWhere(
        (item) => item.itemCode == event.item.itemCode,
      );

      if (existingIndex != -1) {
        // ถ้ามีแล้ว เพิ่มจำนวน
        final existingItem = updatedItems[existingIndex];
        final existingQty = double.tryParse(existingItem.qty) ?? 0;
        final newQty = double.tryParse(event.item.qty) ?? 0;
        updatedItems[existingIndex] = existingItem.copyWith(
          qty: (existingQty + newQty).toString(),
        );
      } else {
        // ถ้ายังไม่มี เพิ่มเข้าไปใหม่
        // เพิ่มข้อมูล warehouse และ location จาก LocalStorage
        final warehouse = await _localStorage.getWarehouse();
        final location = await _localStorage.getLocation();

        if (warehouse != null && location != null) {
          final newItem = event.item.copyWith(
            whCode: warehouse.code,
            shelfCode: location.code,
          );
          updatedItems.add(newItem);
        } else {
          emit(const CartError('กรุณาเลือกคลังและพื้นที่เก็บก่อนเพิ่มสินค้า'));
          return;
        }
      }

      // คำนวณยอดรวม
      final totalAmount = _calculateTotal(updatedItems);

      emit(currentState.copyWith(
        items: updatedItems,
        totalAmount: totalAmount,
      ));
    }
  }

  // ลบสินค้าออกจากตะกร้า
  void _onRemoveItem(RemoveItemFromCart event, Emitter<CartState> emit) {
    if (state is CartLoaded) {
      final currentState = state as CartLoaded;
      final updatedItems = currentState.items.where((item) => item.itemCode != event.itemCode).toList();

      final totalAmount = _calculateTotal(updatedItems);

      emit(currentState.copyWith(
        items: updatedItems,
        totalAmount: totalAmount,
      ));
    }
  }

  // อัพเดทจำนวนสินค้า
  void _onUpdateQuantity(UpdateItemQuantity event, Emitter<CartState> emit) {
    if (state is CartLoaded) {
      final currentState = state as CartLoaded;
      final updatedItems = currentState.items.map((item) {
        if (item.itemCode == event.itemCode) {
          return item.copyWith(qty: event.quantity.toString());
        }
        return item;
      }).toList();

      final totalAmount = _calculateTotal(updatedItems);

      emit(currentState.copyWith(
        items: updatedItems,
        totalAmount: totalAmount,
      ));
    }
  }

  // ล้างตะกร้า
  void _onClearCart(ClearCart event, Emitter<CartState> emit) {
    emit(const CartLoaded());
  }

  // เพิ่มการชำระเงิน
  void _onAddPayment(AddPayment event, Emitter<CartState> emit) {
    if (state is CartLoaded) {
      final currentState = state as CartLoaded;
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
  void _onRemovePayment(RemovePayment event, Emitter<CartState> emit) {
    if (state is CartLoaded) {
      final currentState = state as CartLoaded;
      final updatedPayments = currentState.payments.where((payment) => PaymentModel.intToPaymentType(payment.payType) != event.paymentType).toList();

      emit(currentState.copyWith(
        payments: updatedPayments,
      ));
    }
  }

  // บันทึกการขาย
  Future<void> _onSubmitSale(SubmitSale event, Emitter<CartState> emit) async {
    if (state is CartLoaded) {
      final currentState = state as CartLoaded;

      // ตรวจสอบข้อมูลที่จำเป็น
      if (currentState.selectedCustomer == null) {
        emit(const CartError('กรุณาเลือกลูกค้า'));
        return;
      }

      if (currentState.items.isEmpty) {
        emit(const CartError('กรุณาเพิ่มสินค้าในตะกร้า'));
        return;
      }

      if (!currentState.isFullyPaid) {
        emit(const CartError('กรุณาชำระเงินให้ครบจำนวน'));
        return;
      }

      emit(CartSubmitting());

      try {
        // ดึงข้อมูลที่จำเป็น
        final user = await _localStorage.getUserData();
        final warehouse = await _localStorage.getWarehouse();
        final warehouseCode = warehouse?.code ?? 'NA';
        final docNo = _saleRepository.generateDocumentNumber(warehouseCode);
        final now = DateTime.now();
        final docDate = DateFormat('yyyy-MM-dd').format(now);
        final docTime = DateFormat('HH:mm').format(now);

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
        final transaction = SaleTransactionModel(
          custCode: currentState.selectedCustomer!.code!,
          empCode: user?.userCode ?? 'TEST',
          docDate: docDate,
          docTime: docTime,
          docNo: docNo,
          items: currentState.items
              .map((item) => CartItemModel(
                    itemCode: item.itemCode,
                    itemName: item.itemName,
                    barcode: item.barcode,
                    qty: item.qty.toString(),
                    price: item.price.toString(),
                    sumAmount: item.totalAmount.toString(),
                    unitCode: item.unitCode,
                    whCode: item.whCode,
                    shelfCode: item.shelfCode,
                    ratio: item.ratio,
                    standValue: item.standValue,
                    divideValue: item.divideValue,
                  ))
              .toList(),
          paymentDetail: currentState.payments, // เปลี่ยนชื่อ field
          transferAmount: transferAmount.toString(),
          creditAmount: '0',
          cashAmount: cashAmount.toString(), // เพิ่ม cash_amount
          cardAmount: cardAmount.toString(),
          totalAmount: currentState.totalAmount.toString(),
          totalValue: currentState.totalAmount.toString(),
          remark: event.remark,
        );

        // บันทึกการขาย
        final success = await _saleRepository.saveSaleTransaction(transaction);

        if (success) {
          emit(CartSubmitSuccess(
            documentNumber: docNo,
            customer: currentState.selectedCustomer!,
            items: currentState.items,
            payments: currentState.payments,
            totalAmount: currentState.totalAmount,
          ));
        } else {
          emit(const CartError('ไม่สามารถบันทึกการขายได้'));
        }
      } catch (e) {
        _logger.e('Submit sale error: $e');
        emit(CartError(e.toString()));
      }
    }
  }

  // คำนวณยอดรวม
  double _calculateTotal(List<CartItemModel> items) {
    return items.fold(0, (sum, item) => sum + item.totalAmount);
  }
}
