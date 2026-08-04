import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';

class DeliveryRemoteDataSource {
  final ApiClient client;
  DeliveryRemoteDataSource(this.client);

  Future<Map<String, dynamic>> getMe() async {
    final res = await client.dio.get('/drivers/me');
    return res.data;
  }

  Future<Map<String, dynamic>> submitDocuments({
    required File idPhoto,
    required File licensePhoto,
    required File selfie,
    required String plateNumber,
    String? fullName,
  }) async {
    final form = FormData.fromMap({
      'plate_number': plateNumber,
      if (fullName != null) 'full_name': fullName,
      'id_doc': await MultipartFile.fromFile(idPhoto.path, filename: 'id.jpg'),
      'license_doc': await MultipartFile.fromFile(licensePhoto.path, filename: 'license.jpg'),
      'selfie': await MultipartFile.fromFile(selfie.path, filename: 'selfie.jpg'),
    });
    final res = await client.dio.post('/drivers/me/documents', data: form);
    return res.data;
  }

  Future<Map<String, dynamic>> createDelivery(int projectId, String unitNumber) async {
    final res = await client.dio.post('/deliveries', data: {
      'project_id': projectId,
      'unit_number': unitNumber,
    });
    return res.data;
  }

  Future<void> postPing(int deliveryId, double lat, double lng, {double? accuracy, double? speed}) async {
    await client.dio.post('/deliveries/$deliveryId/pings', data: {
      'lat': lat,
      'lng': lng,
      if (accuracy != null) 'accuracy_m': accuracy,
      if (speed != null) 'speed_kmh': speed,
    });
  }

  // Guard endpoints
  Future<Map<String, dynamic>> lookupQr(String qrToken) async {
    final res = await client.dio.get('/deliveries/by-token/$qrToken');
    return res.data;
  }

  Future<void> confirmEntry(int deliveryId) async {
    await client.dio.post('/deliveries/$deliveryId/confirm-entry');
  }

  Future<void> rejectEntry(int deliveryId, String reason) async {
    await client.dio.post('/deliveries/$deliveryId/reject', data: {'reason': reason});
  }
}
