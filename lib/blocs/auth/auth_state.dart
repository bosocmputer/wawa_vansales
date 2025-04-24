import 'package:equatable/equatable.dart';
import 'package:wawa_vansales/data/models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

// สถานะเริ่มต้น
class AuthInitial extends AuthState {}

// กำลังโหลด
class AuthLoading extends AuthState {}

// ตรวจสอบการเข้าสู่ระบบ
class AuthCheckingStatus extends AuthState {}

// เข้าสู่ระบบสำเร็จ
class AuthAuthenticated extends AuthState {
  final UserModel user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

// ไม่ได้เข้าสู่ระบบ
class AuthUnauthenticated extends AuthState {}

// เกิดข้อผิดพลาด
class AuthFailure extends AuthState {
  final String message;

  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}
