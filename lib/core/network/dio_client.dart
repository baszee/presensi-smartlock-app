import 'package:dio/dio.dart';
import '../utils/app_logger.dart';

/// Class ini bertugas bikin dan mengatur satu instance Dio
/// yang dipakai di seluruh aplikasi untuk request ke backend.
class DioClient {
  late final Dio dio;

  // Sementara base URL di-hardcode dulu (sesuai keputusan ADR: flavor
  // system belum diimplementasi). Nanti tinggal ganti sesuai info dari backend.
  static const String baseUrl = 'http://10.10.118.215:8000/api/v1';

  DioClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    // Tambahin interceptor sederhana buat logging request/response.
    // Ini akan ngeprint tiap request yang dikirim dan response yang diterima
    // ke console, biar gampang debug.
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          appLogger.i('➡️ REQUEST[${options.method}] => ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          appLogger.i(
            'RESPONSE[${response.statusCode}] => ${response.requestOptions.uri}',
          );
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          appLogger.e(
            'ERROR[${e.response?.statusCode}] => ${e.requestOptions.uri}',
            error: e,
          );
          return handler.next(e);
        },
      ),
    );
  }
}