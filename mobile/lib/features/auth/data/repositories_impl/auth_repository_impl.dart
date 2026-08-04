import '../../domain/repositories/auth_repository.dart';
import '../data_sources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> requestOtp(String phone) async {
    await remoteDataSource.requestOtp(phone);
  }

  @override
  Future<Map<String, dynamic>> verifyOtp(String phone, String code) async {
    return remoteDataSource.verifyOtp(phone, code);
  }

  @override
  Future<void> submitDocuments({
    required String name,
    required String plate,
    required String idImagePath,
    required String licenseImagePath,
    required String selfieImagePath,
  }) async {
    await remoteDataSource.submitDocuments(
      name: name,
      plate: plate,
      idImagePath: idImagePath,
      licenseImagePath: licenseImagePath,
      selfieImagePath: selfieImagePath,
    );
  }
}

