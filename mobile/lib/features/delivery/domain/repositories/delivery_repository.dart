import 'dart:io';

abstract class DeliveryRepository {
  Future<Map<String, dynamic>> getMe();
  
  Future<void> submitDocuments({
    required File idPhoto,
    required File licensePhoto,
    required File selfie,
    required String plateNumber,
    String? fullName,
  });

  Future<Map<String, dynamic>> createDelivery(int projectId, String unitNumber);

  Future<void> postPing(int deliveryId, double lat, double lng, {double? accuracy, double? speed});

  // Guard endpoints
  Future<Map<String, dynamic>> lookupQr(String qrToken);
  Future<void> confirmEntry(int deliveryId);
  Future<void> rejectEntry(int deliveryId, String reason);
  Future<void> confirmExit(int deliveryId);
  Future<List<dynamic>> fetchDeliveryHistory();
}
