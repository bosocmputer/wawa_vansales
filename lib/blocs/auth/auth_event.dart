import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

// ตรวจสอบสถานะการเข้าสู่ระบบเมื่อเริ่มแอป
class AuthCheckRequested extends AuthEvent {}

// ทำการลงชื่อเข้าใช้
class LoginRequested extends AuthEvent {
  final String userCode;
  final String password;

  const LoginRequested({required this.userCode, required this.password});

  @override
  List<Object?> get props => [userCode, password];
}

// ทำการออกจากระบบ
class LogoutRequested extends AuthEvent {}
