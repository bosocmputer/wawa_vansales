// lib/blocs/network/network_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';
import 'package:wawa_vansales/blocs/network/network_event.dart';
import 'package:wawa_vansales/blocs/network/network_state.dart';
import 'package:wawa_vansales/utils/network_helper.dart';

class NetworkBloc extends Bloc<NetworkEvent, NetworkState> {
  final NetworkHelper _networkHelper;
  final Logger _logger = Logger();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  NetworkBloc({
    required NetworkHelper networkHelper,
  })  : _networkHelper = networkHelper,
        super(NetworkInitial()) {
    on<CheckNetworkStatus>(_onCheckNetworkStatus);
    on<UpdateNetworkStatus>(_onUpdateNetworkStatus);
    on<ResetNetworkState>(_onResetNetworkState);

    // เริ่มการตรวจสอบการเชื่อมต่อเครือข่าย
    _initConnectivityListener();
    add(CheckNetworkStatus());
  }

  void _initConnectivityListener() {
    _connectivitySubscription = _networkHelper.connectivityStream.listen((result) {
      add(UpdateNetworkStatus(result));
    });
  }

  // ตรวจสอบสถานะการเชื่อมต่อ
  Future<void> _onCheckNetworkStatus(
    CheckNetworkStatus event,
    Emitter<NetworkState> emit,
  ) async {
    _logger.i('Checking network status');

    try {
      final isConnected = await _networkHelper.isConnected();
      if (isConnected) {
        _logger.i('Network is connected');
        emit(NetworkConnected());
      } else {
        _logger.w('Network is disconnected');
        emit(NetworkDisconnected());
      }
    } catch (e) {
      _logger.e('Error checking network status: $e');
      emit(NetworkUnstable('ไม่สามารถตรวจสอบการเชื่อมต่อได้: $e'));
    }
  }

  // อัพเดตสถานะการเชื่อมต่อ
  void _onUpdateNetworkStatus(
    UpdateNetworkStatus event,
    Emitter<NetworkState> emit,
  ) {
    _logger.i('Network status updated: ${event.result}');

    switch (event.result) {
      case ConnectivityResult.none:
        emit(NetworkDisconnected());
        break;
      case ConnectivityResult.mobile:
      case ConnectivityResult.wifi:
      case ConnectivityResult.ethernet:
        emit(NetworkConnected());
        break;
      case ConnectivityResult.bluetooth:
      case ConnectivityResult.vpn:
      case ConnectivityResult.other:
        emit(NetworkConnected()); // สำหรับการเชื่อมต่อประเภทอื่นๆ จะถือว่าเชื่อมต่ออยู่
        break;
    }
  }

  // รีเซ็ตสถานะการเชื่อมต่อ
  void _onResetNetworkState(
    ResetNetworkState event,
    Emitter<NetworkState> emit,
  ) {
    _logger.i('Reset network state');
    emit(NetworkInitial());
    add(CheckNetworkStatus());
  }

  @override
  Future<void> close() {
    _connectivitySubscription.cancel();
    return super.close();
  }
}
