// lib/blocs/cart/cart_state.dart
import 'package:equatable/equatable.dart';
import 'package:wawa_vansales/data/models/balance_detail_model.dart';
import 'package:wawa_vansales/data/models/cart_item_model.dart';
import 'package:wawa_vansales/data/models/customer_model.dart';
import 'package:wawa_vansales/data/models/payment_model.dart';
import 'package:wawa_vansales/data/models/sale_transaction_model.dart';

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
  final double balanceAmount; // เพิ่มฟิลด์สำหรับเก็บยอดลดหนี้
  final List<BalanceDetailModel> balanceDetail; // เพิ่มฟิลด์สำหรับเก็บรายละเอียดการลดหนี้
  final String partialPay; // เพิ่มฟิลด์สำหรับระบุการชำระบางส่วน (0=ชำระเต็มจำนวน, 1=ชำระบางส่วน)
  final double preOrderApiTotalAmount; // เพิ่มฟิลด์สำหรับเก็บยอด total_amount จาก API getDocPreSaleList (ใช้สำหรับขั้นตอนชำระเงิน)

  const CartLoaded({
    this.selectedCustomer,
    this.items = const [],
    this.payments = const [],
    this.totalAmount = 0,
    this.currentStep = 0,
    this.preOrderDocNo = '', // กำหนดค่าเริ่มต้นเป็นสตริงว่าง
    this.documentNumber = '', // กำหนดค่าเริ่มต้นเป็นสตริงว่าง
    this.balanceAmount = 0, // กำหนดค่าเริ่มต้นเป็น 0
    this.balanceDetail = const [], // กำหนดค่าเริ่มต้นเป็น list ว่าง
    this.partialPay = '0', // กำหนดค่าเริ่มต้นเป็น 0 (ชำระเต็มจำนวน)
    this.preOrderApiTotalAmount = 0, // กำหนดค่าเริ่มต้นเป็น 0
  });

  @override
  List<Object?> get props =>
      [selectedCustomer, items, payments, totalAmount, currentStep, preOrderDocNo, documentNumber, balanceAmount, balanceDetail, partialPay, preOrderApiTotalAmount];

  // สร้าง copyWith method
  CartLoaded copyWith({
    CustomerModel? selectedCustomer,
    List<CartItemModel>? items,
    List<PaymentModel>? payments,
    double? totalAmount,
    int? currentStep,
    String? preOrderDocNo,
    String? documentNumber,
    double? balanceAmount,
    List<BalanceDetailModel>? balanceDetail,
    String? partialPay,
    double? preOrderApiTotalAmount,
  }) {
    return CartLoaded(
      selectedCustomer: selectedCustomer ?? this.selectedCustomer,
      items: items ?? this.items,
      payments: payments ?? this.payments,
      totalAmount: totalAmount ?? this.totalAmount,
      currentStep: currentStep ?? this.currentStep,
      preOrderDocNo: preOrderDocNo ?? this.preOrderDocNo,
      documentNumber: documentNumber ?? this.documentNumber,
      balanceAmount: balanceAmount ?? this.balanceAmount,
      balanceDetail: balanceDetail ?? this.balanceDetail,
      partialPay: partialPay ?? this.partialPay,
      preOrderApiTotalAmount: preOrderApiTotalAmount ?? this.preOrderApiTotalAmount,
    );
  }

  // คำนวณยอดชำระแล้ว
  double get totalPaid {
    return payments.fold(0.0, (sum, payment) => sum + payment.payAmount) + balanceAmount;
  }

  // คำนวณยอดคงเหลือ - ใช้ยอดจาก API สำหรับ PreOrder ในขั้นตอนชำระเงิน
  double get remainingAmount {
    final effectiveTotalAmount = preOrderDocNo.isNotEmpty && preOrderApiTotalAmount > 0 ? preOrderApiTotalAmount : totalAmount;
    return effectiveTotalAmount - totalPaid;
  }

  // ตรวจสอบว่าชำระครบหรือยัง - ใช้ยอดจาก API สำหรับ PreOrder ในขั้นตอนชำระเงิน
  bool get isFullyPaid {
    return remainingAmount <= 0;
  }

  // ยอดรวมที่ใช้ในขั้นตอนชำระเงิน (ใช้ยอดจาก API สำหรับ PreOrder)
  double get effectivePaymentAmount {
    return preOrderDocNo.isNotEmpty && preOrderApiTotalAmount > 0 ? preOrderApiTotalAmount : totalAmount;
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
  final double balanceAmount; // เพิ่มฟิลด์สำหรับเก็บยอดลดหนี้
  final List<BalanceDetailModel> balanceDetail; // เพิ่มฟิลด์สำหรับเก็บรายละเอียดการลดหนี้
  final String partialPay; // เพิ่มฟิลด์สำหรับระบุการชำระบางส่วน (0=ชำระเต็มจำนวน, 1=ชำระบางส่วน)
  final double preOrderApiTotalAmount; // เพิ่มฟิลด์สำหรับเก็บยอด total_amount จาก API getDocPreSaleList (ใช้สำหรับขั้นตอนชำระเงิน)

  const CartSubmitSuccess({
    required this.documentNumber,
    required this.customer,
    required this.items,
    required this.payments,
    required this.totalAmount,
    this.balanceAmount = 0,
    this.balanceDetail = const [],
    this.partialPay = '0',
    this.preOrderApiTotalAmount = 0,
  });

  @override
  List<Object?> get props => [documentNumber, customer, items, payments, totalAmount, balanceAmount, balanceDetail, partialPay, preOrderApiTotalAmount];
}

// เกิดข้อผิดพลาด
class CartError extends CartState {
  final String message;
  final SaleTransactionModel? transaction; // เพิ่มข้อมูล transaction สำหรับการแสดงผล

  const CartError(this.message, {this.transaction});

  @override
  List<Object?> get props => [message, transaction];
}
