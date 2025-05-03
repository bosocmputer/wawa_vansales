// lib/blocs/return_product/return_product_state.dart
import 'package:equatable/equatable.dart';
import 'package:wawa_vansales/data/models/cart_item_model.dart';
import 'package:wawa_vansales/data/models/customer_model.dart';
import 'package:wawa_vansales/data/models/payment_model.dart';
import 'package:wawa_vansales/data/models/return_product/sale_document_detail_model.dart';
import 'package:wawa_vansales/data/models/return_product/sale_document_model.dart';

abstract class ReturnProductState extends Equatable {
  const ReturnProductState();

  @override
  List<Object?> get props => [];
}

// สถานะเริ่มต้น
class ReturnProductInitial extends ReturnProductState {}

// สถานะตะกร้าสินค้าคืน
class ReturnProductLoaded extends ReturnProductState {
  final CustomerModel? selectedCustomer;
  final List<SaleDocumentModel> saleDocuments;
  final SaleDocumentModel? selectedSaleDocument;
  final List<SaleDocumentDetailModel> documentDetails;
  final List<CartItemModel> returnItems;
  final List<PaymentModel> payments;
  final double totalAmount;
  final int currentStep; // 0: เลือกลูกค้า, 1: เลือกเอกสารขาย, 2: เลือกสินค้าคืน, 3: ชำระเงิน, 4: สรุปรายการ
  final String documentNumber;

  const ReturnProductLoaded({
    this.selectedCustomer,
    this.saleDocuments = const [],
    this.selectedSaleDocument,
    this.documentDetails = const [],
    this.returnItems = const [],
    this.payments = const [],
    this.totalAmount = 0,
    this.currentStep = 0,
    this.documentNumber = '',
  });

  @override
  List<Object?> get props => [
        selectedCustomer,
        saleDocuments,
        selectedSaleDocument,
        documentDetails,
        returnItems,
        payments,
        totalAmount,
        currentStep,
        documentNumber,
      ];

  // สร้าง copyWith method
  ReturnProductLoaded copyWith({
    CustomerModel? selectedCustomer,
    List<SaleDocumentModel>? saleDocuments,
    SaleDocumentModel? selectedSaleDocument,
    List<SaleDocumentDetailModel>? documentDetails,
    List<CartItemModel>? returnItems,
    List<PaymentModel>? payments,
    double? totalAmount,
    int? currentStep,
    String? documentNumber,
  }) {
    return ReturnProductLoaded(
      selectedCustomer: selectedCustomer ?? this.selectedCustomer,
      saleDocuments: saleDocuments ?? this.saleDocuments,
      selectedSaleDocument: selectedSaleDocument ?? this.selectedSaleDocument,
      documentDetails: documentDetails ?? this.documentDetails,
      returnItems: returnItems ?? this.returnItems,
      payments: payments ?? this.payments,
      totalAmount: totalAmount ?? this.totalAmount,
      currentStep: currentStep ?? this.currentStep,
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

// กำลังโหลดข้อมูล
class ReturnProductLoading extends ReturnProductState {}

// กำลังบันทึกการคืนสินค้า
class ReturnSubmitting extends ReturnProductState {}

// บันทึกการคืนสินค้าสำเร็จ
class ReturnSubmitSuccess extends ReturnProductState {
  final String documentNumber;
  final CustomerModel customer;
  final List<CartItemModel> items;
  final List<PaymentModel> payments;
  final double totalAmount;
  final SaleDocumentModel refSaleDocument;

  const ReturnSubmitSuccess({
    required this.documentNumber,
    required this.customer,
    required this.items,
    required this.payments,
    required this.totalAmount,
    required this.refSaleDocument,
  });

  @override
  List<Object?> get props => [documentNumber, customer, items, payments, totalAmount, refSaleDocument];
}

// เกิดข้อผิดพลาด
class ReturnProductError extends ReturnProductState {
  final String message;

  const ReturnProductError(this.message);

  @override
  List<Object?> get props => [message];
}
