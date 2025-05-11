// lib/data/models/payment_model.dart
import 'package:json_annotation/json_annotation.dart';

part 'payment_model.g.dart';

enum PaymentType {
  cash,
  transfer,
  creditCard,
}

@JsonSerializable()
class PaymentModel {
  @JsonKey(name: 'pay_type')
  final int payType;

  @JsonKey(name: 'trans_number')
  final String transNumber;

  @JsonKey(name: 'pay_amount')
  final double payAmount;

  @JsonKey(name: 'charge')
  final double charge;

  PaymentModel({
    required this.payType,
    required this.transNumber,
    required this.payAmount,
    this.charge = 0.0,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) => _$PaymentModelFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentModelToJson(this);

  // Convert enum to int
  static int paymentTypeToInt(PaymentType type) {
    switch (type) {
      case PaymentType.cash:
        return 0;
      case PaymentType.transfer:
        return 1;
      case PaymentType.creditCard:
        return 2;
    }
  }

  // Convert int to enum
  static PaymentType intToPaymentType(int type) {
    switch (type) {
      case 0:
        return PaymentType.cash;
      case 1:
        return PaymentType.transfer;
      case 2:
        return PaymentType.creditCard;
      default:
        return PaymentType.cash;
    }
  }
}
