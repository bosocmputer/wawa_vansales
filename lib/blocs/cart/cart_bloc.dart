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
import 'package:wawa_vansales/utils/global.dart';
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
    on<SetPreOrderDocument>(_onSetPreOrderDocument);
    on<AddItemsToCart>(_onAddItems);
    on<SetDocumentNumber>(_onSetDocumentNumber);
    on<ResetCartState>(_onResetState); // เพิ่มการจัดการ Reset State
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

  // รีเซ็ตสถานะทั้งหมดของ Cart
  void _onResetState(ResetCartState event, Emitter<CartState> emit) {
    _logger.i('Resetting cart state to initial');
    emit(const CartLoaded()); // รีเซ็ตกลับไปเป็น state เริ่มต้น
  }

  // อัปเดต step ปัจจุบัน
  void _onUpdateStep(UpdateStep event, Emitter<CartState> emit) {
    if (state is CartLoaded) {
      final currentState = state as CartLoaded;
      emit(currentState.copyWith(currentStep: event.step));
    }
  }

  // ตั้งค่าเลขที่เอกสาร
  void _onSetDocumentNumber(SetDocumentNumber event, Emitter<CartState> emit) {
    if (state is CartLoaded) {
      final currentState = state as CartLoaded;
      emit(currentState.copyWith(documentNumber: event.documentNumber));
    }
  }

  // เพิ่มสินค้าเข้าตะกร้า
  Future<void> _onAddItem(AddItemToCart event, Emitter<CartState> emit) async {
    if (state is CartLoaded) {
      final currentState = state as CartLoaded;
      final List<CartItemModel> updatedItems = List.from(currentState.items);

      // เพิ่ม log เพื่อดูค่าที่ส่งเข้ามา
      _logger.i('Adding item: ${event.item.itemCode}, barcode: ${event.item.barcode}, unit: ${event.item.unitCode}, qty: ${event.item.qty}');

      // ตรวจสอบว่ามีสินค้านี้ในตะกร้าแล้วหรือไม่ โดยตรวจสอบทั้ง itemCode, barcode และ unitCode
      final existingIndex = updatedItems.indexWhere(
        (item) => item.itemCode == event.item.itemCode && item.barcode == event.item.barcode && item.unitCode == event.item.unitCode,
      );

      if (existingIndex != -1) {
        // ถ้ามีแล้ว เพิ่มจำนวนตาม qty ที่ส่งมา
        final existingItem = updatedItems[existingIndex];
        final existingQty = double.tryParse(existingItem.qty) ?? 0;
        // ใช้ค่า qty จริงที่ส่งมาแทนการใช้ค่าคงที่ 1.0
        final qtyToAdd = double.tryParse(event.item.qty) ?? 1.0;

        _logger.i('Existing qty: $existingQty, Adding: $qtyToAdd');

        updatedItems[existingIndex] = existingItem.copyWith(
          qty: (existingQty + qtyToAdd).toString(),
        );
      } else {
        // ยังคงใช้โค้ดเดิมในการเพิ่มรายการใหม่...
        final warehouse = await _localStorage.getWarehouse();
        final location = await _localStorage.getLocation();

        if (warehouse != null && location != null) {
          // ตรวจสอบให้แน่ใจว่า qty เป็น "1" เสมอเมื่อเพิ่มสินค้าใหม่
          final newItem = event.item.copyWith(
            whCode: warehouse.code,
            shelfCode: location.code,
            qty: event.item.qty, // ใช้ qty ที่ส่งมาจาก event
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

  // เพิ่มเมธอดสำหรับเพิ่มสินค้าหลายรายการพร้อมกัน
  Future<void> _onAddItems(AddItemsToCart event, Emitter<CartState> emit) async {
    if (state is CartLoaded) {
      final currentState = state as CartLoaded;
      final List<CartItemModel> updatedItems = List.from(currentState.items);
      final warehouse = await _localStorage.getWarehouse();
      final location = await _localStorage.getLocation();

      if (warehouse != null && location != null) {
        for (var item in event.items) {
          // ตรวจสอบว่ามีสินค้านี้ในตะกร้าแล้วหรือไม่
          final existingIndex = updatedItems.indexWhere(
            (i) => i.itemCode == item.itemCode && i.barcode == item.barcode && i.unitCode == item.unitCode,
          );

          if (existingIndex != -1) {
            // ถ้ามีแล้ว เพิ่มจำนวน
            final existingItem = updatedItems[existingIndex];
            final existingQty = double.tryParse(existingItem.qty) ?? 0;
            final qtyToAdd = double.tryParse(item.qty) ?? 1.0;

            _logger.i('Existing qty: $existingQty, Adding: $qtyToAdd for ${item.itemCode}');

            updatedItems[existingIndex] = existingItem.copyWith(
              qty: (existingQty + qtyToAdd).toString(),
            );
          } else {
            // เพิ่มสินค้าใหม่โดยใช้ warehouse และ location จาก localStorage
            final newItem = item.copyWith(
              whCode: item.whCode.isEmpty ? warehouse.code : item.whCode,
              shelfCode: item.shelfCode.isEmpty ? location.code : item.shelfCode,
            );
            updatedItems.add(newItem);
            _logger.i('Added new item: ${newItem.itemCode}, qty: ${newItem.qty}');
          }
        }

        // คำนวณยอดรวม
        final totalAmount = _calculateTotal(updatedItems);

        emit(currentState.copyWith(
          items: updatedItems,
          totalAmount: totalAmount,
        ));
      } else {
        emit(const CartError('กรุณาเลือกคลังและพื้นที่เก็บก่อนเพิ่มสินค้า'));
      }
    }
  }

  // ลบสินค้าออกจากตะกร้า
  void _onRemoveItem(RemoveItemFromCart event, Emitter<CartState> emit) {
    if (state is CartLoaded) {
      final currentState = state as CartLoaded;
      final updatedItems = currentState.items.where((item) => !(item.itemCode == event.itemCode && item.barcode == event.barcode && item.unitCode == event.unitCode)).toList();

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
        if (item.itemCode == event.itemCode && item.barcode == event.barcode && item.unitCode == event.unitCode) {
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

        // ใช้เลขที่เอกสารที่ถูกตั้งค่าไว้แล้ว หรือสร้างใหม่ถ้ายังไม่มี
        final docNo = currentState.documentNumber.isNotEmpty ? currentState.documentNumber : Global.generateDocumentNumber(warehouseCode);

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
          paymentDetail: currentState.payments,
          transferAmount: transferAmount.toString(),
          creditAmount: '0',
          cashAmount: cashAmount.toString(),
          cardAmount: cardAmount.toString(),
          totalAmount: currentState.totalAmount.toString(),
          totalValue: currentState.totalAmount.toString(),
          remark: event.remark,
          carCode: warehouseCode, // ใช้ warehouseCode จาก localStorage แทน Global.whCode ที่อาจจะเป็น NA
        );

        bool success = false;

        // ตรวจสอบว่าเป็นการชำระเงินจากพรีออเดอร์หรือไม่
        if (currentState.preOrderDocNo.isNotEmpty) {
          // ถ้ามี preOrderDocNo ให้อัพเดทสถานะเอกสารพรีออเดอร์
          _logger.i('Updating pre-order payment: ${currentState.preOrderDocNo}');

          success = await _saleRepository.updatePreOrderPayment(transaction, currentState.preOrderDocNo);
        } else {
          // บันทึกการขายทั่วไป
          _logger.i('Saving normal sale transaction');
          success = await _saleRepository.saveSaleTransaction(transaction);
        }

        if (success) {
          // ส่ง CartSubmitSuccess เพียงครั้งเดียวและจบการทำงาน
          emit(CartSubmitSuccess(
            documentNumber: docNo,
            customer: currentState.selectedCustomer!,
            items: currentState.items,
            payments: currentState.payments,
            totalAmount: currentState.totalAmount,
          ));
          return; // เพิ่ม return เพื่อจบการทำงานทันที
        } else {
          // กรณีไม่สำเร็จ emit CartError เพียงอย่างเดียว
          emit(const CartError('ไม่สามารถบันทึกการขายได้'));
          // ไม่ต้อง emit กลับเป็น CartLoaded อีก
        }
      } catch (e) {
        _logger.e('Submit sale error: $e');
        emit(const CartError('เกิดข้อผิดพลาด: ไม่สามารถบันทึกข้อมูลได้'));
        // ไม่ต้อง emit กลับเป็น CartLoaded อีก
      }
    }
  }

  // ตั้งค่าเอกสารพรีออเดอร์
  void _onSetPreOrderDocument(SetPreOrderDocument event, Emitter<CartState> emit) {
    if (state is CartLoaded) {
      final currentState = state as CartLoaded;
      emit(currentState.copyWith(preOrderDocNo: event.docNo));
    }
  }

  // คำนวณยอดรวม
  double _calculateTotal(List<CartItemModel> items) {
    return items.fold(0, (sum, item) => sum + item.totalAmount);
  }
}
