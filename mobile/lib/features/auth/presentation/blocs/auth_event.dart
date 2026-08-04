import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class RequestOtpEvent extends AuthEvent {
  final String phone;

  const RequestOtpEvent(this.phone);

  @override
  List<Object> get props => [phone];
}

class VerifyOtpEvent extends AuthEvent {
  final String phone;
  final String code;

  const VerifyOtpEvent(this.phone, this.code);

  @override
  List<Object> get props => [phone, code];
}

class SubmitDocumentsEvent extends AuthEvent {
  final String name;
  final String plate;
  final String idImagePath;
  final String licenseImagePath;
  final String selfieImagePath;

  const SubmitDocumentsEvent({
    required this.name,
    required this.plate,
    required this.idImagePath,
    required this.licenseImagePath,
    required this.selfieImagePath,
  });

  @override
  List<Object> get props => [name, plate, idImagePath, licenseImagePath, selfieImagePath];
}

