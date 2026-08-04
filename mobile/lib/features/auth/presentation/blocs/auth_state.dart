import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthOtpSent extends AuthState {
  final String phone;

  const AuthOtpSent(this.phone);

  @override
  List<Object?> get props => [phone];
}

class AuthAuthenticated extends AuthState {
  final String driverStatus;

  const AuthAuthenticated({required this.driverStatus});

  @override
  List<Object?> get props => [driverStatus];
}

class AuthDocumentsSubmitted extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
