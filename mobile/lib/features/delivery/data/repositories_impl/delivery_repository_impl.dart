import 'dart:io';
import '../../domain/repositories/delivery_repository.dart';
import '../data_sources/delivery_remote_data_source.dart';

class DeliveryRepositoryImpl implements DeliveryRepository {
  final DeliveryRemoteDataSource remoteDataSource;

  DeliveryRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Map<String, dynamic>> getMe() async {
    return await remoteDataSource.getMe();
  }

  @override
  Future<void> submitDocuments({
    required File idPhoto,
    required File licensePhoto,
    required File selfie,
    required String plateNumber,
    String? fullName,
  }) async {
    await remoteDataSource.submitDocuments(
      idPhoto: idPhoto,
      licensePhoto: licensePhoto,
      selfie: selfie,
      plateNumber: plateNumber,
      fullName: fullName,
    );
  }

  @override
  Future<Map<String, dynamic>> createDelivery(int projectId, String unitNumber) async {
    return await remoteDataSource.createDelivery(projectId, unitNumber);
  }

  @override
  Future<void> postPing(int deliveryId, double lat, double lng, {double? accuracy, double? speed}) async {
    await remoteDataSource.postPing(deliveryId, lat, lng, accuracy: accuracy, speed: speed);
  }

  @override
  Future<Map<String, dynamic>> lookupQr(String qrToken) async {
    return await remoteDataSource.lookupQr(qrToken);
  }

  @override
  Future<void> confirmEntry(int deliveryId) async {
    await remoteDataSource.confirmEntry(deliveryId);
  }

  @override
  Future<void> rejectEntry(int deliveryId, String reason) async {
    await remoteDataSource.rejectEntry(deliveryId, reason);
  }

  @override
  Future<void> confirmExit(int deliveryId) async {
    await remoteDataSource.confirmExit(deliveryId);
  }

  @override
  Future<List<dynamic>> fetchDeliveryHistory() async {
    return await remoteDataSource.fetchDeliveryHistory();
  }
}
