import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../devices/data/device_registration_service.dart';

class FaceEnrollScreen extends ConsumerStatefulWidget {
  const FaceEnrollScreen({super.key});

  @override
  ConsumerState<FaceEnrollScreen> createState() => _FaceEnrollScreenState();
}

class _FaceEnrollScreenState extends ConsumerState<FaceEnrollScreen> {
  bool _consentGiven = false;
  bool _isLoading = false;

  // TODO: ganti simulasi ini dengan kamera real-time (MediaPipe) sesuai
  // Flow_Navigasi.md 1.1 -- struktur layar & router TIDAK perlu berubah,
  // cukup ganti isi fungsi ini supaya kirim file gambar asli ke endpoint.
  Future<void> _simulateCaptureAndEnroll() async {
    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioClientProvider);
      await dio.post('/mobile/mahasiswa/face/enroll', data: {
        'consent': true,
        'consent_version': '1.0',
      });

      const storage = FlutterSecureStorage();
      await storage.write(key: 'face_enrolled', value: 'true');

      // Daftarkan HP ini di background -- silent, tidak ada layar khusus,
      // dan kalau gagal TIDAK menghalangi user lanjut ke Home.
      await DeviceRegistrationService.ensureRegistered(dio, nfcSupported: false);

      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mendaftarkan wajah: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
            Container(
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
                    'Kamera real-time akan tampil di sini\n(sementara simulasi)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
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
            const Spacer(),
            ElevatedButton(
              onPressed: (!_consentGiven || _isLoading) ? null : _simulateCaptureAndEnroll,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Ambil Foto & Daftarkan (Simulasi)'),
            ),
          ],
        ),
      ),
    );
  }
}