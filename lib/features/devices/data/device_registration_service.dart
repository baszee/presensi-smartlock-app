import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../../../core/utils/app_logger.dart';

/// Mendaftarkan instalasi HP ini ke backend, sesuai API_CONTRACT2.md bagian 6
/// (POST /mobile/devices). Dijalankan otomatis di background -- TIDAK ada
/// layar manual, sesuai Flow_Navigasi.md 1.1.
///
/// device_public_id: UUID acak yang di-generate SEKALI per instalasi app,
/// lalu disimpan lokal supaya tetap sama selama app belum di-uninstall.
/// mobile_device_id: ID yang dikembalikan backend, dipakai di request lain
/// (presensi, remote unlock).
///
/// PENTING -- key disimpan PER ROLE ("mobile_device_id_mahasiswa" /
/// "mobile_device_id_dosen"), BUKAN satu key global. Kalau dipakai buat
/// testing dua role di HP/emulator yang sama (kayak 2 tombol dummy login
/// di login_screen.dart), device ID milik mahasiswa bisa "kebaca" seolah
/// punya dosen kalau key-nya digabung -- akibatnya ensureRegistered()
/// nganggep sudah terdaftar padahal belum, dan POST /mobile/devices nggak
/// pernah beneran ditembak buat role yang satunya.
class DeviceRegistrationService {
  static const _storage = FlutterSecureStorage();
  static const _uuid = Uuid();

  /// Panggil ini setelah onboarding selesai (atau kapan saja perlu memastikan
  /// device sudah terdaftar). Aman dipanggil berkali-kali -- kalau sudah
  /// pernah terdaftar, langsung return ID yang tersimpan tanpa nembak API lagi.
  static Future<String?> ensureRegistered(
      Dio dio, {
        required String role,
        bool nfcSupported = false,
      }) async {
    final deviceIdKey = 'mobile_device_id_$role';

    final existingDeviceId = await _storage.read(key: deviceIdKey);
    if (existingDeviceId != null && existingDeviceId.isNotEmpty) {
      return existingDeviceId;
    }

    try {
      var devicePublicId = await _storage.read(key: 'device_public_id');
      if (devicePublicId == null || devicePublicId.isEmpty) {
        devicePublicId = _uuid.v4();
        await _storage.write(key: 'device_public_id', value: devicePublicId);
      }

      final platform = Platform.isIOS ? 'ios' : 'android';

      final response = await dio.post('/mobile/devices', data: {
        'device_public_id': devicePublicId,
        'device_name': '$platform Device',
        'platform': platform,
        'nfc_supported': nfcSupported,
      });

      final data = response.data;
      final mobileDeviceId = data['id']?.toString() ??
          data['mobile_device_id']?.toString() ??
          data['data']?['id']?.toString();

      if (mobileDeviceId == null) {
        appLogger.e('⚠️ Registrasi device sukses tapi tidak ada ID di respons.');
        return null;
      }

      await _storage.write(key: deviceIdKey, value: mobileDeviceId);
      return mobileDeviceId;
    } catch (e) {
      // Sengaja tidak melempar error ke pemanggil -- registrasi device
      // gagal TIDAK BOLEH memblokir onboarding (sesuai keputusan kita
      // sebelumnya soal assigned_to_rombel: kekurangan data pendukung
      // tidak menghentikan alur utama).
      appLogger.e('❌ ERROR REGISTRASI DEVICE ($role): $e');
      return null;
    }
  }

  /// Dipakai layar/provider lain yang cuma butuh BACA id yang sudah
  /// tersimpan (presensi mahasiswa, remote unlock dosen) -- tanpa perlu
  /// import ensureRegistered lagi.
  static Future<String?> readStoredId(String role) {
    return _storage.read(key: 'mobile_device_id_$role');
  }
}