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
class DeviceRegistrationService {
  static const _storage = FlutterSecureStorage();
  static const _uuid = Uuid();

  /// Panggil ini setelah onboarding selesai (atau kapan saja perlu memastikan
  /// device sudah terdaftar). Aman dipanggil berkali-kali -- kalau sudah
  /// pernah terdaftar, langsung return ID yang tersimpan tanpa nembak API lagi.
  static Future<String?> ensureRegistered(Dio dio, {bool nfcSupported = false}) async {
    final existingDeviceId = await _storage.read(key: 'mobile_device_id');
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

      await _storage.write(key: 'mobile_device_id', value: mobileDeviceId);
      return mobileDeviceId;
    } catch (e) {
      // Sengaja tidak melempar error ke pemanggil -- registrasi device
      // gagal TIDAK BOLEH memblokir onboarding (sesuai keputusan kita
      // sebelumnya soal assigned_to_rombel: kekurangan data pendukung
      // tidak menghentikan alur utama).
      appLogger.e('❌ ERROR REGISTRASI DEVICE: $e');
      return null;
    }
  }
}