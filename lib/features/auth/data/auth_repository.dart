import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/utils/app_logger.dart';

class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  AuthRepository(this._dio, this._secureStorage);

  Future<void> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      // 1. KITA PRINT DULU ISI ASLINYA BIAR KETAHUAN
      appLogger.w('📦 ISI RESPONSE POSTMAN: ${response.data}');

      // 2. LOGIKA PARSING YANG LEBIH AMAN (SAFE CHECK)
      // Jika response.data['data'] kosong, kita coba langsung baca response.data
      final responseData = response.data['data'] ?? response.data;

      final String? token = responseData['access_token'];

      // Jika token tetap null, berarti Postman memang tidak membalas JSON yang benar
      if (token == null) {
        throw 'Gagal! Postman tidak mengirim access_token. Cek Example di Postman.';
      }

      final String role = responseData['user']?['role'] ?? 'mahasiswa';

      await _secureStorage.write(key: 'access_token', value: token);
      await _secureStorage.write(key: 'user_role', value: role);

      appLogger.i('Login Berhasil! Role: $role');
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'Koneksi ke server gagal.';
      throw errorMessage;
    } catch (e) {
      throw 'Terjadi kesalahan sistem: $e';
    }
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'user_role');
  }
}

// Provider agar repository ini bisa dipanggil di mana saja
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthRepository(dio, secureStorage);
});