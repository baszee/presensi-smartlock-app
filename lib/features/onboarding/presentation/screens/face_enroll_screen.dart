import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/widgets/face_camera_capture.dart';
import '../../../devices/data/device_registration_service.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../../jadwal/providers/jadwal_provider.dart';
import '../../../sesi_kelas/providers/sesi_provider.dart';
import '../../../riwayat_presensi/providers/riwayat_provider.dart';

enum _EnrollStep { consent, capture, submitting }

class FaceEnrollScreen extends ConsumerStatefulWidget {
  const FaceEnrollScreen({super.key});

  @override
  ConsumerState<FaceEnrollScreen> createState() => _FaceEnrollScreenState();
}

class _FaceEnrollScreenState extends ConsumerState<FaceEnrollScreen> {
  bool _consentGiven = false;
  _EnrollStep _step = _EnrollStep.consent;
  String? _errorMessage;

  /// BENERAN kirim foto sekarang -- sebelumnya cuma simulasi (consent doang,
  /// tanpa 'image'), makanya backend asli selalu balas 422 "The image field
  /// is required."
  Future<void> _onFaceCaptured(String imagePath) async {
    setState(() {
      _step = _EnrollStep.submitting;
      _errorMessage = null;
    });

    try {
      final dio = ref.read(dioClientProvider);

      final formData = FormData.fromMap({
        'consent': true,
        'consent_version': '1.0',
        'image': await MultipartFile.fromFile(imagePath, filename: 'face_enroll.jpg'),
      });

      await dio.post('/mobile/mahasiswa/face/enroll', data: formData);

      const storage = FlutterSecureStorage();
      await storage.write(key: 'face_enrolled', value: 'true');

      // Daftarkan HP ini di background -- silent, tidak ada layar khusus,
      // dan kalau gagal TIDAK menghalangi user lanjut ke Home.
      await DeviceRegistrationService.ensureRegistered(dio, role: 'mahasiswa', nfcSupported: false);

      if (mounted) context.go('/home');
    } catch (e) {
      appLogger.e('❌ ERROR FACE ENROLL: $e');
      if (mounted) {
        setState(() {
          _step = _EnrollStep.capture;
          _errorMessage = 'Gagal mendaftarkan wajah: $e';
        });
      }
    }
  }

  /// Sama seperti complete_profile_screen.dart (step 1) & waiting_rombel_
  /// screen.dart (step 3): "back" = kembali ke login (logout), bukan
  /// balik ke step profil -- profil yang sudah disimpan di backend
  /// TIDAK hilang, jadi aman.
  Future<void> _confirmBackToLogin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Kembali ke Login?'),
        content: const Text(
          'Data profil kamu yang sudah disimpan tetap aman. '
              'Kamu bisa login lagi kapan saja untuk lanjut mendaftarkan wajah.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ya, Kembali')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    const storage = FlutterSecureStorage();
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'user_role');
    await storage.delete(key: 'profile_completed');
    await storage.delete(key: 'face_enrolled');
    await storage.delete(key: 'assigned_to_rombel');
    ref.invalidate(profileProvider);
    ref.invalidate(semuaJadwalProvider);
    ref.invalidate(jadwalHariIniProvider);
    ref.invalidate(sesiHariIniProvider);
    ref.invalidate(sesiHariIniDenganPresensiProvider);
    ref.invalidate(riwayatPresensiProvider);
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Daftarkan Wajah'),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Kembali ke Login',
          onPressed: _step == _EnrollStep.submitting ? null : _confirmBackToLogin,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Langkah 2 dari 3', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 4),
            const Text(
              'Wajah kamu dipakai untuk verifikasi presensi.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Expanded(child: Center(child: _buildStepContent())),
            if (_step == _EnrollStep.consent) ...[
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _consentGiven,
                onChanged: (v) => setState(() => _consentGiven = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'Saya menyetujui data wajah saya digunakan untuk verifikasi presensi.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: !_consentGiven ? null : () => setState(() => _step = _EnrollStep.capture),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Lanjut ke Kamera'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case _EnrollStep.consent:
        return Container(
          height: 260,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.face_retouching_natural, size: 64, color: Colors.grey.shade500),
              const SizedBox(height: 8),
              Text(
                'Centang persetujuan di bawah,\nlalu kamera akan terbuka',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        );
      case _EnrollStep.capture:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_errorMessage != null) ...[
              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 13)),
              const SizedBox(height: 12),
            ],
            FaceCameraCapture(onCaptured: _onFaceCaptured, captureLabel: 'Ambil Foto & Daftarkan'),
          ],
        );
      case _EnrollStep.submitting:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Mendaftarkan wajah...', style: TextStyle(fontSize: 15, color: Colors.grey)),
          ],
        );
    }
  }
}