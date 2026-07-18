import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/utils/app_logger.dart';
import 'auth_model.dart'; // <-- Import ini sekarang akan menyala/terang!

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
        // TAMBAHKAN OPTIONS INI UNTUK TRIK POSTMAN
        options: Options(
          headers: {
            // Kalau emailnya dosen, kirim header supaya Postman pakai Example "Login Dosen"
            if (email.contains('dosen')) 'x-mock-response-name': 'Login Dosen',
          },
        ),
      );

      // 1. KITA PRINT DULU ISI ASLINYA BIAR KETAHUAN
      appLogger.w('📦 ISI RESPONSE POSTMAN: ${response.data}');

      // 2. LOGIKA PARSING (SAFE CHECK)
      final responseData = response.data['data'] ?? response.data;

      // 3. MASUKKAN JSON KE DALAM CETAKAN MODEL
      // Di sinilah fungsi auth_model.dart bekerja!
      final authData = AuthResponse.fromJson(responseData);

      // Jika token kosong (karena fallback di model adalah string kosong ''), lempar error
      if (authData.accessToken.isEmpty) {
        throw 'Gagal! Postman tidak mengirim access_token. Cek Example di Postman.';
      }

      // 4. SIMPAN DATA KE SECURE STORAGE
      // Perhatikan: Kita sekarang memanggil properti object (authData.accessToken),
      // bukan lagi map manual (responseData['access_token']). Jauh lebih aman dari typo!
      await _secureStorage.write(key: 'access_token', value: authData.accessToken);
      await _secureStorage.write(key: 'user_role', value: authData.user.role);

      appLogger.i('Login Berhasil! Role: ${authData.user.role}');
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