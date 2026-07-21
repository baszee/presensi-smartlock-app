import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../utils/app_logger.dart';
import 'fake_backend_interceptor.dart';

class DioClient {
  late final Dio dio;
  final FlutterSecureStorage secureStorage;

  // Ganti lewat AppConfig.useMockBackend (lib/core/config/app_config.dart),
  // JANGAN ubah manual di sini -- biar 1 saklar ngontrol baseUrl + interceptor
  // sekaligus, nggak ada kemungkinan lupa salah satunya.
  static const String _mockBaseUrl = 'https://68b8e6dd-1738-4a8a-a25e-9dbec037fe1e.mock.pstmn.io/api/v1';
  static const String _realBaseUrl = 'https://subprime-decay-figure.ngrok-free.dev/api/v1';

  static const String baseUrl = AppConfig.useMockBackend ? _mockBaseUrl : _realBaseUrl;

  DioClient(this.secureStorage) {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          // ngrok gratis nampilin halaman peringatan browser sebelum ke
          // request asli kalau header ini nggak ada -- request dari app
          // (bukan browser) akan gagal parse HTML itu sebagai JSON.
          if (!AppConfig.useMockBackend) 'ngrok-skip-browser-warning': 'true',
        },
      ),
    );

    dio.interceptors.addAll([

      if (AppConfig.useMockBackend) FakeBackendInterceptor(),
      // 1. AUTH INTERCEPTOR: Otomatis menyuntikkan Bearer Token
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (!options.path.contains('/auth/login')) {
            final token = await secureStorage.read(key: 'access_token');
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
      ),

      // 🛑 BLOK MOCK INTERCEPTOR (isMockMode) SUDAH DIHAPUS DARI SINI 🛑

      // 2. LOGGING INTERCEPTOR: Untuk mempermudah debug di console
      InterceptorsWrapper(
        onRequest: (options, handler) {
          appLogger.i('➡️ REQUEST[${options.method}] => ${options.uri}');
          if (options.data != null) appLogger.d('Body: ${options.data}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          appLogger.i('✅ RESPONSE[${response.statusCode}] => ${response.requestOptions.uri}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          appLogger.e('❌ ERROR[${e.response?.statusCode}] => ${e.requestOptions.uri}', error: e);
          if (e.response?.data != null) appLogger.e('Error Data: ${e.response?.data}');
          return handler.next(e);
        },
      ),
    ]);
  }
}