import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_provider.dart';

enum UnlockStatus { initial, loading, success, error }

class RemoteUnlockState {
  final UnlockStatus status;
  final String? message;

  RemoteUnlockState({required this.status, this.message});
}

class RemoteUnlockNotifier extends StateNotifier<RemoteUnlockState> {
  final Dio _dio;

  RemoteUnlockNotifier(this._dio) : super(RemoteUnlockState(status: UnlockStatus.initial));

  Future<void> unlockDoor(String sesiId, String password) async {
    state = RemoteUnlockState(status: UnlockStatus.loading);
    try {
      final response = await _dio.post(
        '/mobile/dosen/remote-unlock', // <-- UBAH BAGIAN INI SESUAI POSTMAN
        data: {
          'sesi_id': sesiId, // Kita lempar ID Sesi ke dalam body saja
          'current_password': password,
        },
        options: Options(
          headers: {
            'x-mock-response-name': 'Remote Unlock',
          },
        ),
      );

      state = RemoteUnlockState(
        status: UnlockStatus.success,
        message: response.data['message'],
      );
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'Gagal terhubung ke alat.';
      state = RemoteUnlockState(status: UnlockStatus.error, message: errorMessage);
    } catch (e) {
      state = RemoteUnlockState(status: UnlockStatus.error, message: e.toString());
    }
  }
}

// Daftarkan ke Riverpod
final remoteUnlockProvider = StateNotifierProvider<RemoteUnlockNotifier, RemoteUnlockState>((ref) {
  final dio = ref.watch(dioClientProvider);
  return RemoteUnlockNotifier(dio);
});