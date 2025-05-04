// lib/blocs/network/network_state.dart
import 'package:equatable/equatable.dart';

abstract class NetworkState extends Equatable {
  const NetworkState();

  @override
  List<Object> get props => [];
}

// สถานะเริ่มต้น รอการตรวจสอบ
class NetworkInitial extends NetworkState {}

// สถานะเชื่อมต่อปกติ
class NetworkConnected extends NetworkState {}

// สถานะไม่มีการเชื่อมต่อ
class NetworkDisconnected extends NetworkState {}

// สถานะการเชื่อมต่อไม่เสถียร
class NetworkUnstable extends NetworkState {
  final String message;

  const NetworkUnstable(this.message);

  @override
  List<Object> get props => [message];
}
