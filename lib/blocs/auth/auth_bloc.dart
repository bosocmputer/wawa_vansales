import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:wawa_vansales/blocs/auth/auth_event.dart';
import 'package:wawa_vansales/blocs/auth/auth_state.dart';
import 'package:wawa_vansales/data/repositories/auth_repository.dart';
import 'package:wawa_vansales/utils/global.dart';
import 'package:wawa_vansales/utils/local_storage.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final Logger _logger = Logger();
  final LocalStorage _localStorage;

  AuthBloc({
    required AuthRepository authRepository,
    required LocalStorage localStorage,
  })  : _authRepository = authRepository,
        _localStorage = localStorage,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  // ตรวจสอบสถานะการเข้าสู่ระบบเมื่อเริ่มแอป
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    _logger.i('Checking auth status');
    emit(AuthCheckingStatus());

    try {
      final isLoggedIn = await _authRepository.isLoggedIn();
      _logger.i('Is logged in: $isLoggedIn');

      if (isLoggedIn) {
        final user = await _authRepository.getCurrentUser();
        if (user != null) {
          _logger.i('User found: ${user.userName}');

          // ตั้งค่า Global.empCode เมื่อตรวจสอบพบว่าล็อกอินอยู่
          if (user.userCode.isNotEmpty) {
            await Global.setEmpCode(_localStorage, user.userCode);
            _logger.i('Global.empCode set to: ${user.userCode}');
          }

          emit(AuthAuthenticated(user));
        } else {
          _logger.w('No user found despite logged in status');
          emit(AuthUnauthenticated());
        }
      } else {
        _logger.i('User is not logged in');
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      _logger.e('Error checking auth status: $e');
      emit(AuthUnauthenticated());
    }
  }

  // ทำการลงชื่อเข้าใช้
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    _logger.i('Login requested: ${event.userCode}');
    emit(AuthLoading());

    try {
      final user = await _authRepository.login(
        event.userCode,
        event.password,
      );

      // ตั้งค่า Global.empCode เมื่อล็อกอินสำเร็จ
      if (user.userCode.isNotEmpty) {
        await Global.setEmpCode(_localStorage, user.userCode);
        _logger.i('Global.empCode set to: ${user.userCode}');
      }

      _logger.i('Login successful: ${user.userName}');
      emit(AuthAuthenticated(user));
    } catch (e) {
      _logger.e('Login error: $e');
      emit(AuthFailure(e.toString()));
    }
  }

  // ทำการออกจากระบบ
  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    _logger.i('Logout requested');
    emit(AuthLoading());

    try {
      await _authRepository.logout();
      // ล้างค่าทั้งหมดรวมถึง empCode
      await Global.clearAll(_localStorage);
      _logger.i('Logout successful and Global values cleared');
      emit(AuthUnauthenticated());
    } catch (e) {
      _logger.e('Logout error: $e');
      emit(const AuthFailure('ไม่สามารถออกจากระบบได้ โปรดลองอีกครั้ง'));
    }
  }
}
