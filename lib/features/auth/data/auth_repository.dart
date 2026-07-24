import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/utils/app_logger.dart';
import 'auth_model.dart'; // <-- Import ini sekarang akan menyala/terang!

class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  AuthRepository(this._dio, this._secureStorage);

  // Dipisah jadi method sendiri (bukan langsung field) supaya gampang
  // di-scope: cuma diminta 'email' -- kita nggak butuh scope Drive/dsb.
  //
  // PENTING -- serverClientId WAJIB diisi Client ID tipe "Web application"
  // (BUKAN yang Android). Tanpa ini, di sebagian device/emulator
  // GoogleSignIn.authentication BISA berhasil nampilin dialog pilih akun
  // tapi idToken-nya balik null -- karena Android nggak tau backend mana
  // yang bakal verifikasi token itu. serverClientId inilah yang ngasih
  // tau "generate idToken yang valid buat di-verify sama Client Web ini".
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId: '623719855557-iqoot5aak41eipfoqkfd83gb1a3o9fgv.apps.googleusercontent.com',
  );

  Future<void> _saveAuthData(AuthResponse authData) async {
    await _secureStorage.write(key: 'access_token', value: authData.accessToken);
    await _secureStorage.write(key: 'user_role', value: authData.user.role);
    await _secureStorage.write(key: 'profile_completed', value: authData.profileCompleted.toString());
    await _secureStorage.write(key: 'face_enrolled', value: authData.faceEnrolled.toString());
    await _secureStorage.write(key: 'assigned_to_rombel', value: authData.assignedToRombel.toString());
  }

  /// Login via Google Sign-In.
  ///
  /// PENTING soal mock: popup pilih akun Google di sini SELALU beneran
  /// (nggak ada versi mock buat langkah ini -- Google nggak nyediain cara
  /// buat "pura-pura" pilih akun tanpa akun asli). Yang di-mock cuma
  /// LANGKAH SETELAHNYA: verifikasi idToken ke backend. Kalau
  /// AppConfig.useMockBackend true, request POST /auth/google ini
  /// dicegat FakeBackendInterceptor dan langsung dibalas sukses, TANPA
  /// pernah beneran ngirim idToken ke Laravel/Google tokeninfo endpoint.
  /// Jadi kamu tetap lihat dialog akun Google asli, tapi hasil "login
  /// berhasil"-nya dari mock.
  Future<void> loginWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        // User nutup dialog pilih akun / cancel -- ini bukan error,
        // biar AuthNotifier balik ke initial tanpa nampilin snackbar merah.
        throw 'Login Google dibatalkan.';
      }

      final googleAuth = await account.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        throw 'Gagal mendapatkan token dari Google. Coba lagi.';
      }

      final response = await _dio.post(
        '/auth/google',
        data: {
          'id_token': idToken,
          // Dua field ini TIDAK dipakai backend asli (dia cuma butuh
          // id_token, sisanya diverifikasi langsung ke Google) -- ini
          // cuma buat FakeBackendInterceptor pas mock aktif, biar respons
          // mock-nya bisa nunjukin email/nama akun Google yang beneran
          // kamu pilih, bukan data dummy generik.
          'google_email': account.email,
          'google_name': account.displayName,
        },
      );

      appLogger.w('📦 ISI RESPONSE GOOGLE LOGIN: ${response.data}');

      final responseData = response.data['data'] ?? response.data;
      final authData = AuthResponse.fromJson(responseData);

      if (authData.accessToken.isEmpty) {
        throw 'Gagal! Server tidak mengirim access_token.';
      }

      await _saveAuthData(authData);
      appLogger.i('Login Google Berhasil! Role: ${authData.user.role}');
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'Koneksi ke server gagal.';
      throw errorMessage;
    } catch (e) {
      throw 'Terjadi kesalahan sistem: $e';
    }
  }

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
            if (AppConfig.useMockBackend && email.contains('dosen')) 'x-mock-response-name': 'Login Dosen',
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

      // 4. SIMPAN DATA KE SECURE STORAGE (token + flag onboarding, dipakai
      // bareng juga sama loginWithGoogle() di bawah lewat _saveAuthData).
      await _saveAuthData(authData);

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