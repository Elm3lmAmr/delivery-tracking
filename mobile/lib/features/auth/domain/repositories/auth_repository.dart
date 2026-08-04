abstract class AuthRepository {
  Future<void> requestOtp(String phone);
  Future<Map<String, dynamic>> verifyOtp(String phone, String code);
  Future<void> submitDocuments({
    required String name,
    required String plate,
    required String idImagePath,
    required String licenseImagePath,
    required String selfieImagePath,
  });
}

