import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;

  AuthBloc({required this.repository}) : super(AuthInitial()) {
    on<RequestOtpEvent>(_onRequestOtp);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<SubmitDocumentsEvent>(_onSubmitDocuments);
  }

  Future<void> _onRequestOtp(RequestOtpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await repository.requestOtp(event.phone);
      emit(AuthOtpSent(event.phone));
    } catch (e) {
      emit(AuthError('Failed to send OTP: ${_extractErrorMessage(e)}'));
    }
  }

  String _extractErrorMessage(dynamic e) {
    if (e is DioException && e.response?.data is Map) {
      return e.response?.data['error']?.toString() ?? e.message ?? 'Unknown error';
    }
    return e.toString().replaceFirst('Exception: ', '');
  }

  Future<void> _onVerifyOtp(VerifyOtpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final result = await repository.verifyOtp(event.phone, event.code);
      final status = result['status'] as String? ?? 'pending';
      final fullName = result['fullName'] as String?;

      if (fullName != null && fullName.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('driver_name', fullName);
      }

      emit(AuthAuthenticated(driverStatus: status));
    } catch (e) {
      emit(AuthError(_extractErrorMessage(e)));
    }
  }

  Future<void> _onSubmitDocuments(SubmitDocumentsEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await repository.submitDocuments(
        name: event.name,
        plate: event.plate,
        idImagePath: event.idImagePath,
        licenseImagePath: event.licenseImagePath,
        selfieImagePath: event.selfieImagePath,
      );
      emit(AuthDocumentsSubmitted());
    } catch (e) {
      emit(AuthError('Failed to submit documents: ${_extractErrorMessage(e)}'));
    }
  }
}


