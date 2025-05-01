// lib/blocs/cart/cart_state.dart
import 'package:equatable/equatable.dart';
import 'package:wawa_vansales/data/models/cart_item_model.dart';
import 'package:wawa_vansales/data/models/customer_model.dart';
import 'package:wawa_vansales/data/models/payment_model.dart';

abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

// สถานะเริ่มต้น
class CartInitial extends CartState {}

// สถานะตะกร้าสินค้า
class CartLoaded extends CartState {
  final CustomerModel? selectedCustomer;
  final List<CartItemModel> items;
  final List<PaymentModel> payments;
  final double totalAmount;
  final int currentStep; // 0: เลือกลูกค้า, 1: เลือกสินค้า, 2: ชำระเงิน, 3: สรุปรายการ
  final String preOrderDocNo; // เพิ่มฟิลด์สำหรับเก็บเลขที่เอกสารพรีออเดอร์
  final String documentNumber; // เพิ่มฟิลด์สำหรับเก็บเลขที่เอกสาร

  const CartLoaded({
    this.selectedCustomer,
    this.items = const [],
    this.payments = const [],
    this.totalAmount = 0,
    this.currentStep = 0,
    this.preOrderDocNo = '', // กำหนดค่าเริ่มต้นเป็นสตริงว่าง
    this.documentNumber = '', // กำหนดค่าเริ่มต้นเป็นสตริงว่าง
  });

  @override
  List<Object?> get props => [selectedCustomer, items, payments, totalAmount, currentStep, preOrderDocNo, documentNumber];

  // สร้าง copyWith method
  CartLoaded copyWith({
    CustomerModel? selectedCustomer,
    List<CartItemModel>? items,
    List<PaymentModel>? payments,
    double? totalAmount,
    int? currentStep,
    String? preOrderDocNo,
    String? documentNumber,
  }) {
    return CartLoaded(
      selectedCustomer: selectedCustomer ?? this.selectedCustomer,
      items: items ?? this.items,
      payments: payments ?? this.payments,
      totalAmount: totalAmount ?? this.totalAmount,
      currentStep: currentStep ?? this.currentStep,
      preOrderDocNo: preOrderDocNo ?? this.preOrderDocNo,
      documentNumber: documentNumber ?? this.documentNumber,
    );
  }

  // คำนวณยอดชำระแล้ว
  double get totalPaid {
    return payments.fold(0, (sum, payment) => sum + payment.payAmount);
  }

  // คำนวณยอดคงเหลือ
  double get remainingAmount {
    return totalAmount - totalPaid;
  }

  // ตรวจสอบว่าชำระครบหรือยัง
  bool get isFullyPaid {
    return remainingAmount <= 0;
  }
}

// กำลังบันทึกการขาย
class CartSubmitting extends CartState {}

// บันทึกการขายสำเร็จ
class CartSubmitSuccess extends CartState {
  final String documentNumber;
  final CustomerModel customer;
  final List<CartItemModel> items;
  final List<PaymentModel> payments;
  final double totalAmount;

  const CartSubmitSuccess({
    required this.documentNumber,
    required this.customer,
    required this.items,
    required this.payments,
    required this.totalAmount,
  });

  @override
  List<Object?> get props => [documentNumber, customer, items, payments, totalAmount];
}

// เกิดข้อผิดพลาด
class CartError extends CartState {
  final String message;

  const CartError(this.message);

  @override
  List<Object?> get props => [message];
}
