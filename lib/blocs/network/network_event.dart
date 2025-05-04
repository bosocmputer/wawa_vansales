// lib/blocs/network/network_event.dart
import 'package:equatable/equatable.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

abstract class NetworkEvent extends Equatable {
  const NetworkEvent();

  @override
  List<Object?> get props => [];
}

// เหตุการณ์ตรวจสอบสถานะการเชื่อมต่อ
class CheckNetworkStatus extends NetworkEvent {}

// เหตุการณ์อัพเดตสถานะการเชื่อมต่อ
class UpdateNetworkStatus extends NetworkEvent {
  final ConnectivityResult result;

  const UpdateNetworkStatus(this.result);

  @override
  List<Object?> get props => [result];
}

// เหตุการณ์รีเซ็ตสถานะการเชื่อมต่อ
class ResetNetworkState extends NetworkEvent {}
