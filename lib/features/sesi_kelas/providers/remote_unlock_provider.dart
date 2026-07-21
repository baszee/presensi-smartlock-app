import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/dio_provider.dart';
import '../../devices/data/device_registration_service.dart';

enum UnlockStatus { initial, loading, success, error }

class RemoteUnlockState {
  final UnlockStatus status;
  final String? message;

  RemoteUnlockState({required this.status, this.message});
}

class RemoteUnlockNotifier extends StateNotifier<RemoteUnlockState> {
  final Dio _dio;
  static const _storage = FlutterSecureStorage();

  RemoteUnlockNotifier(this._dio) : super(RemoteUnlockState(status: UnlockStatus.initial));

  /// Payload ini WAJIB sesuai API_CONTRACT2.md Bagian 7 / Postman "Remote
  /// Unlock": ruangan_id, mobile_device_id, alasan, current_password.
  /// (Sebelumnya provider ini salah kirim "sesi_id" -- dibenarkan di sini.)
  Future<void> unlockDoor(String ruanganId, String password, {String alasan = 'Membuka kelas'}) async {
    state = RemoteUnlockState(status: UnlockStatus.loading);

    // Pastikan kamu sudah import device_registration_service.dart di atas file ini
    final mobileDeviceId = await DeviceRegistrationService.readStoredId('dosen');
    if (mobileDeviceId == null || mobileDeviceId.isEmpty) {
      // HP dosen belum terdaftar (POST /mobile/devices) -- tanpa ini,
      // backend akan menolak remote-unlock karena syarat "HP ber-NFC
      // terdaftar" tidak terpenuhi. Ini gap terpisah, dicatat, belum
      // dibenerin di sini (dosen belum ada layar registrasi HP).
      state = RemoteUnlockState(
        status: UnlockStatus.error,
        message: 'HP kamu belum terdaftar. Daftarkan perangkat dulu sebelum remote unlock.',
      );
      return;
    }

    try {
      final response = await _dio.post(
        '/mobile/dosen/remote-unlock',
        data: {
          'ruangan_id': ruanganId,
          'mobile_device_id': mobileDeviceId,
          'alasan': alasan,
          'current_password': password,
        },
        options: Options(
          headers: {
            if (AppConfig.useMockBackend) 'x-mock-response-name': 'Remote Unlock',
          },
        ),
      );

      state = RemoteUnlockState(
        status: UnlockStatus.success,
        message: response.data['message'] ?? 'Command unlock berhasil diterbitkan',
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