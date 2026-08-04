import 'dart:async';
import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';

class AuthRemoteDataSource {
  final ApiClient client;
  AuthRemoteDataSource(this.client);

  /// Strips all whitespace from the phone number before sending so that
  /// "+20 1118196999" and "+201118196999" hit the same backend record.
  String _normalizePhone(String phone) => phone.replaceAll(RegExp(r'\s+'), '');

  Future<void> requestOtp(String phone) async {
    await client.dio.post('/auth/driver/otp/request', data: {
      'phone': _normalizePhone(phone),
    });
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String code) async {
    final res = await client.dio.post('/auth/driver/otp/verify', data: {
      'phone': _normalizePhone(phone),
      'code': code,
    });

    await client.saveToken(res.data['token'] as String);

    return {
      'driverId': res.data['driverId'],
      'status': res.data['status'] as String? ?? 'pending',
    };
  }

  Future<void> submitDocuments({
    required String name,
    required String plate,
    required String idImagePath,
    required String licenseImagePath,
    required String selfieImagePath,
  }) async {
    final formData = FormData.fromMap({
      'full_name': name,
      'plate_number': plate,
      'id_doc': await MultipartFile.fromFile(idImagePath, filename: 'id_doc.jpg'),
      'license_doc': await MultipartFile.fromFile(licenseImagePath, filename: 'license_doc.jpg'),
      'selfie': await MultipartFile.fromFile(selfieImagePath, filename: 'selfie.jpg'),
    });

    await client.dio.post('/drivers/me/documents', data: formData);
  }
}

