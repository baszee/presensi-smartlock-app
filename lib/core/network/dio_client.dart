import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/app_logger.dart';

class DioClient {
  late final Dio dio;
  final FlutterSecureStorage secureStorage;

  // 🔴 PASTIKAN URL INI MILIK POSTMAN MOCK SERVER-MU!
  static const String baseUrl = 'https://68b8e6dd-1738-4a8a-a25e-9dbec037fe1e.mock.pstmn.io/api/v1';

  DioClient(this.secureStorage) {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
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