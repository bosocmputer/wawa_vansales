import 'package:json_annotation/json_annotation.dart';
import 'package:wawa_vansales/data/models/customer_model.dart';
import 'package:wawa_vansales/data/models/product_model.dart';

part 'sales_transaction_model.g.dart';

enum PaymentType { cash, transfer, creditCard }

extension PaymentTypeExtension on PaymentType {
  String get name {
    switch (this) {
      case PaymentType.cash:
        return 'เงินสด';
      case PaymentType.transfer:
        return 'โอนเงิน';
      case PaymentType.creditCard:
        return 'บัตรเครดิต';
    }
  }
}

@JsonSerializable()
class SalesTransactionModel {
  String id;
  String docNo;
  DateTime docDate;
  CustomerModel? customer;
  List<SalesItemModel> items;
  double subtotal;
  double vatAmount;
  double discount;
  double total;
  PaymentType paymentType;
  String? remark;
  String status; // draft, completed, canceled

  SalesTransactionModel({
    required this.id,
    required this.docNo,
    required this.docDate,
    this.customer,
    required this.items,
    required this.subtotal,
    required this.vatAmount,
    required this.discount,
    required this.total,
    required this.paymentType,
    this.remark,
    required this.status,
  });

  factory SalesTransactionModel.fromJson(Map<String, dynamic> json) => _$SalesTransactionModelFromJson(json);

  Map<String, dynamic> toJson() => _$SalesTransactionModelToJson(this);

  // Helper method to create a new draft transaction
  factory SalesTransactionModel.createDraft() {
    final now = DateTime.now();
    final String docNo = 'S${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.hour}${now.minute}${now.second}';

    return SalesTransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      docNo: docNo,
      docDate: now,
      items: [],
      subtotal: 0,
      vatAmount: 0,
      discount: 0,
      total: 0,
      paymentType: PaymentType.cash,
      status: 'draft',
    );
  }

  // Calculate all amounts
  void calculateAmounts() {
    subtotal = 0;
    for (var item in items) {
      subtotal += item.total;
    }

    // Assume VAT is 7%
    vatAmount = (subtotal - discount) * 0.07;
    total = subtotal - discount + vatAmount;
  }

  // Add item to transaction
  void addItem(ProductModel product, double quantity) {
    // Check if product already exists in the transaction
    final existingItemIndex = items.indexWhere((item) => item.product.itemCode == product.itemCode);

    if (existingItemIndex >= 0) {
      // Update existing item
      final existingItem = items[existingItemIndex];
      items[existingItemIndex] = SalesItemModel(
        product: product,
        quantity: existingItem.quantity + quantity,
        unitPrice: product.price,
        discount: existingItem.discount,
        total: (existingItem.quantity + quantity) * product.price - existingItem.discount,
      );
    } else {
      // Add new item
      items.add(SalesItemModel(
        product: product,
        quantity: quantity,
        unitPrice: product.price,
        discount: 0,
        total: quantity * product.price,
      ));
    }

    // Recalculate totals
    calculateAmounts();
  }

  // Remove item from transaction
  void removeItem(String productCode) {
    items.removeWhere((item) => item.product.itemCode == productCode);
    calculateAmounts();
  }

  // Update item quantity
  void updateItemQuantity(String productCode, double quantity) {
    final index = items.indexWhere((item) => item.product.itemCode == productCode);
    if (index >= 0) {
      final item = items[index];
      items[index] = SalesItemModel(
        product: item.product,
        quantity: quantity,
        unitPrice: item.unitPrice,
        discount: item.discount,
        total: quantity * item.unitPrice - item.discount,
      );
      calculateAmounts();
    }
  }
}

@JsonSerializable()
class SalesItemModel {
  ProductModel product;
  double quantity;
  double unitPrice;
  double discount;
  double total;

  SalesItemModel({
    required this.product,
    required this.quantity,
    required this.unitPrice,
    required this.discount,
    required this.total,
  });

  factory SalesItemModel.fromJson(Map<String, dynamic> json) => _$SalesItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$SalesItemModelToJson(this);
}
